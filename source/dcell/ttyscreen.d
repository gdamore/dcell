// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.ttyscreen;

import core.time;
import std.string;
import std.utf;
import std.concurrency;

import dcell.cell;
import dcell.cursor;
import dcell.key;
import dcell.mouse;
import dcell.terminfo;
import dcell.tty;
import dcell.screen;
import dcell.event;
import dcell.parser;

class TtyScreen : Screen
{
    this(Tty tt, const Termcap* tc)
    {
        caps = tc;
        tty = tt;
        cells = new CellBuffer(tty.windowSize());
        parser = new shared Parser(caps);
    }

    ~this()
    {
        stop();
    }

    void start()
    {
        synchronized (this)
        {
            tty.start();
            puts(caps.clear);
            resize();
            draw();
            flush();
        }
    }

    void stop()
    {
        synchronized (this)
        {
            puts(caps.resetColors);
            puts(caps.attrOff);
            puts(caps.cursorReset);
            puts(caps.showCursor);
            puts(caps.cursorReset);
            puts(caps.clear);
            tty.drain();
            tty.stop();
        }
    }

    void clear()
    {
        synchronized (this)
        {
            fill(" ");
            clear_ = true;
            // because we are going to clear it in the next cycle,
            // lets mark all the cells clean, so that we don't waste
            // needless time redrawing spaces for the entire screen.
            cells.setAllDirty(false);
        }
    }

    void fill(string s, Style style)
    {
        synchronized (this)
            cells.fill(s, style);
    }

    void fill(string s)
    {
        synchronized (this)
            fill(s, this.style_);
    }

    void showCursor(Coord pos, Cursor cur = Cursor.current)
    {
        synchronized (this)
        {
            // just save the coordinates for now
            // it will be used during the next draw cycle
            cursorPos = pos;
            cursorShape = cur;
        }
    }

    void showCursor(Cursor cur)
    {
        synchronized (this)
            cursorShape = cur;
    }

    Coord size()
    {
        synchronized (this)
            return (cells.size());
    }

    const(Cell) opIndex(Coord pos)
    {
        synchronized (this)
            return (cells[pos]);
    }

    void opIndexAssign(Cell c, Coord pos)
    {
        synchronized (this)
            cells[pos] = c;
    }

    void enablePaste(bool b)
    {
        synchronized (this)
        {
            pasteEn = b;
            sendPasteEnable(b);
        }
    }

    bool hasMouse() pure
    {
        return caps.mouse != "";
    }

    int colors() pure
    {
        return caps.colors;
    }

    void show()
    {
        synchronized (this)
        {
            resize();
            draw();
        }
    }

    void sync()
    {
        synchronized (this)
        {
            pos_ = Coord(-1, -1);
            resize();
            clear_ = true;
            cells.setAllDirty(true);
            draw();
        }
    }

    void beep()
    {
        synchronized (this)
        {
            puts(caps.bell);
            flush();
        }
    }

    void setSize(Coord size)
    {
        synchronized (this)
        {
            if (caps.setWindowSize != "")
            {
                puts(caps.setWindowSize, size.x, size.y);
                flush();
                cells.setAllDirty(true);
                resize();
            }
        }
    }

    bool hasKey(Key k)
    {
        if (k == Key.rune)
        {
            return true;
        }
        return (k in keyExist ? true : false);
    }

    void enableMouse(MouseEnable en)
    {
        // we rely on the fact that all known implementations adhere
        // to the de-facto standard from XTerm.  This is necessary as
        // there is no standard terminfo sequence for reporting this
        // information.
        synchronized (this)
        {
            if (caps.mouse != "")
            {
                mouseEn = en; // save this so we can restore after a suspend
                sendMouseEnable(en);
            }
        }
    }

    void handleEvents(void delegate(Event) handler)
    {
        synchronized (this)
        {
            evHandler = handler;
        }
    }

private:
    struct KeyCode
    {
        Key key;
        Modifiers mod;
    }

