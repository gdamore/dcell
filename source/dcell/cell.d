// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.cell;

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
 */
class CellBuffer
{
    int w; /// width
    int h; /// height
    Cell[] cells; /// current content - linear for performance
    Cell[] prev; /// previous content - linear for performance

    private int index(int x, int y)
    {
        return (y * w + x);
    }

    this(const int cols, const int rows)
    {
        w = cols;
        h = rows;
        cells = new Cell[w * h];
        prev = new Cell[w * h];
        for (int i = 0; i < cells.length; i++)
        {
            cells[i].width = 1;
            cells[i].text = " ";
        }
    }

    /**
     * Set content for the cell.
     *
     * Params:
     *   x = column (0 is left most)
     *   y = row (0 is top)
     *   s = text (character) to display.  Note that only a single
     *       character (including combining marks) is written.
     *   st = style to apply
     *   width = should be 1 for normal width, 2 for full width
     *           or -1 to calculate from the text.
     */
    void set(int x, int y, string s, Style st, int width = -1)
    {
        Cell c = {text: s, style: st, width: width};
        set(x, y, c);
    }

    /**
     * Set content for the cell, preserving existing styling.
     *
     * Params:
     *   x = column (0 is left most)
     *   y = row (0 is top)
     *   s = text (character) to display.  Note that only a single
     *       character (including combining marks) is written.
     */
    void set(int x, int y, string s)
    {
        if ((x >= 0) && (x < w) && (y >= 0) && (y < h))
        {
            if (s == "" || s[0] < ' ')
            {
                // no control sequences or empty strings
                s = " ";
            }
            // TODO: We need to calculate the width using East Asian Width
            auto index = index(x, y);
            cells[index].text = s;
            cells[index].width = 1;
        }
    }

    /**
     * Set only the style for a given location.
     * This does not change change the textual content.
     */
    void set(int x, int y, Style st)
    {
        if ((x >= 0) && (x < w) && (y >= 0) && (y < h))
        {
            cells[index(x, y)].style = st;
        }
    }

    /**
     * Set content for the cell.  
     *
     * Params:
     *   x = column (0 is left most)
     *   y = row (0 is top)
     *   c = content to store for the cell.
     */
    void set(int x, int y, Cell c)
    {
        if ((x >= 0) && (x < w) && (y >= 0) && (y < h))
        {
            if (c.text == "" || c.text[0] < ' ')
            {
                // no control sequences or empty strings
                c.text = " ";
            }
            if (c.width < 0 || c.width > 2)
            {
                // TODO: determine based on East Asian Width
                c.width = 1;
            }
            cells[index(x, y)] = c;
        }
    }

    /**
     * Is a cell dirty?  Dirty means that the cell has some content
     * or style change that has not been written to the terminal yet.
     * Writes of identical content to what was last displayed do not
     * cause a cell to become dirty -- only *different* content does.
     *
     * Params:
     *   x = column (0 is left most)
     *   y = row (0 is top)
     *   b = mark all dirty if true, or clean if false
     */
    bool dirty(int x, int y)
    {
        if ((x >= 0) && (x < w) && (y >= 0) && (y < h))
        {
            auto index = index(x, y);
            if (prev[index].text == "")
            {
                return true;
            }
            return (cells[index] != prev[index]);
        }
        return false;
    }

