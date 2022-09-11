// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.ttyscreen;

import core.atomic;
import core.time;
import std.string;
import std.concurrency;
import std.exception;
import std.outbuffer;
import std.range;
import std.stdio;

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
    this(TtyImpl tt, const(Termcap)* tc)
    {
        caps = tc;
        ti = tt;
        ti.start();
        cells = new CellBuffer(ti.windowSize());
        keys = ParseKeys(tc);
        ob = new OutBuffer();
        stopping = new Turnstile();
        defStyle.bg = Color.reset;
        defStyle.fg = Color.reset;
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
        puts(caps.clear);
        resize();
        draw();
        spawn(&inputLoop, cast(shared TtyImpl) ti, keys, tid, cast(shared EventQueue) eq, stopping);
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
        puts(caps.resetColors);
        puts(caps.attrOff);
        puts(caps.cursorReset);
        puts(caps.showCursor);
        puts(caps.cursorReset);
        puts(caps.clear);
        puts(caps.disablePaste);
        enableMouse(MouseEnable.disable);
        flush();
        stopping.set(true);
        ti.blocking(false);
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
        return caps.mouse != "";
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
        puts(caps.bell);
        flush();
    }

    void setStyle(Style style)
    {
        defStyle = style;
    }

    void setSize(Coord size)
    {
        if (caps.setWindowSize != "")
        {
            puts(caps.setWindowSize, size.x, size.y);
            flush();
            cells.setAllDirty(true);
            resize();
        }
    }

    bool hasKey(Key k) const pure
    {
        return (keys.hasKey(k));
    }

    void enableMouse(MouseEnable en)
    {
        // we rely on the fact that all known implementations adhere
        // to the de-facto standard from XTerm.  This is necessary as
        // there is no standard terminfo sequence for reporting this
        // information.
        if (caps.mouse != "")
        {
            mouseEn = en; // save this so we can restore after a suspend
            sendMouseEnable(en);
        }
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
    bool clear_; // if a sceren clear is requested
    Coord pos_; // location where we will update next
    Style style_; // current style
    Style defStyle; // default style (when screen is cleared)
    Coord cursorPos;
    Cursor cursorShape;
    MouseEnable mouseEn; // saved state for suspend/resume
    bool pasteEn; // saved state for suspend/resume
    ParseKeys keys;
    TtyImpl ti;
    OutBuffer ob;
    Turnstile stopping;
    bool started;
    EventQueue eq;

    // puts emits a parameterized string that may contain embedded delay padding.
    // it should not be used for user-supplied strings.
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
                puts(caps.setFgBgRGB,
                    rgb1[0], rgb1[1], rgb1[2], rgb2[0], rgb2[1], rgb2[2]);
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
            puts(caps.bold);
        if (attr & Attr.underline)
            puts(caps.underline);
        if (attr & Attr.reverse)
            puts(caps.reverse);
        if (attr & Attr.blink)
            puts(caps.blink);
        if (attr & Attr.dim)
            puts(caps.dim);
        if (attr & Attr.italic)
            puts(caps.italic);
        if (attr & Attr.strikethrough)
            puts(caps.strikethrough);
    }

    void clearScreen()
    {
        if (clear_)
        {
            clear_ = false;
            puts(caps.attrOff);
            puts(caps.exitURL);
            sendColors(defStyle);
            sendAttrs(defStyle);
            style_ = defStyle;
            puts(caps.clear);
            flush();
        }
    }

    void goTo(Coord pos)
    {
        if (pos != pos_)
        {
            puts(caps.setCursor, pos.y, pos.x);
            pos_ = pos;
        }
    }

    // sendCursor sends the current cursor location
    void sendCursor()
    {
        if (!cells.isLegal(cursorPos) || (cursorShape == Cursor.hidden))
        {
            if (caps.hideCursor != "")
            {
                puts(caps.hideCursor);
            }
            else
            {
                // go to last cell (lower right)
                // this is the best we can do to move the cursor
                // out of the way.
                auto size = cells.size();
                goTo(Coord(size.x - 1, size.y - 1));
            }
            return;
        }
        goTo(cursorPos);
        puts(caps.showCursor);
        final switch (cursorShape)
        {
        case Cursor.current:
            break;
        case Cursor.hidden:
            puts(caps.hideCursor);
            break;
        case Cursor.reset:
            puts(caps.cursorReset);
            break;
        case Cursor.bar:
            puts(caps.cursorBar);
            break;
        case Cursor.block:
            puts(caps.cursorBlock);
            break;
        case Cursor.underline:
            puts(caps.cursorUnderline);
            break;
        case Cursor.blinkingBar:
            puts(caps.cursorBlinkingBar);
            break;
        case Cursor.blinkingBlock:
            puts(caps.cursorBlinkingBlock);
            break;
        case Cursor.blinkingUnderline:
            puts(caps.cursorBlinkingUnderline);
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
        // automargin handling -- if we are going to automatically
        // wrap at the bottom right corner, then we want to insert
        // that character in place, to avoid the scroll of doom.
        auto size = cells.size();
        if ((pos.y == size.y - 1) && (pos.x == size.x - 1) && caps.automargin && (
                caps.insertChar != ""))
        {
            auto pp = pos;
            pp.x--;
            goTo(pp);
            insert = true;
        }
        else if (pos != pos_)
        {
            goTo(pos);
        }

        if (caps.colors == 0)
        {
            // if its monochrome, simulate ligher and darker with reverse
            if (darker(c.style.fg, c.style.bg))
            {
                c.style.attr ^= Attr.reverse;
            }
        }
        if (caps.enterURL == "")
        { // avoid pointless changes due to URL where not supported
            c.style.url = "";
        }

        if (c.style.fg != style_.fg || c.style.bg != style_.bg || c.style.attr != style_.attr)
        {
            puts(caps.attrOff);
            sendColors(c.style);
            sendAttrs(c.style);
        }
        if (c.style.url != style_.url)
        {
            if (c.style.url != "")
            {
                puts(caps.enterURL, c.style.url);
            }
            else
            {
                puts(caps.exitURL);
            }
        }
        // TODO: replacement encoding (ACSC, application supplied fallbacks)

        style_ = c.style;

        if (pos.x + c.width > size.x)
        {
            // if too big to fit last column, just fill with a space
            c.text = " ";
            c.width = 1;
        }

        puts(c.text);
        pos_.x += c.width;
        // Note that we might be beyond the width, and if automargin
        // is set true, we might have wrapped.  But it turns out that
        // we can't reliably depend on automargin, as some terminals
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
        puts(caps.hideCursor); // hide the cursor while we draw
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
        if (caps.mouse != "")
        {
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
    }

    void sendPasteEnable(bool b)
    {
        puts(b ? caps.enablePaste : caps.disablePaste);
        flush();
    }

    static void inputLoop(shared TtyImpl tin, ParseKeys keys, Tid tid, shared EventQueue eq, shared Turnstile stopping)
    {
        TtyImpl f = cast(TtyImpl) tin;
        Parser p = new Parser(keys);
        bool poll = false;

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
            p.parse(s);
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
                    import std.stdio;

                    eq.send(ev);
                }
            }
            if (!p.empty())
            {
                f.blocking(false);
                poll = true;
            }
            else
            {
                // No data, so we can sleep until some arrives.
                f.blocking(true);
                poll = false;
            }

            if (stopping.get())
            {
                stopping.set(false);
                return;
            }
        }
    }

    unittest
    {
        version (Posix)
        {
            import core.thread;
            import dcell.terminfo.xterm;

            auto caps = Database.get("xterm-256color");
            assert(caps.name != "");
            assert(caps.setFgBg != "");
            auto ts = new TtyScreen(newDevTty(), caps);
            assert(ts !is null);

            ts.start();
            ts.showCursor(Coord(0, 0), Cursor.hidden);
            auto c = ts.size();
            c.x /= 2;
            c.y /= 2;
            ts[c] = Cell("A", Style(Color.white, Color.red, Attr
                    .underline), 1);
            c.x++;
            ts[c] = Cell("B", Style(Color.white, Color.green, Attr
                    .underline), 1);
            ts.show();
            import core.thread;

            Thread.sleep(dur!("seconds")(2));
            ts.stop();
            destroy(ts);
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
    return new TtyScreen(newDevTty(), caps);
}
