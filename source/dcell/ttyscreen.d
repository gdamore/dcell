/**
 * TtyScreen module implements POSIX style terminals (ala XTerm).
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.ttyscreen;

package:

import core.atomic;
import core.time;
import std.algorithm : canFind;
import std.format;
import std.concurrency;
import std.exception;
import std.outbuffer;
import std.range;
import std.stdio;
import std.string;

import dcell.cell;
import dcell.cursor;
import dcell.evqueue;
import dcell.key;
import dcell.mouse;
import dcell.termcap;
import dcell.database;
import dcell.termio;
import dcell.screen;
import dcell.event;
import dcell.parser;
import dcell.turnstile;

class TtyScreen : Screen
{
    // Various escape escape sequences we can send.
    // Note that we have a rather broad assumption that we only support terminals
    // that understand these things, or in some cases, that will gracefully ignore
    // them.  (For example, terminals should ignore SGR settings they don't grok.)
    struct Vt
    {
        enum string enableAutoMargin = "\x1b[?7h"; // dec private mode 7 (enable)
        enum string disableAutoMargin = "\x1b[?7l";
        enum string setCursorPosition = "\x1b[%d;%dH";
        enum string sgr0 = "\x1b[m"; // attrOff
        enum string bold = "\x1b[1m";
        enum string dim = "\x1b[2m";
        enum string italic = "\x1b[3m";
        enum string underline = "\x1b[4m";
        enum string blink = "\x1b[5m";
        enum string reverse = "\x1b[7m";
        enum string strikeThrough = "\x1b[9m";
        enum string showCursor = "\x1b[?25h";
        enum string hideCursor = "\x1b[?25l";
        enum string clear = "\x1b[H\x1b[J";
        enum string enablePaste = "\x1b[?2004h";
        enum string disablePaste = "\x1b[?2004l";
        enum string enableFocus = "\x1b[?1004h";
        enum string disableFocus = "\x1b[?1004l";
        enum string cursorReset = "\x1b[0 q"; // reset cursor shape to default
        enum string cursorBlinkingBlock = "\x1b[1 q";
        enum string cursorBlock = "\x1b[2 q";
        enum string cursorBlinkingUnderline = "\x1b[3 q";
        enum string cursorUnderline = "\x1b[4 q";
        enum string cursorBlinkingBar = "\x1b[5 q";
        enum string cursorBar = "\x1b[6 q";
        enum string enterCA = "\x1b[?1049h"; // alternate screen
        enum string exitCA = "\x1b[?1049l"; // alternate screen
        enum string startSyncOut = "\x1b[?2026h";
        enum string endSyncOut = "\x1b[?2026l";

        // these can be overridden (e.g. disabled for legacy)
        string enterURL = "\x1b]8;;%s\x1b\\";
        string exitURL = "\x1b]8;;\x1b\\";
        string setWindowSize = "\x1b[8;%d;%dt";
        string saveTitle = "\x1b[22;2t";
        string restoreTitle = "\x1b[23;2t";
        string setTitle = "\x1b[>2t\x1b]2;%s\x1b\\";

        // doubleUnder       = "\x1b[4:2m"
        // curlyUnder        = "\x1b[4:3m"
        // dottedUnder       = "\x1b[4:4m"
        // dashedUnder       = "\x1b[4:5m"
        // underColor        = "\x1b[58:5:%dm"
        // underRGB          = "\x1b[58:2::%d:%d:%dm"
        // underFg           = "\x1b[59m"
        // enableAltChars    = "\x1b(B\x1b)0"                      // set G0 as US-ASCII, G1 as DEC line drawing
        // startAltChars     = "\x0e"                              // aka Shift-Out
        // endAltChars       = "\x0f"                              // aka Shift-In
        // setFg8            = "\x1b[3%dm"                         // for colors less than 8
        // setFg256          = "\x1b[38;5;%dm"                     // for colors less than 256
        // setFgRgb          = "\x1b[38;2;%d;%d;%dm"               // for RGB
        // setBg8            = "\x1b[4%dm"                         // color colors less than 8
        // setBg256          = "\x1b[48;5;%dm"                     // for colors less than 256
        // setBgRgb          = "\x1b[48;2;%d;%d;%dm"               // for RGB
        // setFgBgRgb        = "\x1b[38;2;%d;%d;%d;48;2;%d;%d;%dm" // for RGB, in one shot
        // resetFgBg         = "\x1b[39;49m"                       // ECMA defined
        // enterKeypad       = "\x1b[?1h\x1b="                     // Note mode 1 might not be supported everywhere
        // exitKeypad        = "\x1b[?1l\x1b>"                     // Also mode 1
        // requestWindowSize = "\x1b[18t"                          // For modern terminals
    }

    this(TtyImpl tt, const(Termcap)* tc, string term = "")
    {
        caps = tc;
        ti = tt;
        ti.start();
        cells = new CellBuffer(ti.windowSize());
        ob = new OutBuffer();
        stopping = new Turnstile();
        defStyle.bg = Color.reset;
        defStyle.fg = Color.reset;

        legacy = false;
        if (term.startsWith("vt") || term.canFind("ansi") || term == "linux" || term == "sun" || term == "sun-color")
        {
            // these terminals are "legacy" and not expected to support most OSC functions
            legacy = true;
        }

        // for legacy terminals, disable functions we don't support
        if (legacy)
        {
            vt.enterURL = "";
            vt.exitURL = "";
            vt.setWindowSize = "";
            vt.setTitle = "";
            vt.restoreTitle = "";
            vt.saveTitle = "";
        }
    }

    ~this()
    {
        ti.stop();
    }

    private void start(Tid tid, EventQueue eq)
    {
        if (started)
            return;
        stopping.set(false);
        ti.save();
        ti.raw();
        puts(vt.disableAutoMargin);
        puts(vt.clear);
        resize();
        draw();
        spawn(&inputLoop, cast(shared TtyImpl) ti, tid,
            cast(shared EventQueue) eq, cast(shared Turnstile) stopping);
        started = true;
    }

    void start(Tid tid)
    {
        start(tid, null);
    }

    void start()
    {
        eq = new EventQueue();
        start(Tid(), eq);
    }

    void stop()
    {
        if (!started)
            return;

        puts(vt.enableAutoMargin);
        puts(caps.resetColors);
        puts(vt.sgr0);
        puts(vt.cursorReset);
        puts(vt.showCursor);
        puts(vt.cursorReset);
        puts(vt.clear);
        puts(vt.disablePaste);
        enableMouse(MouseEnable.disable);
        puts(vt.disableFocus);
        flush();
        stopping.set(true);
        ti.blocking(false);
        ti.stop();
        stopping.wait(false);
        ti.blocking(true);
        ti.restore();
        started = false;
    }

    void clear()
    {
        fill(" ");
        clear_ = true;
        // because we are going to clear it in the next cycle,
        // lets mark all the cells clean, so that we don't waste
        // needless time redrawing spaces for the entire screen.
        cells.setAllDirty(false);
    }

    void fill(string s, Style style)
    {
        cells.fill(s, style);
    }

    void fill(string s)
    {
        fill(s, this.defStyle);
    }

    void showCursor(Coord pos, Cursor cur = Cursor.current)
    {
        // just save the coordinates for now
        // it will be used during the next draw cycle
        cursorPos = pos;
        cursorShape = cur;
    }

    void showCursor(Cursor cur)
    {
        cursorShape = cur;
    }

    Coord size() pure const
    {
        return (cells.size());
    }

    void resize()
    {
        auto phys = ti.windowSize();
        if (phys != cells.size())
        {
            cells.resize(phys);
            cells.setAllDirty(true);
        }
    }

    ref Cell opIndex(size_t x, size_t y)
    {
        return (cells[x, y]);
    }

    void opIndexAssign(Cell c, size_t x, size_t y)
    {
        cells[x, y] = c;
    }

    void enablePaste(bool b)
    {
        pasteEn = b;
        sendPasteEnable(b);
    }

    bool hasMouse() const pure
    {
        return true;
    }

    int colors() const pure
    {
        return caps.colors;
    }

    void show()
    {
        resize();
        draw();
    }

    void sync()
    {
        pos_ = Coord(-1, -1);
        resize();
        clear_ = true;
        cells.setAllDirty(true);
        draw();
    }

    void beep()
    {
        puts("\x07");
        flush();
    }

    void setStyle(Style style)
    {
        defStyle = style;
    }

    void setSize(Coord size)
    {
        if (vt.setWindowSize != "")
        {
            puts(vt.setWindowSize, size.y, size.x);
            flush();
            cells.setAllDirty(true);
            resize();
        }
    }

    void enableMouse(MouseEnable en)
    {
        // we rely on the fact that all known implementations adhere
        // to the de-facto standard from XTerm.  This is necessary as
        // there is no standard terminfo sequence for reporting this
        // information.
        mouseEn = en; // save this so we can restore after a suspend
        sendMouseEnable(en);
    }

    void enableFocus(bool enabled)
    {
        puts(enabled ? Vt.enableFocus : Vt.disableFocus);
        flush();
    }

    Event receiveEvent(Duration dur)
    {
        if (eq is null)
        {
            return Event(EventType.error);
        }
        return eq.receive(dur);
    }

    /** This variant of receiveEvent blocks forever until an event is available. */
    Event receiveEvent()
    {
        if (eq is null)
        {
            return Event(EventType.error);
        }
        return eq.receive();
    }

