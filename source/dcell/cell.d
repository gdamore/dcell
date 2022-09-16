/**
 * Cell module for dcell.
 *
 * Copyright: Copyright 2022 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.cell;

import std.algorithm;
import std.traits;
import std.utf;

public import dcell.coord;
public import dcell.style;

/** 
 * Cell represents the contents of a single character cell on screen,
 * or in some cases two adjacent cells.  Terminals are expected to have a uniform 
 * display width for each cell, and to have a fixed number of cell columsn and rows.
 * (We assume fixed pitch fonts.)  The occasion when a double wide character is present
 * occurs for certain East Asian characters that require twice as much horizontal space
 * to display as others.  (This can also occur with some emoji.)
 */
struct Cell
{
    string text; /// character content - one character followed by any combinging characters
    Style style; /// styling for the cell

    this(C)(C c, Style st = Style()) if (isSomeChar!C)
    {
        text = toUTF8([c]);
        style = st;
    }

    this(S)(S s, Style st = Style()) if (isSomeString!S)
    {
        text = toUTF8(s);
        style = st;
    }

    @property uint width() pure const {
        // TODO: east asian width
        return 1;
    }
}

/**
 * CellBuffer is a logical grid of cells containing content to display on screen.
 * It uses double buffering which can be used to reduce redrawing content on screen,
 * which can have a very noticeable impact on performance and responsiveness.
 *
 * It behaves something like a two-dimensional array, but offers some conveniences.
 * Values returned from the indexing are constant, but new values can be assigned.
 */
class CellBuffer
{
    private Coord size_;
    private Cell[] cells; // current content - linear for performance
    private Cell[] prev; // previous content - linear for performance

    private size_t index(Coord pos) nothrow pure const
    {
        return index(pos.x, pos.y);
    }

    private size_t index(size_t x, size_t y) nothrow pure const
    {
        assert(size_.x > 0);
        return (y * size_.x + x);
    }

    bool isLegal(Coord pos) nothrow pure const
    {
        return ((pos.x >= 0) && (pos.y >= 0) && (pos.x < size_.x) && (pos.y < size_.y));
    }

    this(const size_t cols, const size_t rows)
    {
        assert((cols >= 0) && (rows >= 0) && (cols < int.max) && (rows < int.max));
        cells = new Cell[cols * rows];
        prev = new Cell[cols * rows];
        size_.x = cast(int) cols;
        size_.y = cast(int) rows;

        foreach (i; 0 .. cells.length)
        {
            cells[i].text = " ";
        }
    }

    this(Coord size)
    {
        this(size.x, size.y);
    }

    /**
     * Is a cell dirty?  Dirty means that the cell has some content
     * or style change that has not been written to the terminal yet.
     * Writes of identical content to what was last displayed do not
     * cause a cell to become dirty -- only *different* content does.
     *
     * Params:
     *   pos = coordinates of cell to check
     */
    bool dirty(Coord pos) pure const
    {
        if (isLegal(pos))
        {
            auto ix = index(pos);
            if (prev[ix].text == "")
            {
                return true;
            }
            return cells[ix] != prev[ix];
        }
        return false;
    }

    /**
     * Mark a cell as either dirty or clean.
     *
     * Params:
     *   pos = coordinate of sell to update
     *   b = mark all dirty if true, or clean if false
     */
    void setDirty(Coord pos, bool b) pure
    {
        if (isLegal(pos))
        {
            auto ix = index(pos);
            if (b)
            {
                prev[ix].text = "";
            }
            else
            {
                prev[ix] = cells[ix];
            }
        }
    }

    /**
     * Mark all cells as either dirty or clean.
     *
     * Params:
     *   b = mark all dirty if true, or clean if false
     */
    void setAllDirty(bool b) pure
    {
        // structured this way for efficiency
        if (b)
        {
            foreach (i; 0 .. prev.length)
            {
                prev[i].text = "";
            }
        }
        else
        {
            foreach (i; 0 .. prev.length)
            {
                prev[i] = cells[i];
            }
        }
    }

