// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.ttyscreen;

import std.string;
import std.variant;
import std.utf;

import dcell.cell;
import dcell.cursor;
import dcell.key;
import dcell.mouse;
import dcell.terminfo;
import dcell.tty;
import dcell.screen;
import dcell.event;

class TtyScreen : Screen
{
    this(Tty tt, Terminfo tinfo)
    {
        tty = tt;
        ti = tinfo;
        auto size = tty.windowSize();
        cells = new CellBuffer(size);
    }

    ~this()
    {
        tty.drain();
        tty.stop();
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

    bool hasMouse()
    {
        return ti.caps.mouse != "";
    }

    int colors()
    {
        return ti.caps.colors;
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
            puts(ti.caps.bell);
    }

    void setSize(Coord size)
    {
        synchronized (this)
        {
            if (ti.caps.setWindowSize != "")
            {
                puts(ti.tParm(ti.caps.setWindowSize, size.x, size.y));
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
            if (ti.caps.mouse != "")
            {
                mouseEn = en; // save this so we can restore after a suspend
                sendMouseEnable(en);
            }
        }
    }

    void handleEvents(void delegate(Variant) handler)
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

    Terminfo ti;
    CellBuffer cells;
    Tty tty;
    bool clear_; // if a sceren clear is requested
    Coord pos_; // location where we will update next
    Style style_; // current style
    Coord cursorPos;
    Cursor cursorShape;
    bool[Key] keyExist; // indicator of keys that are mapped
    KeyCode[string] keyCodes; // sequence (escape) to a key
    MouseEnable mouseEn; // saved state for suspend/resume
    bool pasteEn; // saved state for suspend/resume
    void delegate(Variant) evHandler;
    bool stopping; // if true we are in the process of shutting down

    // puts emits a parameterized string that may contain embedded delay padding.
    // it should not be used for user-supplied strings.
    void puts(string s)
    {
        ti.tPuts(s, tty.file());
    }

    // sendColors sends just the colors for a given style
    void sendColors(Style style)
    {
        auto fg = style.fg;
        auto bg = style.bg;

        if (fg == Color.reset || bg == Color.reset)
        {
            puts(ti.caps.resetColors);
        }
        if (ti.caps.colors > 256)
        {
            if (ti.caps.setFgBgRGB != "" && isRGB(fg) && isRGB(bg))
            {
                auto rgb1 = decompose(fg);
                auto rgb2 = decompose(bg);
                puts(ti.tParm(ti.caps.setFgBgRGB,
                        rgb1[0], rgb1[1], rgb1[2], rgb2[0], rgb2[1], rgb2[2]));
            }
            else
            {
                if (isRGB(fg) && ti.caps.setFgRGB != "")
                {
                    auto rgb = decompose(fg);
                    puts(ti.tParm(ti.caps.setFgRGB, rgb[0], rgb[1], rgb[2]));
                }
                if (isRGB(bg) && ti.caps.setBgRGB != "")
                {
                    auto rgb = decompose(bg);
                    puts(ti.tParm(ti.caps.setBgRGB, rgb[0], rgb[1], rgb[2]));
                }
            }
        }
        else
        {
            // TODO: we should fit these to closest palette match
            fg = toPalette(fg);
            bg = toPalette(bg);
        }
        if (fg < 256 && bg < 256 && ti.caps.setFgBg != "")
            puts(ti.tParm(ti.caps.setFgBg, fg, bg));
        else
        {
            if (fg < 256)
                puts(ti.tParm(ti.caps.setFg, fg));
            if (bg < 256)
                puts(ti.tParm(ti.caps.setBg, bg));
        }

    }

    void sendAttrs(Style style)
    {
        auto attr = style.attr;
        if (attr & Attr.bold)
            puts(ti.caps.bold);
        if (attr & Attr.underline)
            puts(ti.caps.underline);
        if (attr & Attr.reverse)
            puts(ti.caps.reverse);
        if (attr & Attr.blink)
            puts(ti.caps.blink);
        if (attr & Attr.dim)
            puts(ti.caps.dim);
        if (attr & Attr.italic)
            puts(ti.caps.italic);
        if (attr & Attr.strikethrough)
            puts(ti.caps.strikethrough);
    }

    void clearScreen()
    {
        if (clear_)
        {
            clear_ = false;
            puts(ti.caps.attrOff);
            puts(ti.caps.exitURL);
            sendColors(style_);
            sendAttrs(style_);
            puts(ti.caps.clear);
        }
    }

    void goTo(Coord pos)
    {
        if (pos != pos_)
        {
            puts(ti.tGoto(pos.x, pos.y));
            pos_ = pos;
        }
    }

    // sendCursor sends the current cursor location
    void sendCursor()
    {
        if (!cells.isLegal(cursorPos) || (cursorShape == Cursor.hidden))
        {
            if (ti.caps.hideCursor != "")
            {
                puts(ti.caps.hideCursor);
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
        puts(ti.caps.showCursor);
        final switch (cursorShape)
        {
        case Cursor.current:
            break;
        case Cursor.hidden:
            puts(ti.caps.hideCursor);
            break;
        case Cursor.reset:
            puts(ti.caps.cursorReset);
            break;
        case Cursor.bar:
            puts(ti.caps.cursorBar);
            break;
        case Cursor.block:
            puts(ti.caps.cursorBlock);
            break;
        case Cursor.underline:
            puts(ti.caps.cursorUnderline);
            break;
        case Cursor.blinkingBar:
            puts(ti.caps.cursorBlinkingBar);
            break;
        case Cursor.blinkingBlock:
            puts(ti.caps.cursorBlinkingBlock);
            break;
        case Cursor.blinkingUnderline:
            puts(ti.caps.cursorBlinkingUnderline);
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
        if ((pos.y == size.y - 1) && (pos.x == size.x - 1) && ti.caps.automargin && (
                ti.caps.insertChar != ""))
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
        if (ti.caps.colors == 0)
        {
            // monochrome, we just look at luminance and possibly
            // reverse the video.
            // TODO: implement palette lookup
            // if need be, c.style.attr ^= Attr.reverse;
        }
        if (ti.caps.enterURL == "")
        { // avoid pointless changes due to URL where not supported
            c.style.url = "";
        }

        if (c.style.fg != style_.fg || c.style.bg != style_.bg || c.style.attr != style_.attr)
        {
            puts(ti.caps.attrOff);
            sendColors(c.style);
            sendAttrs(c.style);
        }
        if (c.style.url != style_.url)
        {
            if (c.style.url != "")
            {
                puts(ti.tParmString(ti.caps.enterURL, c.style.url));
            }
            else
            {
                puts(ti.caps.exitURL);
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
        if (ti.caps.automargin && pos_.x >= c.width)
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
        puts(ti.caps.hideCursor); // hide the cursor while we draw
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
        if (ti.caps.mouse != "")
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
        }

    }

    void sendPasteEnable(bool b)
    {
        puts(b ? ti.caps.enablePaste : ti.caps.disablePaste);
    }

    // prepareKeyMod is used to populate the keys
    void prepareKeyMod(Key key, Modifiers mod, string val)
    {
        if (val == "")
            return;
        if (val !in keyCodes)
        {
            keyExist[key] = true;
            keyCodes[val] = KeyCode(key, mod);
        }
    }

    // prepareKeyModReplace loads a key sequence, and optionally replaces
    // a previously existing one if it matches.
    void prepareKeyModReplace(Key key, Key replace, Modifiers mod, string val)
    {
        if (val == "")
            return;
        if ((val !in keyCodes) || keyCodes[val].key == replace)
        {
            keyExist[key] = true;
            keyCodes[val] = KeyCode(key, mod);
        }
    }

    void mainLoop()
    {

    }

    // inputLoop reads from our TTY, and posts bytes read (on success)
    // to the mainLoop thread.  If read fails, it posts an error and exits.
    void inputLoop()
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
        auto ti = new Terminfo(caps);
        writeln("STEP 4");
        assert(ti !is null);
        assert(ti.caps.name != "");
        writeln("CAPS IS OK");
        auto ts = new TtyScreen(tty, ti);
        writeln("STEP 5");
        assert(ts !is null);

        writeln("COLS ", ts.size().x, " ROWS ", ts.size().y);
        ts.tty.start();

        writeln("CLEARING...");
        ts.clear();
        writeln("CLEARED?");
        ts.show();
        writeln("SHOWN");
        import core.thread;

        Thread.sleep(dur!("seconds")(1));
        destroy(ts);
    }
}
