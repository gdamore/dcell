// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.cell;

import std.algorithm;
import dcell.coord;
import dcell.style;

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
    int width; /// display width in cells
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

    private int index(Coord pos)
    {
        return (pos.y * size_.x + pos.x);
    }

    bool isLegal(Coord pos)
    {
        return ((pos.x >= 0) && (pos.y >= 0) && (pos.x < size_.x) && (pos.y < size_.y));
    }

    this(const int cols, const int rows)
    {
        this(Coord(cols, rows));
    }

    this(Coord size)
    {
        size_ = size;
        cells = new Cell[size.x * size.y];
        prev = new Cell[size.x * size.y];
        for (int i = 0; i < cells.length; i++)
        {
            cells[i].width = 1;
            cells[i].text = " ";
        }
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
    bool dirty(Coord pos)
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
    void setDirty(Coord pos, bool b)
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
    void setAllDirty(bool b)
    {
        // structured this way for efficiency
        if (b)
        {
            for (int i = 0; i < prev.length; i++)
            {
                prev[i].text = "";
            }
        }
        else
        {
            for (int i = 0; i < prev.length; i++)
            {
                prev[i] = cells[i];
            }
        }
    }

    const(Cell) opIndex(Coord pos)
    {
        if (isLegal(pos))
        {
            return cells[index(pos)];
        }
        return Cell();
    }

    const(Cell) opIndex(int x, int y)
    {
        return this[(Coord(x, y))];
    }

    /**
     * Set content for the cell.  
     *
     * Params:
     *   c = content to store for the cell.
     *   pos = coordinate of the cell
     */
    void opIndexAssign(Cell c, Coord pos)
    {
        if (c.text == "" || c.text[0] < ' ')
        {
            c.text = " ";
        }
        // TODO: East Asian Width
        c.width = 1;

        if (isLegal(pos))
        {
            auto ix = index(pos);

            cells[index(pos)] = c;
        }
    }

    /**
     * Set content for the cell, preserving existing styling.
     *
     * Params:
     *   s = text (character) to display.  Note that only a single
     *       character (including combining marks) is written.
     *   pos = coordinate to update.
     */
    void opIndexAssign(string s, Coord pos)
    {
        if (s == "" || s[0] < ' ')
        {
            s = " ";
        }
        // TODO: East Asian Width
        if (isLegal(pos))
        {
            auto ix = index(pos);
            cells[ix].text = s;
            cells[ix].width = 1;
        }
    }

    void opIndexAssign(Style style, Coord pos)
    {
        if (isLegal(pos))
        {
            cells[index(pos)].style = style;
        }
    }

    void opIndexAssign(Cell c, int x, int y)
    {
        this[Coord(x, y)] = c;
    }

    void opIndexAssign(string v, int x, int y)
    {
        this[Coord(x, y)] = v;
    }

    void opIndexAssign(Style v, int x, int y)
    {
        this[Coord(x, y)] = v;
    }

    void fill(Cell c)
    {
        if (c.width < 0 || c.width > 2)
        {
            // TODO: East Asian Widths.
            c.width = 1;
        }
        if (c.text == "" || c.text[0] < ' ')
        {
            c.text = " ";
        }
        for (int i = 0; i < cells.length; i++)
        {
            cells[i] = c;
        }
    }

    /**
     * Fill the entire contents, but leave any text styles undisturbed.
     */
    void fill(string s)
    {
        for (int i = 0; i < cells.length; i++)
        {
            cells[i].text = s;
            cells[i].width = 1; // TODO: East Asian Width
        }
    }

    /**
     * Fill the entires contents, including the given style.
     */
    void fill(string s, Style style)
    {
        Cell c = {text: s, style: style};
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
        for (int i = 0; i < newCells.length; i++)
        {
            // prefill with whitespace
            newCells[i].text = " ";
            newCells[i].width = 1;
        }
        // maximum dimensions to copy (minimum of dimensions)
        int lx = min(size.x, size_.x);
        int ly = min(size.y, size_.y);

        for (int y = 0; y < ly; y++)
        {
            for (int x = 0; x < lx; x++)
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

    Coord size() {
        return size_;
    }

    unittest
    {
        auto cb = new CellBuffer(80, 24);
        assert(cb.cells.length == 24 * 80);
        assert(cb.prev.length == 24 * 80);
        assert(cb.size_ == Coord(80, 24));

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

        cb[Coord(-1, 100)] = "z";
        cb[Coord(-1, 100)] = st;
        //cb.set(Coord(1, -100), "z", st);

        c = cb[Coord(1, -100)];
        assert(c.style.bg == Color.none);
        assert(c.style.fg == Color.none);
        assert(c.style.attr == Attr.none);

        cb[0, 0] = Cell("", st, 0);
        c = cb[0, 0];
        assert(c.text == " "); // space replaces null string
        assert(c.width == 1);
        assert(c.style == st);

        cb[1, 0] = Cell("\x1b", st, 0);
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

        cb[-1, 10] = c;
        c = cb[-1, 10];
        assert(c.text == "");
        assert(c.style.bg == Color.none);
        assert(c.style.fg == Color.none);
        assert(c.style.attr == Attr.none);
        assert(!cb.dirty(Coord(-1, 10)));

        cb[Coord(1, -10)] = c; // invalid
        c = cb[Coord(1, -10)];
        //assert(c.text == "");
        assert(c.style.bg == Color.none);
        assert(c.style.fg == Color.none);
        assert(c.style.attr == Attr.none);
        assert(!cb.dirty(Coord(1, -10)));

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

        c.width = -1;
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
    }
}