    ref Cell opIndex(Coord pos)
    {
        return this[pos.x, pos.y];
    }

    ref Cell opIndex(size_t x, size_t y)
    {
        return cells[index(x, y)];
    }

    Cell get(Coord pos) nothrow pure
    {
        if (isLegal(pos))
        {
            return cells[index(pos)];
        }
        return Cell();
    }

    /**
     * Set content for the cell.  
     *
     * Params:
     *   c = content to store for the cell.
     *   pos = coordinate of the cell
     */
    void opIndexAssign(Cell c, size_t x, size_t y) pure
    {
        if ((x < size_.x) && (y < size_.y))
        {
            if (c.text == "" || c.text[0] < ' ')
            {
                c.text = " ";
            }
            cells[index(x, y)] = c;
        }
    }

    void opIndexAssign(Cell c, Coord pos) pure
    {
        this[pos.x, pos.y] = c;
    }

    /**
     * Set content for the cell, preserving existing styling.
     *
     * Params:
     *   s = text (character) to display.  Note that only a single
     *       character (including combining marks) is written.
     *   pos = coordinate to update.
     */
    void opIndexAssign(string s, Coord pos) pure
    {
        if (s == "" || s[0] < ' ')
        {
            s = " ";
        }
        if (isLegal(pos))
        {
            auto ix = index(pos);
            cells[ix].text = s;
        }
    }

    void opIndexAssign(Style style, Coord pos) pure
    {
        if (isLegal(pos))
        {
            cells[index(pos)].style = style;
        }
    }

    void opIndexAssign(string s, size_t x, size_t y) pure
    {
        if (s == "" || s[0] < ' ')
        {
            s = " ";
        }

        cells[index(x, y)].text = s;
    }

    void opIndexAssign(Style v, size_t x, size_t y) pure
    {
        cells[index(x, y)].style = v;
    }

    int opDollar(size_t dim)()
    {
        if (dim == 0)
        {
            return size_.x;
        }
        else
        {
            return size_.y;
        }
    }

    void fill(Cell c) pure
    {
        if (c.text == "" || c.text[0] < ' ')
        {
            c.text = " ";
        }
        foreach (i; 0 .. cells.length)
        {
            cells[i] = c;
        }
    }

    /**
     * Fill the entire contents, but leave any text styles undisturbed.
     */
    void fill(string s) pure
    {
        foreach (i; 0 .. cells.length)
        {
            cells[i].text = s;
        }
    }

    /**
     * Fill the entires contents, including the given style.
     */
    void fill(string s, Style style) pure
    {
        Cell c = Cell(s, style);
        fill(c);
    }

    /**
     * Resize the cell buffer.  Existing contents will be preserved,
     * provided that they still fit.  Contents that no longer fit will
     * be clipped (lost).  Newly added cells will be initialized to empty
     * content.  The entire set of contents are marked dirty, because
     * presumably everything needs to be redrawn when this happens.
     */
    void resize(Coord size)
    {
        if (size_ == size)
        {
            return;
        }
        auto newCells = new Cell[size.x * size.y];
        foreach (i; 0 .. newCells.length)
        {
            // prefill with whitespace
            newCells[i].text = " ";
        }
        // maximum dimensions to copy (minimum of dimensions)
        int lx = min(size.x, size_.x);
        int ly = min(size.y, size_.y);

        foreach (y; 0 .. ly)
        {
            foreach (x; 0 .. lx)
            {
                newCells[y * size.x + x] = cells[y * size_.x + x];
            }
        }
        size_ = size;
        cells = newCells;
        prev = new Cell[size.x * size.y];
    }

    void resize(int cols, int rows)
    {
        resize(Coord(cols, rows));
    }