    /**
     * Mark a cell as either dirty or clean.
     *
     * Params:
     *   x = column (0 is left most)
     *   y = row (0 is top)
     *   b = mark all dirty if true, or clean if false
     */
    void setDirty(int x, int y, bool b)
    {
        if ((x >= 0) && (x < w) && (y >= 0) && (y < h))
        {
            auto index = y * w + x;
            if (b)
            {
                prev[index].text = "";
            }
            else
            {
                prev[index] = cells[index];
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

    Cell get(int x, int y)
    {
        if ((x >= 0) && (x < w) && (y >= 0) && (y < h))
        {
            return cells[index(x, y)];
        }
        Cell c;
        return c;
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
    void resize(int cols, int rows)
    {
        if (w == cols && h == rows)
        {
            return;
        }
        auto newCells = new Cell[cols * rows];
        for (int i = 0; i < newCells.length; i++)
        {
            // prefill with whitespace
            newCells[i].text = " ";
            newCells[i].width = 1;
        }
        // maximum dimensions to copy (minimum of dimensions)
        int lx = cols < w ? cols : w;
        int ly = rows < h ? rows : h;

        for (int y = 0; y < ly; y++)
        {
            for (int x = 0; x < lx; x++)
            {
                newCells[y * cols + x] = cells[y * h + x];
            }
        }
        h = rows;
        w = cols;
        cells = newCells;
        prev = new Cell[cols * rows];
    }

    unittest
    {
        auto cb = new CellBuffer(80, 24);
        assert(cb.cells.length == 24 * 80);
        assert(cb.prev.length == 24 * 80);
        assert(cb.w == 80);
        assert(cb.h == 24);

        cb.set(2, 5, "b");
        auto c = cb.get(2, 5);
        Style st;
        assert(c.width == 1);
        assert(c.text == "b");
        assert(c.style == st);
        assert(cb.cells[5 * cb.w + 2].text == "b");

        st.bg = Color.white;
        st.fg = Color.blue;
        st.attr = Attr.reverse;
        cb.set(3, 5, "z", st);

        c = cb.get(3, 5);
        assert(c.style.bg == Color.white);
        assert(c.style.fg == Color.blue);
        assert(c.style.attr == Attr.reverse);

        cb.set(-1, 100, "z", st);
        cb.set(1, -100, "z", st);

        c = cb.get(1, -100);
        assert(c.style.bg == Color.none);
        assert(c.style.fg == Color.none);
        assert(c.style.attr == Attr.none);

        cb.set(0, 0, "", st);
        c = cb.get(0, 0);
        assert(c.text == " "); // space replaces null string
        assert(c.width == 1);
        assert(c.style == st);

        cb.set(1, 0, "\x1b", st);
        c = cb.get(1, 0);
        assert(c.text == " "); // space replaces control sequence
        assert(c.width == 1);
        assert(c.style == st);

        cb.set(1, 1, "\x1b");
        c = cb.get(1, 1);
        assert(c.text == " "); // space replaces control sequence
        assert(c.width == 1);

        c.text = "@";
        cb.set(2, 0, c);
        c = cb.get(2, 0);
        assert(c.text == "@");
        assert(cb.dirty(2, 0));

        cb.set(-1, 10, c);
        c = cb.get(-1, 10);
        assert(c.text == "");
        assert(c.style.bg == Color.none);
        assert(c.style.fg == Color.none);
        assert(c.style.attr == Attr.none);
        assert(!cb.dirty(-1, 10));

        cb.set(1, -10, c);
        c = cb.get(1, -10);
        assert(c.text == "");
        assert(c.style.bg == Color.none);
        assert(c.style.fg == Color.none);
        assert(c.style.attr == Attr.none);
        assert(!cb.dirty(1, -10));

        st.attr = Attr.reverse;
        st.bg = Color.none;
        st.fg = Color.maroon;
        cb.fill("%", st);
        assert(cb.get(1, 1).text == "%");
        assert(cb.get(1, 1).style == st);
        cb.fill("s");

        cb.setAllDirty(false);

        cb.set(1, 1, "U");
        cb.set(1, 1, st);
        assert(cb.get(1, 1).style == st);
        assert(cb.get(1, 1).text == "U");
        assert(cb.dirty(1, 1));
        assert(!cb.dirty(2, 1));

        assert(cb.prev[0] == cb.cells[0]);

        cb.setDirty(2, 1, true);
        assert(cb.dirty(2, 1));
        assert(!cb.dirty(3, 1));

        cb.setDirty(3, 1, false);
        assert(!cb.dirty(3, 1));
        cb.setAllDirty(true);
        assert(cb.dirty(3, 1));

        c.width = -1;
        c.text = "A";
        cb.fill(c);
        assert(cb.get(0, 0).width == 1);
        assert(cb.get(0, 0).text == "A");
        assert(cb.get(1, 23).text == "A");
        assert(cb.get(79, 23).text == "A");
        cb.resize(132, 50);
        assert(cb.w == 132);
        assert(cb.h == 50);
        assert(cb.get(79, 23).text == "A");
        assert(cb.get(80, 23).text == " ");
        assert(cb.get(79, 24).text == " ");
        cb.resize(132, 50); // this should be a no-op
        assert(cb.w == 132);
        assert(cb.h == 50);
        assert(cb.get(79, 23).text == "A");
        assert(cb.get(80, 23).text == " ");
        assert(cb.get(79, 24).text == " ");

        c.text = "";
        cb.fill(c);
        assert(cb.get(79, 23).text == " ");
    }
}