private:
    struct KeyCode
    {
        Key key;
        Modifiers mod;
    }

    const(Termcap)* caps;
    CellBuffer cells;
    bool clear_; // if a screen clear is requested
    Coord pos_; // location where we will update next
    Style style_; // current style
    Style defStyle; // default style (when screen is cleared)
    Coord cursorPos;
    Cursor cursorShape;
    MouseEnable mouseEn; // saved state for suspend/resume
    bool pasteEn; // saved state for suspend/resume
    TtyImpl ti;
    OutBuffer ob;
    Turnstile stopping;
    bool started;
    bool legacy; // legacy terminals don't have support for OSC, APC, DSC, etc.
    EventQueue eq;
    Vt vt;

    void puts(string s)
    {
        Termcap.puts(ob, s, &flush);
    }

    void puts(string s, int[] args...)
    {
        puts(Termcap.param(s, args));
    }

    void puts(string s, string[] args...)
    {
        puts(Termcap.param(s, args));
    }

    // flush queued output
    void flush()
    {
        ti.write(ob.toString());
        ti.flush();
        ob.clear();
    }

    // sendColors sends just the colors for a given style
    void sendColors(Style style)
    {
        auto fg = style.fg;
        auto bg = style.bg;

        if (caps.colors == 0)
        {
            return;
        }
        if (fg == Color.reset || bg == Color.reset)
        {
            puts(caps.resetColors);
        }
        if (caps.colors > 256)
        {
            if (caps.setFgBgRGB != "" && isRGB(fg) && isRGB(bg))
            {
                auto rgb1 = decompose(fg);
                auto rgb2 = decompose(bg);
                puts(caps.setFgBgRGB, rgb1[0], rgb1[1], rgb1[2], rgb2[0], rgb2[1], rgb2[2]);
            }
            else
            {
                if (isRGB(fg) && caps.setFgRGB != "")
                {
                    auto rgb = decompose(fg);
                    puts(caps.setFgRGB, rgb[0], rgb[1], rgb[2]);
                }
                if (isRGB(bg) && caps.setBgRGB != "")
                {
                    auto rgb = decompose(bg);
                    puts(caps.setBgRGB, rgb[0], rgb[1], rgb[2]);
                }
            }
        }
        else
        {
            fg = toPalette(fg, caps.colors);
            bg = toPalette(bg, caps.colors);
        }
        if (fg < 256 && bg < 256 && caps.setFgBg != "")
            puts(caps.setFgBg, fg, bg);
        else
        {
            if (fg < 256)
                puts(caps.setFg, fg);
            if (bg < 256)
                puts(caps.setBg, bg);
        }

    }

    void sendAttrs(Style style)
    {
        auto attr = style.attr;
        if (attr & Attr.bold)
            puts(Vt.bold);
        if (attr & Attr.underline)
            puts(Vt.underline);
        if (attr & Attr.reverse)
            puts(Vt.reverse);
        if (attr & Attr.blink)
            puts(Vt.blink);
        if (attr & Attr.dim)
            puts(Vt.dim);
        if (attr & Attr.italic)
            puts(Vt.italic);
        if (attr & Attr.strikethrough)
            puts(Vt.strikeThrough);
    }

    void clearScreen()
    {
        if (clear_)
        {
            clear_ = false;
            puts(vt.sgr0);
            puts(vt.exitURL);
            sendColors(defStyle);
            sendAttrs(defStyle);
            style_ = defStyle;
            puts(Vt.clear);
            flush();
        }
    }

    void goTo(Coord pos)
    {
        if (pos != pos_)
        {
            puts(format!(Vt.setCursorPosition)(pos.y, pos.x));
            pos_ = pos;
        }
    }

    // sendCursor sends the current cursor location
    void sendCursor()
    {
        if (!cells.isLegal(cursorPos) || (cursorShape == Cursor.hidden))
        {
            puts(vt.hideCursor);
            return;
        }
        goTo(cursorPos);
        puts(cursorShape != Cursor.hidden ? vt.showCursor : vt.hideCursor);
        final switch (cursorShape)
        {
        case Cursor.current:
            break;
        case Cursor.hidden:
            break;
        case Cursor.reset:
            puts(vt.cursorReset);
            break;
        case Cursor.bar:
            puts(vt.cursorBar);
            break;
        case Cursor.block:
            puts(vt.cursorBlock);
            break;
        case Cursor.underline:
            puts(vt.cursorUnderline);
            break;
        case Cursor.blinkingBar:
            puts(vt.cursorBlinkingBar);
            break;
        case Cursor.blinkingBlock:
            puts(vt.cursorBlinkingBlock);
            break;
        case Cursor.blinkingUnderline:
            puts(vt.cursorBlinkingUnderline);
            break;
        }

        // update our location
        pos_ = cursorPos;
    }

    // drawCell draws one cell.  It returns the width drawn (1 or 2).
    int drawCell(Coord pos)
    {
        Cell c = cells[pos];
        auto insert = false;
        if (!cells.dirty(pos))
        {
            return c.width;
        }
        auto size = cells.size();
        if (pos != pos_)
        {
            goTo(pos);
        }

        if (caps.colors == 0)
        {
            // if its monochrome, simulate lighter and darker with reverse
            if (darker(c.style.fg, c.style.bg))
            {
                c.style.attr ^= Attr.reverse;
            }
        }
        if (vt.enterURL == "")
        {
            // avoid pointless changes due to URL where not supported
            c.style.url = "";
        }

        if (c.style.fg != style_.fg || c.style.bg != style_.bg || c.style.attr != style_.attr)
        {
            puts(Vt.sgr0);
            sendColors(c.style);
            sendAttrs(c.style);
        }
        if (c.style.url != style_.url)
        {
            if (c.style.url != "")
            {
                puts(format(vt.enterURL, c.style.url));
            }
            else
            {
                puts(vt.exitURL);
            }
        }
        // TODO: replacement encoding (ACSC, application supplied fallbacks)

        style_ = c.style;

        if (pos.x + c.width > size.x)
        {
            // if too big to fit last column, just fill with a space
            c.text = " ";
        }

        puts(c.text);
        pos_.x += c.width;
        // Note that we might be beyond the width, and if auto-margin
        // is set true, we might have wrapped.  But it turns out that
        // we can't reliably depend on auto-margin, as some terminals
        // that claim to behave that way actually don't.
        cells.setDirty(pos, false);
        if (insert)
        {
            // go back and redraw the second to last cell
            drawCell(Coord(pos.x - 1, pos.y));
        }
        return c.width;
    }

    void draw()
    {
        puts(vt.hideCursor); // hide the cursor while we draw
        clearScreen(); // no op if not needed
        auto size = cells.size();
        Coord pos = Coord(0, 0);
        for (pos.y = 0; pos.y < size.y; pos.y++)
        {
            int width = 1;
            for (pos.x = 0; pos.x < size.x; pos.x += width)
            {
                width = drawCell(pos);
                // this way if we ever redraw that cell, it will
                // be marked dirty, because we have clobbered it with
                // the adjacent character
                if (width < 1)
                    width = 1;
                if (width > 1)
                {
                    cells.setDirty(Coord(pos.x + 1, pos.y), true);
                }
            }
        }
        sendCursor();
        flush();
    }

    void sendMouseEnable(MouseEnable en)
    {
        // we rely on the fact that all known implementations adhere
        // to the de-facto standard from XTerm.  This is necessary as
        // there is no standard terminfo sequence for reporting this
        // information.
        // start by disabling everything
        puts("\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l");
        // then turn on specific enables
        if (en & MouseEnable.buttons)
            puts("\x1b[?1000h");
        if (en & MouseEnable.drag)
            puts("\x1b[?1002h");
        if (en & MouseEnable.motion)
            puts("\x1b[?1003h");
        // and if any are set, we need to send this
        if (en & MouseEnable.all)
            puts("\x1b[?1006h");
        flush();
    }

    void sendPasteEnable(bool b)
    {
        puts(b ? Vt.enablePaste : Vt.disablePaste);
        flush();
    }

    static void inputLoop(shared TtyImpl tin, Tid tid,
        shared EventQueue eq, shared Turnstile stopping)
    {
        TtyImpl f = cast(TtyImpl) tin;
        Parser p = new Parser();

        f.blocking(true);

        for (;;)
        {
            string s;
            try
            {
                s = f.read();
            }
            catch (Exception e)
            {
            }
            bool finished = p.parse(s);
            auto evs = p.events();
            if (f.resized())
            {
                Event ev;
                ev.type = EventType.resize;
                ev.when = MonoTime.currTime();
                evs ~= ev;
            }
            foreach (_, ev; evs)
            {
                if (eq is null)
                    send(ownerTid(), ev);
                else
                {
                    eq.send(ev);
                }
            }

            if (stopping.get())
            {
                stopping.set(false);
                return;
            }

            if (!p.empty() || !finished)
            {
                f.blocking(false);
            }
            else
            {
                // No data, so we can sleep until some arrives.
                f.blocking(true);
            }
        }
    }
}

version (Posix)  : import dcell.terminfo;

Screen newTtyScreen(string term = "")
{
    import std.process;

    if (term == "")
    {
        term = environment.get("TERM", "ansi");
    }
    auto caps = Database.get(term);
    if (caps is null)
    {
        throw new Exception("terminal not found");
    }
    return new TtyScreen(newDevTty(), caps, term);
}