    Coord size() const pure nothrow
    {
        return size_;
    }

    unittest
    {
        auto cb = new CellBuffer(80, 24);
        assert(cb.cells.length == 24 * 80);
        assert(cb.prev.length == 24 * 80);
        assert(cb.size_ == Coord(80, 24));

        assert(Cell('A').text == "A");

        cb[Coord(2, 5)] = "b";
        assert(cb[2, 5].text == "b");
        Cell c = cb[2, 5];
        Style st;
        assert(c.width == 1);
        assert(c.text == "b");
        assert(c.style == st);
        assert(cb.cells[5 * cb.size_.x + 2].text == "b");

        st.bg = Color.white;
        st.fg = Color.blue;
        st.attr = Attr.reverse;
        cb[3, 5] = "z";
        cb[3, 5] = st;

        c = cb[Coord(3, 5)];
        assert(c.style.bg == Color.white);
        assert(c.style.fg == Color.blue);
        assert(c.style.attr == Attr.reverse);

        cb[0, 0] = Cell("", st);
        c = cb[0, 0];
        assert(c.text == " "); // space replaces null string
        assert(c.width == 1);
        assert(c.style == st);

        cb[1, 0] = Cell("\x1b", st);
        c = cb[1, 0];
        assert(c.text == " "); // space replaces control sequence
        assert(c.width == 1);
        assert(c.style == st);

        cb[1, 1] = "\x1b";
        c = cb[1, 1];
        assert(c.text == " "); // space replaces control sequence
        assert(c.width == 1);

        c.text = "@";
        cb[2, 0] = c;
        c = cb[2, 0];
        assert(c.text == "@");
        assert(cb.dirty(Coord(2, 0)));

        st.attr = Attr.reverse;
        st.bg = Color.none;
        st.fg = Color.maroon;
        cb.fill("%", st);
        assert(cb[1, 1].text == "%");
        assert(cb[1, 1].style == st);
        cb.fill("s");

        cb.setAllDirty(false);

        cb[1, 1] = "U";
        cb[1, 1] = st;
        assert(cb[1, 1].style == st);
        assert(cb[1, 1].text == "U");
        assert(cb.dirty(Coord(1, 1)));
        assert(!cb.dirty(Coord(2, 1)));

        assert(cb.prev[0] == cb.cells[0]);

        cb.setDirty(Coord(2, 1), true);
        assert(cb.dirty(Coord(2, 1)));
        assert(!cb.dirty(Coord(3, 1)));

        cb.setDirty(Coord(3, 1), false);
        assert(!cb.dirty(Coord(3, 1)));
        cb.setAllDirty(true);
        assert(cb.dirty(Coord(3, 1)));

        c.text = "A";
        cb.fill(c);
        assert(cb[0, 0].width == 1);
        assert(cb[0, 0].text == "A");
        assert(cb[1, 23].text == "A");
        assert(cb[79, 23].text == "A");
        cb.resize(132, 50);
        assert(cb.size() == Coord(132, 50));
        assert(cb[79, 23].text == "A");
        assert(cb[80, 23].text == " ");
        assert(cb[79, 24].text == " ");
        cb.resize(132, 50); // this should be a no-op
        assert(cb.size() == Coord(132, 50));
        assert(cb[79, 23].text == "A");
        assert(cb[80, 23].text == " ");
        assert(cb[79, 24].text == " ");

        c.text = "";
        cb.fill(c);
        assert(cb[79, 23].text == " ");

        // opDollar
        assert(cb.size() == Coord(132, 50));
        cb[0, 0].text = "A";
        cb[$ - 1, 0].text = "B";
        cb[0, $ - 1].text = "C";
        cb[$ - 1, $ - 1].text = "D";
        assert(cb[0, 0].text == "A");
        assert(cb[131, 0].text == "B");
        assert(cb[0, 49].text == "C");
        assert(cb[131, 49].text == "D");
    }
}
