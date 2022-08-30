// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.ttyscreen;

import dcell.cell;
import dcell.coord;
import dcell.terminfo;
import dcell.tty;
import dcell.style;

class TtyScreen /* : Screen */
{

    abstract int setup();
    abstract void teardown();

    /// Clears the screen.
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

    abstract void set(int x, int y, Cell c);
    abstract Cell get(int x, int y);

    void hideCursor()
    {
        if (ti.caps.hideCursor != "")
        {
            puts(ti.caps.hideCursor);
        }
        else
        {
            // can't hide it, so at least try to put it off somewhere
            // less obvious.
            auto c = cells.size;
            c.x--;
            c.y--;
            goTo(c);
        }
    }

    abstract void showCursor();
    // TODO: setCursorStyle();
    abstract void size(ref int w, ref int h);

    // TODO: event posting, and polling (for keyboard)

    abstract void enablePaste();
    abstract void disablePaste();

    bool hasMouse()
    {
        return ti.caps.mouse != "";
    }

    int colors()
    {
        return ti.caps.colors;
    }

    /**
     * Show content on the screen, doing so efficiently.
     */
    abstract void show();

    /**
     * Update the screen, writing every cell.  This should be done
     * to repair screen damage, for example.
     */
    abstract void sync();

    /**
     * Emit a beep or bell.
     */
    abstract void beep();

    /**
     * Attempt to resize the terminal.  YMMV.
     */
    abstract void setSize(int rows, int cols);

private:
    Terminfo ti;
    CellBuffer cells;
    Tty tty;
    bool clear_; // if a sceren clear is requested
    Coord pos_; // location where we will update next
    Coord cursor_; // where the cursor should be
    Style style_; // current style

    // puts emits a parameterized string that may contain embedded delay padding.
    // it should not be used for user-supplied strings.
    void puts(string s)
    {
        ti.tPuts(s, tty.file());
    }

    void sendColors(Style style) // does not send URL
    {
        auto fg = style.fg;
        auto bg = style.bg;

        if (fg == Color.reset || bg == Color.reset)
        {
            puts(ti.caps.resetColors);
        }
        if (ti.caps.truecolor)
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
        if (!cells.isLegal(cursor_))
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
        goTo(cursor_);
        puts(ti.caps.showCursor);
        // TODO: cursor style

        // update our location
        pos_ = cursor_;
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
}