    const Termcap* caps;
    CellBuffer cells;
    Tty tty;
    bool clear_; // if a sceren clear is requested
    Coord pos_; // location where we will update next
    Style style_; // current style
    Coord cursorPos;
    Cursor cursorShape;
    MouseEnable mouseEn; // saved state for suspend/resume
    bool pasteEn; // saved state for suspend/resume
    void delegate(Event) evHandler;
    bool stopping; // if true we are in the process of shutting down
    shared Parser parser;
    bool[Key] keyExist; // indicator of keys that are mapped
    KeyCode[string] keyCodes; // sequence (escape) to a key

    // puts emits a parameterized string that may contain embedded delay padding.
    // it should not be used for user-supplied strings.
    void puts(string s)
    {
        Termcap.puts(tty.file.lockingBinaryWriter(), s, &flush);
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
        tty.file.flush();
    }

    // sendColors sends just the colors for a given style
    void sendColors(Style style)
    {
        auto fg = style.fg;
        auto bg = style.bg;

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
            // TODO: we should fit these to closest palette match
            fg = toPalette(fg);
            bg = toPalette(bg);
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
            sendColors(style_);
            sendAttrs(style_);
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

        // TODO: default style?  maybe not needed
        if (caps.colors == 0)
        {
            // monochrome, we just look at luminance and possibly
            // reverse the video.
            // TODO: implement palette lookup
            // if need be, c.style.attr ^= Attr.reverse;
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

        tty.write(cast(ubyte[]) c.text);
        pos_.x += c.width;
        if (caps.automargin && pos_.x >= c.width)
        {
            pos_.x = 1;
            pos_.y++;
        }
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

    void resize()
    {
        auto phys = tty.windowSize();
        if (phys != cells.size())
        {
            cells.resize(phys);
            cells.setAllDirty(true);
            // TODO: POST AN EVENT
        }
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

    void recvInput(ubyte[] b, ref Duration timer)
    {
        if (!parser.parse(b))
            timer = msecs(50);
        else
            timer = seconds(3600);
    }

    void mainLoop()
    {

        auto unhandled = false;
        auto timer = seconds(3600); // we will wake up at least once an hour
        for (;;)
        {
            receiveTimeout(timer,
                (ubyte[] b) { recvInput(b, timer); },
            );

            auto events = parser.events();
            foreach (Event ev; events)
            {
                synchronized (this)
                {
                    if (evHandler !is null)
                    {
                        evHandler(ev);
                    }
                }
            }
        }
    }

    // inputLoop reads from our TTY, and posts bytes read (on success)
    // to the mainLoop thread.  If read fails, it posts an error and exits.
    void inputLoop(Tid loopTid)
    {
        for (;;)
        {
            synchronized (this)
            {
                if (stopping)
                {
                    return;
                }
            }
            ubyte[] b;
            try
            {
                b = tty.read();
            }
            catch (Exception e)
            {
                // TODO: post an event message
                return;
            }
            if (b.length == 0)
            {
                break;
            }

        }
    }
}

unittest
{
    version (Posix)
    {
        import dcell.devtty;
        import std.stdio;

        writeln("STEP 1");
        //        import dcell.terminfo.database;
        auto caps = Database.get("xterm-256color");
        writeln("STEP 2");
        assert(caps.name != "");
        auto tty = new DevTty();
        writeln("STEP 3");
        assert(tty !is null);
        auto ts = new TtyScreen(tty, caps);
        writeln("STEP 5");
        assert(ts !is null);
        assert(ts.caps.setFgBg != "");

        ts.start();

        ts.showCursor(Coord(0, 0), Cursor.hidden);
        auto c = ts.size();
        c.x /= 2;
        c.y /= 2;
        ts[c] = Cell("A", Style(Color.white, Color.red, Attr.underline), 1);
        c.x++;
        ts[c] = Cell("B", Style(Color.white, Color.green, Attr.underline), 1);
        ts.show();
        import core.thread;

        Thread.sleep(dur!("seconds")(2));
        destroy(ts);
    }
}
