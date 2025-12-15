/**
 * VtScreen module implements VT style terminals (ala XTerm).
 * These are terminals that work by sending escape sequences over
 * a single byte stream. Historically this would be a serial port,
 * but modern systems likely use SSH, or a pty (pseudo-terminal).
 * Modern Windows has adopted this form of API as well.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.vt;

package:

import core.atomic;
import core.time;
import std.algorithm : canFind;
import std.format;
import std.datetime;
import std.exception;
import std.outbuffer;
import std.process;
import std.range;
import std.stdio;
import std.string;

import dcell.cell;
import dcell.cursor;
import dcell.key;
import dcell.mouse;
import dcell.termio;
import dcell.screen;
import dcell.event;
import dcell.parser;
import dcell.tty;

class VtScreen : Screen
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
        enum string enableAltChars = "\x1b(B\x1b)0"; // set G0 as US-ASCII, G1 as DEC line drawing
        enum string startAltChars = "\x0e"; // aka Shift-Out
        enum string endAltChars = "\x0f"; // aka Shift-In
        enum string enterKeypad = "\x1b[?1h\x1b="; // Note mode 1 might not be supported everywhere
        enum string exitKeypad = "\x1b[?1l\x1b>"; // Also mode 1
        enum string setFg8 = "\x1b[3%dm"; // for colors less than 8
        enum string setFg256 = "\x1b[38;5;%dm"; // for colors less than 256
        enum string setFgRGB = "\x1b[38;2;%d;%d;%dm"; // for RGB
        enum string setBg8 = "\x1b[4%dm"; // color colors less than 8
        enum string setBg256 = "\x1b[48;5;%dm"; // for colors less than 256
        enum string setBgRGB = "\x1b[48;2;%d;%d;%dm"; // for RGB
        enum string setFgBgRGB = "\x1b[38;2;%d;%d;%d;48;2;%d;%d;%dm"; // for RGB, in one shot
        enum string resetFgBg = "\x1b[39;49m"; // ECMA defined
        enum string requestDA = "\x1b[c"; // request primary device attributes
        enum string disableMouse = "\x1b[?1000l\x1b[?1002l\x1b[?1003l\x1b[?1006l";
        enum string enableButtons = "\x1b[?1000h";
        enum string enableDrag = "\x1b[?1002h";
        enum string enableMotion = "\x1b[?1003h";
        enum string mouseSgr = "\x1b[?1006h"; // SGR reporting (use with other enables)
        enum string doubleUnder = "\x1b[4:2m";
        enum string curlyUnder = "\x1b[4:3m";
        enum string dottedUnder = "\x1b[4:4m";
        enum string dashedUnder = "\x1b[4:5m";
        enum string underColor = "\x1b[58:5:%dm";
        enum string underRGB = "\x1b[58:2::%d:%d:%dm";
        enum string underFg = "\x1b[59m";

        // these can be overridden (e.g. disabled for legacy)
        string enterURL = "\x1b]8;;%s\x1b\\";
        string exitURL = "\x1b]8;;\x1b\\";
        string setWindowSize = "\x1b[8;%d;%dt";
        // Some terminals do not support the title stack, but do support
        // changing the title.  For those we set the title back to the
        // empty string (which they take to mean unset) as a reasonable
        // fallback. Shell programs generally change this as needed anyway.
        string saveTitle = "\x1b[22;2t";
        string restoreTitle = "\x1b]2;\x1b\\" ~ "\x1b[23;2t";
        string setTitle = "\x1b[>2t\x1b]2;%s\x1b\\";
        // three advanced keyboard protocols:
        // - xterm modifyOtherKeys (uses CSI 27 ~ )
        // - kitty csi-u (uses CSI u)
        // - win32-input-mode (uses CSI _)
        string enableCsiU = "\x1b[>4;2m" ~ "\x1b[>1u" ~ "\x1b[?9001h";
        string disableCsiU = "\x1b[?9001l" ~ "\x1b[<u" ~ "\x1b[>4;0m";
        // number of colors - again this can be overridden.
        // Typical values are 0 (monochrome), 8, 16, 256, and 1<<24.
        // There are some oddballs like xterm-88color.  The first
        // 256 colors are from the xterm palette, but if something
        // supports more, it is assumed to support direct RGB colors.
        // Pretty much most modern terminals support 256, which is why
        // we use it as a default.  (This can be affected by environment
        // variables.)
        int numColors = 256;

        // requestWindowSize = "\x1b[18t"                          // For modern terminals
    }

    this()
    {
        version (Posix)
        {
            import dcell.termio : PosixTty;

            this(new PosixTty("/dev/tty"), "");
        }
        else version (Windows)
        {
            import dcell.wintty : WinTty;

            this(new WinTty());
        }
        else
        {
            throw new Exception("no default TTY for platform");
        }
    }

    this(Tty tt, string term = "")
    {
        ti = tt;
        ti.start();
        cells = new CellBuffer(ti.windowSize());
        evq = new TtyEventQ();
        ob = new OutBuffer();
        cells.style.bg = Color.reset;
        cells.style.fg = Color.reset;

        if (term == "")
        {
            term = environment.get("TERM");
        }

        legacy = false;
        if (term.startsWith("vt") || term.canFind("ansi") || term == "linux" || term == "sun" || term == "sun-color")
        {
            // these terminals are "legacy" and not expected to support most OSC functions
            legacy = true;
        }

        string cterm = environment.get("COLORTERM");
        if ("NO_COLOR" in environment)
        {
            vt.numColors = 0;
        }
        else if (cterm == "truecolor" || cterm == "24bit" || cterm == "24-bit")
        {
            vt.numColors = 1 << 24;
        }
        else if (term.endsWith("256color") || cterm.canFind("256"))
        {
            vt.numColors = 256;
        }
        else if (term.endsWith("88color"))
        {
            vt.numColors = 88;
        }
        else if (term.endsWith("16color"))
        {
            vt.numColors = 16;
        }
        else if (cterm != "")
        {
            vt.numColors = 8;
        }
        else if (term.endsWith("-m") || term.canFind("mono") || term.startsWith("vt"))
        {
            vt.numColors = 0;
        }
        else if (term.endsWith("color") || term.canFind("ansi"))
        {
            vt.numColors = 8;
        }
        else if (term == "dtterm" || term == "aixterm" || term == "linux")
        {
            vt.numColors = 8;
        }
        else if (term == "sun")
        {
            vt.numColors = 0;
        }

        if (environment.get("DCELL_ALTSCREEN") == "disable")
        {
            altScrEn = false;
        }
        else
        {
            altScrEn = true;
        }

        version (Windows)
        {
            // If we don't have a $TERM (e.g. Windows Terminal), or we are dealing with WezTerm
            // (which cannot mix modes), then only support win32-input-mode.
            if (term == "")
            {
                vt.enableCsiU = "\x1b[?9001h";
                vt.disableCsiU = "\x1b[?9001l";
            }
        }

        if (legacy)
        {
            vt.enterURL = null;
            vt.exitURL = null;
            vt.setWindowSize = null;
            vt.setTitle = null;
            vt.restoreTitle = null;
            vt.saveTitle = null;
            vt.enableCsiU = null;
            vt.disableCsiU = null;
        }
    }

    ~this()
    {
        ti.close();
    }

    void start()
    {
        if (started)
            return;

        parser = new Parser(); // if we are restarting, this discards the old one
        ti.save();
        ti.raw();
        if (altScrEn)
        {
            puts(vt.enterCA);
        }
        puts(vt.hideCursor);
        puts(vt.disableAutoMargin);
        puts(vt.enableCsiU);
        puts(vt.saveTitle);
        puts(vt.enterKeypad);
        puts(vt.enableFocus);
        puts(vt.enableAltChars);
        puts(vt.clear);
        if (title && !vt.setTitle.empty)
        {
            puts(format(vt.setTitle, title));
        }

        resize();
        draw();

        started = true;
    }

    void stop()
    {
        if (!started)
            return;

        puts(vt.enableAutoMargin);
        puts(vt.resetFgBg);
        puts(vt.sgr0);
        puts(vt.cursorReset);
        puts(vt.showCursor);
        puts(vt.cursorReset);
        puts(vt.restoreTitle);
        if (altScrEn)
        {
            puts(vt.clear);
            puts(vt.exitCA);
        }
        puts(vt.exitKeypad);
        puts(vt.disablePaste);
        puts(vt.disableMouse);
        puts(vt.disableFocus);
        puts(vt.disableCsiU);
        flush();
        ti.stop();
        ti.restore();
        started = false;
    }

    void clear() @safe
    {
        // save the style currently in effect, so when
        // we later send the clear, we can use it.
        baseStyle = style;
        fill(" ");
        clear_ = true;
        // because we are going to clear it in the next cycle,
        // lets mark all the cells clean, so that we don't waste
        // needless time redrawing spaces for the entire screen.
        cells.setAllDirty(false);
    }

    void fill(string s, Style style) @safe
    {
        cells.fill(s, style);
    }

    void fill(string s) @safe
    {
        fill(s, this.style);
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

    void resize() @safe
    {
        auto phys = ti.windowSize();
        if (phys != cells.size())
        {
            cells.resize(phys);
            cells.setAllDirty(true);
        }
    }

    ref Cell opIndex(size_t x, size_t y) @safe
    {
        return (cells[x, y]);
    }

    void opIndexAssign(Cell c, size_t x, size_t y) @safe
    {
        cells[x, y] = c;
    }

    void enablePaste(bool b) @safe
    {
        pasteEn = b;
        sendPasteEnable(b);
    }

    int colors() const pure nothrow @safe
    {
        return vt.numColors;
    }

    void show() @safe
    {
        resize();
        draw();
    }

    void sync() @safe
    {
        pos_ = Coord(-1, -1);
        resize();
        clear_ = true;
        cells.setAllDirty(true);
        draw();
    }

    void beep() @safe
    {
        puts("\x07");
        flush();
    }

    void setSize(Coord size) @safe
    {
        if (vt.setWindowSize != "")
        {
            puts(format(vt.setWindowSize, size.y, size.x));
            flush();
            cells.setAllDirty(true);
            resize();
        }
    }

    void enableMouse(MouseEnable en) @safe
    {
        // we rely on the fact that all known implementations adhere
        // to the de-facto standard from XTerm.  This is necessary as
        // there is no standard terminfo sequence for reporting this
        // information.
        mouseEn = en; // save this so we can restore after a suspend
        sendMouseEnable(en);
    }

    void enableAlternateScreen(bool enabled) @safe
    {
        altScrEn = enabled;
        if (environment.get("DCELL_ALTSCREEN") == "disable")
        {
            altScrEn = false;
        }
    }

    void setTitle(string title) @safe
    {
        this.title = title;
        if (started && !vt.setTitle.empty)
        {
            puts(format(vt.setTitle, title));
            flush();
        }
    }

    bool waitForEvent(Duration timeout, ref Duration resched) @safe
    {
        // expire for a time when we will timeout, safeguard against obvious overflow.
        MonoTime expire = (timeout == Duration.max) ? MonoTime.max : MonoTime.currTime() + timeout;

        // residual tracks whether we are waiting for the rest of
        // a partial escape sequence in the parser.
        bool residual = false;
        bool readOnce = false;

        for (;;)
        {
            evq ~= parser.events();
            if (ti.resized())
            {
                Event rev;
                rev.type = EventType.resize;
                rev.when = MonoTime.currTime();
                evq ~= rev;
            }
            if (!evq.empty)
            {
                return true;
            }

            MonoTime now = MonoTime.currTime();

            // if we expired, and we haven't at least called the
            // read function once, then return.
            Duration interval = expire - now;

            if (expire < now)
            {
                if (readOnce)
                {
                    resched = residual ? msecs(25) : Duration.max;
                    return false;
                }
                interval = msecs(0); // just do a polling read
            }

            readOnce = true;

            // if we have partial data in the parser, we need to use
            // a shorter wakeup, so we can create an event in case the
            // escape sequence is not completed (e.g. lone ESC.)
            if (residual && interval > msecs(5))
            {
                interval = msecs(5);
            }

            residual = !parser.parse(ti.read(interval));
        }
    }

    EventQ events() nothrow @safe @nogc
    {
        return evq;
    }

    // This is the default style we use when writing content using
    // put and similar APIs.
    @property ref Style style() @safe
    {
        return cells.style;
    }

    @property Style style(const(Style) st) @safe
    {
        return cells.style = st;
    }

    // This is the current position that will be writing when when using
    // put or write.
    @property Coord position() const @safe
    {
        return cells.position;
    }

    @property Coord position(const(Coord) pos) @safe
    {
        return cells.position = pos;
    }

    // Write a string at the current `position`, using the current `style`.
    // This will wrap if it reaches the end of the terminal.
    void write(string s) @safe
    {
        cells.write(s);
    }

    void write(wstring s) @safe
    {
        cells.write(s);
    }

    void write(dstring s) @safe
    {
        cells.write(s);
    }

private:
    struct KeyCode
    {
        Key key;
        Modifiers mod;
    }

    class TtyEventQ : EventQ
    {
        override void put(Event ev) @safe
        {
            super.put(ev);
            ti.wakeUp();
        }

        // Note that this operator (~=) intentionally
        // calls the parents put directly to prevent spurious wakeups
        // when adding events that have already come from the tty.
        // It is significant that this method (indeed the entire class)
        // is private, so it should not be accessible by external consumers.
        void opOpAssign(string op : "~")(Event rhs) nothrow @safe
        {
            super.put(rhs);
        }

        // Permit appending a list of events read from the parser directly, but
        // without waking up the reader.
        void opOpAssign(string op : "~")(Event[] rhs) nothrow @safe
        {
            foreach (ev; rhs)
            {
                super.put(ev);
            }
        }
    }

    CellBuffer cells;
    bool clear_; // if a screen clear is requested
    Coord pos_; // location where we will update next
    Style style_; // current style
    Style baseStyle;
    Coord cursorPos;
    Cursor cursorShape;
    MouseEnable mouseEn; // saved state for suspend/resume
    bool pasteEn; // saved state for suspend/resume
    bool altScrEn; // alternate screen is enabled (default on)
    Tty ti;
    OutBuffer ob;
    bool started;
    bool legacy; // legacy terminals don't have support for OSC, APC, DSC, etc.
    Vt vt;
    Parser parser;
    string title;
    TtyEventQ evq;

    void puts(string s) @safe
    {
        ob.write(s);
    }

    // flush queued output
    void flush() @safe
    {
        ti.write(ob.toString());
        ti.flush();
        ob.clear();
    }

    // sendColors sends just the colors for a given style
    void sendColors(Style style) @safe
    {
        auto fg = style.fg;
        auto bg = style.bg;

        if (vt.numColors == 0 || (fg == Color.invalid && bg == Color.invalid))
        {
            return;
        }

        if (style.ul.isValid && (style.attr & Attr.underlineMask))
        {
            if (style.ul == Color.reset)
            {
                puts(vt.underFg);
            }
            else if (style.ul.isRGB && vt.numColors > 256)
            {
                auto rgb = decompose(style.ul);
                puts(format!(vt.underRGB)(rgb[0], rgb[1], rgb[2]));
            }
            else
            {
                auto ul = toPalette(style.ul, vt.numColors);
                puts(format!(vt.underColor)(ul));
            }
        }
        if (fg == Color.reset || bg == Color.reset)
        {
            puts(vt.resetFgBg);
        }
        if (vt.numColors > 256)
        {
            if (isRGB(fg) && isRGB(bg))
            {
                auto rgb1 = decompose(fg);
                auto rgb2 = decompose(bg);
                puts(format!(vt.setFgBgRGB)(rgb1[0], rgb1[1], rgb1[2], rgb2[0], rgb2[1], rgb2[2]));
                return;
            }
            if (isRGB(fg))
            {
                auto rgb = decompose(fg);
                puts(format!(vt.setFgRGB)(rgb[0], rgb[1], rgb[2]));
                fg = Color.invalid;
            }
            if (isRGB(bg))
            {
                auto rgb = decompose(bg);
                puts(format!(vt.setBgRGB)(rgb[0], rgb[1], rgb[2]));
                bg = Color.invalid;
            }
        }

        fg = toPalette(fg, vt.numColors);
        bg = toPalette(bg, vt.numColors);

        if (fg < 8)
        {
            puts(format!(vt.setFg8)(fg));
        }
        else if (fg < 256)
        {
            puts(format!(vt.setFg256)(fg));
        }
        if (bg < 8)
        {
            puts(format!(vt.setBg8)(bg));
        }
        else if (bg < 256)
        {
            puts(format!(vt.setBg256)(bg));
        }
    }

    void sendAttrs(Style style) @safe
    {
        auto attr = style.attr;
        if (attr & Attr.bold)
            puts(vt.bold);
        if (attr & Attr.reverse)
            puts(vt.reverse);
        if (attr & Attr.blink)
            puts(vt.blink);
        if (attr & Attr.dim)
            puts(vt.dim);
        if (attr & Attr.italic)
            puts(vt.italic);
        if (attr & Attr.strikethrough)
            puts(vt.strikeThrough);
        switch (attr & Attr.underlineMask)
        {
        case Attr.plainUnderline:
            puts(vt.underline);
            break;
        case Attr.doubleUnderline:
            puts(vt.underline);
            puts(vt.doubleUnder);
            break;
        case Attr.curlyUnderline:
            puts(vt.underline);
            puts(vt.curlyUnder);
            break;
        case Attr.dottedUnderline:
            puts(vt.underline);
            puts(vt.dottedUnder);
            break;
        case Attr.dashedUnderline:
            puts(vt.underline);
            puts(vt.dashedUnder);
            break;
        default:
            break;
        }
    }

    void clearScreen() @safe
    {
        if (clear_)
        {
            // We want to use the style that was in effect
            // when the clear function was called.
            Style savedStyle = style;
            style = baseStyle;
            clear_ = false;
            puts(vt.sgr0);
            puts(vt.exitURL);
            sendColors(style);
            sendAttrs(style);
            style_ = style;
            puts(Vt.clear);
            flush();
            style = savedStyle;
        }
    }

    void goTo(Coord pos) @safe
    {
        if (pos != pos_)
        {
            puts(format!(vt.setCursorPosition)(pos.y + 1, pos.x + 1));
            pos_ = pos;
        }
    }

    // sendCursor sends the current cursor location
    void sendCursor() @safe
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
    int drawCell(Coord pos) @safe
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

        if (vt.numColors == 0)
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
            if (c.style.url != "" && vt.enterURL !is null)
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

    void draw() @safe
    {
        puts(vt.startSyncOut);
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
        puts(vt.endSyncOut);
        flush();
    }

    void sendMouseEnable(MouseEnable en) @safe
    {
        // we rely on the fact that all known implementations adhere
        // to the de-facto standard from XTerm.  This is necessary as
        // there is no standard terminfo sequence for reporting this
        // information.
        // start by disabling everything
        puts(vt.disableMouse);
        // then turn on specific enables
        if (en & MouseEnable.buttons)
        {
            puts(vt.enableButtons);
        }
        if (en & MouseEnable.drag)
        {
            puts(vt.enableDrag);
        }
        if (en & MouseEnable.motion)
        {
            puts(vt.enableMotion);
        }
        // and if any are set, we need to send this
        if (en & MouseEnable.all)
        {
            puts(vt.mouseSgr);
        }
        flush();
    }

    void sendPasteEnable(bool b) @safe
    {
        puts(b ? Vt.enablePaste : Vt.disablePaste);
        flush();
    }
}
