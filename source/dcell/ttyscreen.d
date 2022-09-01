// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.ttyscreen;

import std.string;

import dcell.cell;
import dcell.cursor;
import dcell.key;
import dcell.mouse;
import dcell.terminfo;
import dcell.tty;
import dcell.screen;

class TtyScreen : Screen
{

    // abstract int setup();
    // abstract void teardown();

    this(Tty tty, Terminfo ti)
    {
        this.tty = tty;
        this.ti = ti;

        prepareKeys();
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
        fill(s, this.style_);
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

    Coord size()
    {
        return (cells.size());
    }

    const(Cell) opIndex(Coord pos)
    {
        return (cells[pos]);
    }

    void opIndexAssign(Cell c, Coord pos)
    {
        cells[pos] = c;
    }

    void enablePaste(bool b)
    {
        pasteEn = b;
        sendPasteEnable(b);
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
        puts(ti.caps.bell);
    }

    void setSize(Coord size)
    {
        if (ti.caps.setWindowSize != "")
        {
            puts(ti.tParm(ti.caps.setWindowSize, size.x, size.y));
            cells.setAllDirty(true);
            resize();
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
        if (ti.caps.mouse != "")
        {
            mouseEn = en; // save this so we can restore after a suspend
            sendMouseEnable(en);
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

        tty.write(cast(byte[]) c.text);
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

    void prepareKeyModXTerm(Key key, string val)
    {
        if (val.length > 2 && val[0] == '\x1b' && val[1] == '[' && val[$ - 1] == '~')
        {
            // These suffixes are calculated assuming Xterm style modifier suffixes.
            // Please see https://invisible-island.net/xterm/ctlseqs/ctlseqs.pdf for
            // more information (specifically "PC-Style Function Keys").
            val = val[0 .. $ - 1]; // drop trailing ~
            prepareKeyModReplace(key, cast(Key)(key + 12), Modifiers.shift, val ~ ";2~");
            prepareKeyModReplace(key, cast(Key)(key + 48), Modifiers.alt, val ~ ";3~");
            prepareKeyModReplace(key, cast(Key)(key + 60), Modifiers.alt | Modifiers.shift, val ~ ";4~");
            prepareKeyModReplace(key, cast(Key)(key + 24), Modifiers.ctrl, val ~ ";5~");
            prepareKeyModReplace(key, cast(Key)(key + 36), Modifiers.ctrl | Modifiers.shift, val ~ ";6~");
            prepareKeyMod(key, Modifiers.alt | Modifiers.ctrl, val ~ ";7~");
            prepareKeyMod(key, Modifiers.shift | Modifiers.alt | Modifiers.ctrl, val ~ ";8~");
            prepareKeyMod(key, Modifiers.meta, val ~ ";9~");
            prepareKeyMod(key, Modifiers.meta | Modifiers.shift, val ~ ";10~");
            prepareKeyMod(key, Modifiers.meta | Modifiers.alt, val ~ ";11~");
            prepareKeyMod(key, Modifiers.meta | Modifiers.shift | Modifiers.alt, val ~ ";12~");
            prepareKeyMod(key, Modifiers.meta | Modifiers.ctrl, val ~ ";13~");
            prepareKeyMod(key, Modifiers.meta | Modifiers.ctrl | Modifiers.shift, val ~ ";14~");
            prepareKeyMod(key, Modifiers.meta | Modifiers.ctrl | Modifiers.alt, val ~ ";15~");
            prepareKeyMod(key, Modifiers.meta | Modifiers.ctrl | Modifiers.shift | Modifiers.alt, val ~ ";16~");
        }
        else if (val.length == 3 && val[0] == '\x1b' && val[1] == '0')
        {
            val = val[2 .. $];
            prepareKeyModReplace(key, cast(Key)(key + 12), Modifiers.shift, "\x1b[1;2" ~ val);
            prepareKeyModReplace(key, cast(Key)(key + 48), Modifiers.alt, "\x1b[1;3" ~ val);
            prepareKeyModReplace(key, cast(Key)(key + 24), Modifiers.ctrl, "\x1b[1;5" ~ val);
            prepareKeyModReplace(key, cast(Key)(key + 36), Modifiers.ctrl | Modifiers.shift, "\x1b[1;6" ~ val);
            prepareKeyModReplace(key, cast(Key)(key + 60), Modifiers.alt | Modifiers.shift, "\x1b[1;4" ~ val);
            prepareKeyMod(key, Modifiers.alt | Modifiers.ctrl, "\x1b[1;7" ~ val);
            prepareKeyMod(key, Modifiers.shift | Modifiers.alt | Modifiers.ctrl, "\x1b[1;8" ~ val);
            prepareKeyMod(key, Modifiers.meta, "\x1b[1;9" ~ val);
            prepareKeyMod(key, Modifiers.meta | Modifiers.shift, "\x1b[1;10" ~ val);
            prepareKeyMod(key, Modifiers.meta | Modifiers.alt, "\x1b[1;11" ~ val);
            prepareKeyMod(key, Modifiers.meta | Modifiers.alt | Modifiers.shift, "\x1b[1;12" ~ val);
            prepareKeyMod(key, Modifiers.meta | Modifiers.ctrl, "\x1b[1;13" ~ val);
            prepareKeyMod(key, Modifiers.meta | Modifiers.ctrl | Modifiers.shift, "\x1b[1;14" ~ val);
            prepareKeyMod(key, Modifiers.meta | Modifiers.ctrl | Modifiers.alt, "\x1b[1;15" ~ val);
            prepareKeyMod(key, Modifiers.meta | Modifiers.ctrl | Modifiers.alt | Modifiers.shift, "\x1b[1;16" ~ val);
        }
    }

    void prepareKey(Key key, string val)
    {
        prepareKeyMod(key, Modifiers.none, val);
    }

    void prepareXTermModifiers()
    {
        if (ti.caps.keyRight != "\x1b[;2C") // does this look "xtermish"?
            return;
        prepareKeyModXTerm(Key.right, ti.caps.keyRight);
        prepareKeyModXTerm(Key.left, ti.caps.keyLeft);
        prepareKeyModXTerm(Key.up, ti.caps.keyUp);
        prepareKeyModXTerm(Key.down, ti.caps.keyDown);
        prepareKeyModXTerm(Key.insert, ti.caps.keyInsert);
        prepareKeyModXTerm(Key.del, ti.caps.keyDelete);
        prepareKeyModXTerm(Key.pgUp, ti.caps.keyPgUp);
        prepareKeyModXTerm(Key.pgDn, ti.caps.keyPgDn);
        prepareKeyModXTerm(Key.home, ti.caps.keyHome);
        prepareKeyModXTerm(Key.end, ti.caps.keyEnd);
        prepareKeyModXTerm(Key.f1, ti.caps.keyF1);
        prepareKeyModXTerm(Key.f2, ti.caps.keyF2);
        prepareKeyModXTerm(Key.f3, ti.caps.keyF3);
        prepareKeyModXTerm(Key.f4, ti.caps.keyF4);
        prepareKeyModXTerm(Key.f5, ti.caps.keyF5);
        prepareKeyModXTerm(Key.f6, ti.caps.keyF6);
        prepareKeyModXTerm(Key.f7, ti.caps.keyF7);
        prepareKeyModXTerm(Key.f8, ti.caps.keyF8);
        prepareKeyModXTerm(Key.f9, ti.caps.keyF9);
        prepareKeyModXTerm(Key.f10, ti.caps.keyF10);
        prepareKeyModXTerm(Key.f11, ti.caps.keyF11);
        prepareKeyModXTerm(Key.f12, ti.caps.keyF12);
    }

    void prepareKeys()
    {
        prepareKey(Key.backspace, ti.caps.keyBackspace);
        prepareKey(Key.f1, ti.caps.keyF1);
        prepareKey(Key.f2, ti.caps.keyF2);
        prepareKey(Key.f3, ti.caps.keyF3);
        prepareKey(Key.f4, ti.caps.keyF4);
        prepareKey(Key.f5, ti.caps.keyF5);
        prepareKey(Key.f6, ti.caps.keyF6);
        prepareKey(Key.f7, ti.caps.keyF7);
        prepareKey(Key.f8, ti.caps.keyF8);
        prepareKey(Key.f9, ti.caps.keyF9);
        prepareKey(Key.f10, ti.caps.keyF10);
        prepareKey(Key.f11, ti.caps.keyF11);
        prepareKey(Key.f12, ti.caps.keyF12);
        prepareKey(Key.f13, ti.caps.keyF13);
        prepareKey(Key.f14, ti.caps.keyF14);
        prepareKey(Key.f15, ti.caps.keyF15);
        prepareKey(Key.f16, ti.caps.keyF16);
        prepareKey(Key.f17, ti.caps.keyF17);
        prepareKey(Key.f18, ti.caps.keyF18);
        prepareKey(Key.f19, ti.caps.keyF19);
        prepareKey(Key.f20, ti.caps.keyF20);
        prepareKey(Key.f21, ti.caps.keyF21);
        prepareKey(Key.f22, ti.caps.keyF22);
        prepareKey(Key.f23, ti.caps.keyF23);
        prepareKey(Key.f24, ti.caps.keyF24);
        prepareKey(Key.f25, ti.caps.keyF25);
        prepareKey(Key.f26, ti.caps.keyF26);
        prepareKey(Key.f27, ti.caps.keyF27);
        prepareKey(Key.f28, ti.caps.keyF28);
        prepareKey(Key.f29, ti.caps.keyF29);
        prepareKey(Key.f30, ti.caps.keyF30);
        prepareKey(Key.f31, ti.caps.keyF31);
        prepareKey(Key.f32, ti.caps.keyF32);
        prepareKey(Key.f33, ti.caps.keyF33);
        prepareKey(Key.f34, ti.caps.keyF34);
        prepareKey(Key.f35, ti.caps.keyF35);
        prepareKey(Key.f36, ti.caps.keyF36);
        prepareKey(Key.f37, ti.caps.keyF37);
        prepareKey(Key.f38, ti.caps.keyF38);
        prepareKey(Key.f39, ti.caps.keyF39);
        prepareKey(Key.f40, ti.caps.keyF40);
        prepareKey(Key.f41, ti.caps.keyF41);
        prepareKey(Key.f42, ti.caps.keyF42);
        prepareKey(Key.f43, ti.caps.keyF43);
        prepareKey(Key.f44, ti.caps.keyF44);
        prepareKey(Key.f45, ti.caps.keyF45);
        prepareKey(Key.f46, ti.caps.keyF46);
        prepareKey(Key.f47, ti.caps.keyF47);
        prepareKey(Key.f48, ti.caps.keyF48);
        prepareKey(Key.f49, ti.caps.keyF49);
        prepareKey(Key.f50, ti.caps.keyF50);
        prepareKey(Key.f51, ti.caps.keyF51);
        prepareKey(Key.f52, ti.caps.keyF52);
        prepareKey(Key.f53, ti.caps.keyF53);
        prepareKey(Key.f54, ti.caps.keyF54);
        prepareKey(Key.f55, ti.caps.keyF55);
        prepareKey(Key.f56, ti.caps.keyF56);
        prepareKey(Key.f57, ti.caps.keyF57);
        prepareKey(Key.f58, ti.caps.keyF58);
        prepareKey(Key.f59, ti.caps.keyF59);
        prepareKey(Key.f60, ti.caps.keyF60);
        prepareKey(Key.f61, ti.caps.keyF61);
        prepareKey(Key.f62, ti.caps.keyF62);
        prepareKey(Key.f63, ti.caps.keyF63);
        prepareKey(Key.f64, ti.caps.keyF64);
        prepareKey(Key.insert, ti.caps.keyInsert);
        prepareKey(Key.del, ti.caps.keyDelete);
        prepareKey(Key.home, ti.caps.keyHome);
        prepareKey(Key.end, ti.caps.keyEnd);
        prepareKey(Key.up, ti.caps.keyUp);
        prepareKey(Key.down, ti.caps.keyDown);
        prepareKey(Key.left, ti.caps.keyLeft);
        prepareKey(Key.right, ti.caps.keyRight);
        prepareKey(Key.pgUp, ti.caps.keyPgUp);
        prepareKey(Key.pgDn, ti.caps.keyPgDn);
        prepareKey(Key.help, ti.caps.keyHelp);
        prepareKey(Key.print, ti.caps.keyPrint);
        prepareKey(Key.cancel, ti.caps.keyCancel);
        prepareKey(Key.exit, ti.caps.keyExit);
        prepareKey(Key.backtab, ti.caps.keyBacktab);
        prepareKey(Key.pasteStart, ti.caps.pasteStart);
        prepareKey(Key.pasteEnd, ti.caps.pasteEnd);

        prepareKeyMod(Key.right, Modifiers.shift, ti.caps.keyShfRight);
        prepareKeyMod(Key.left, Modifiers.shift, ti.caps.keyShfLeft);
        prepareKeyMod(Key.up, Modifiers.shift, ti.caps.keyShfUp);
        prepareKeyMod(Key.down, Modifiers.shift, ti.caps.keyShfDown);
        prepareKeyMod(Key.home, Modifiers.shift, ti.caps.keyShfHome);
        prepareKeyMod(Key.end, Modifiers.shift, ti.caps.keyShfEnd);
        prepareKeyMod(Key.pgUp, Modifiers.shift, ti.caps.keyShfPgUp);
        prepareKeyMod(Key.pgDn, Modifiers.shift, ti.caps.keyShfPgDn);

        prepareKeyMod(Key.right, Modifiers.ctrl, ti.caps.keyCtrlRight);
        prepareKeyMod(Key.left, Modifiers.ctrl, ti.caps.keyCtrlLeft);
        prepareKeyMod(Key.up, Modifiers.ctrl, ti.caps.keyCtrlUp);
        prepareKeyMod(Key.down, Modifiers.ctrl, ti.caps.keyCtrlDown);
        prepareKeyMod(Key.home, Modifiers.ctrl, ti.caps.keyCtrlHome);
        prepareKeyMod(Key.end, Modifiers.ctrl, ti.caps.keyCtrlEnd);

        // Sadly, xterm handling of keycodes is somewhat erratic.  In
        // particular, different codes are sent depending on application
        // mode is in use or not, and the entries for many of these are
        // simply absent from terminfo on many systems.  So we insert
        // a number of escape sequences if they are not already used, in
        // order to have the widest correct usage.  Note that prepareKey
        // will not inject codes if the escape sequence is already known.
        // We also only do this for terminals that have the application
        // mode present.

        if (ti.caps.enterKeypad != "")
        {
            prepareKey(Key.up, "\x1b[A");
            prepareKey(Key.down, "\x1b[B");
            prepareKey(Key.right, "\x1b[C");
            prepareKey(Key.left, "\x1b[D");
            prepareKey(Key.end, "\x1b[F");
            prepareKey(Key.home, "\x1b[H");
            prepareKey(Key.del, "\x1b[3~");
            prepareKey(Key.home, "\x1b[1~");
            prepareKey(Key.end, "\x1b[4~");
            prepareKey(Key.pgUp, "\x1b[5~");
            prepareKey(Key.pgDn, "\x1b[6~");

            // Application mode
            prepareKey(Key.up, "\x1bOA");
            prepareKey(Key.down, "\x1bOB");
            prepareKey(Key.right, "\x1bOC");
            prepareKey(Key.left, "\x1bOD");
            prepareKey(Key.home, "\x1bOH");
        }

        // we look breifly at all the keyCodes we
        // have, to find their starting character.
        // the vast majority of these will be escape.
        bool[char] initials;
        foreach (string esc, KeyCode kc; keyCodes)
        {
            if (esc != "")
            {
                initials[esc[0]] = true;
            }
        }
        // Add key mappings for control keys.
        for (char i = 0; i < ' '; i++)
        {

            // If this is starting character (typically esc) of other sequences,
            // then do not set up the fast path mapping for it.
            // We need to let the read do the whole timeout thing.
            if (i in initials)
                continue;

            Key k = cast(Key) i;
            keyExist[k] = true;
            switch (k)
            {
            case Key.backspace, Key.tab, Key.esc, Key.enter:
                // these are directly typeable
                keyCodes["" ~ i] = KeyCode(k, Modifiers.none);
                break;
            default:
                // these are generally represented as a control sequence
                keyCodes["" ~ i] = KeyCode(k, Modifiers.ctrl);
                break;
            }
        }
    }
}

unittest
{
    version (Posix)
    {

    }
}
