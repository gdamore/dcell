/**
 * Cell module for dcell.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.cell;

import std.algorithm;
import std.exception;
import std.traits;
import std.uni;
import std.utf;

import eastasianwidth;

public import dcell.coord;
public import dcell.style;

/**
 * Cell represents the contents of a single character cell on screen,
 * or in some cases two adjacent cells.  Terminals are expected to have a uniform
 * display width for each cell, and to have a fixed number of cell columns and rows.
 * (We assume fixed pitch fonts.)  The occasion when a double wide character is present
 * occurs for certain East Asian characters that require twice as much horizontal space
 * to display as others.  (This can also occur with some emoji.)
 */
struct Cell
{
    // The order of these is chosen to minimize space per cell.
    Style style; /// styling for the cell

    this(C)(C c, Style st = Style()) if (isSomeChar!C)
    {
        ss = toUTF8([c]);
        dw = calcWidth();
        style = st;
    }

    this(S)(S s, Style st = Style()) if (isSomeString!S)
    {
        ss = toUTF8(s);
        dw = calcWidth();
        style = st;
    }

    @property const(string) text() nothrow pure @safe const
    {
        return ss;
    }

    @property const(string) text(const(string) s) pure @safe
    {
        ss = toUTF8(s);
        dw = calcWidth();
        return s;
    }

    /**
     * The display width of the contents of the cell, which will be 1 (typical western
     * characters, as well as ambiguous characters), 2 (typical CJK characters), or in
     * some cases 0 (empty content, control characters, zero-width whitespace).
     * Note that cells immediately following a cell with a wide character will themselves
     * generally have no content (as their screen display real-estate is consumed by the
     * wide character.)
     *
     * This relies on the accuracy of the content in the imported east_asian_width
     * package and the terminal/font combination (and for some characters it may even
     * be sensitive to which Unicode edition is being supported). Therefore the results
     * may not be perfectly correct for a given platform or font or context.
     */
    @property ubyte width() const nothrow pure @safe
    {
        return dw;
    }

private:

    string ss;
    ubyte dw; // display width

    ubyte calcWidth() pure const @safe
    {
        enum regionA = '\U0001F1E6';
        enum regionZ = '\U0001F1FF';

        if (ss.length < 1 || ss[0] < ' ' || ss[0] == '\x7F') // empty or control characters
        {
            return (0);
        }
        if (ss[0] < '\x80') // covers ASCII
        {
            return 1;
        }
        auto d = toUTF32(ss);
        // flags - missing from east asian width decoding
        if ((d.length >= 2) && (d[0] >= regionA && d[0] <= regionZ && d[1] >= regionA && d[1] <= regionZ))
        {
            return 2;
        }
        assert(d.length > 0);
        if (d[0] < '\u02b0')
        {
            return 1; // covers latin supplements, IPA
        }
        auto w = displayWidth(d[0]);
        if (w < 0)
        {
            return 0;
        }
        if (w > 2)
        {
            return 2;
        }
        return cast(ubyte) w;
    }
}

unittest
{
    assert(Cell('\t').width == 0);
    assert(Cell('\x7F').width == 0);
    assert(Cell("").width == 0);
    assert(Cell('A').width == 1); // ASCII
    assert(Cell("B").width == 1); // ASCII (string)
    assert(Cell('ￂ').width == 1); // half-width form
    assert(Cell('￥').width == 2); // full-width yen
    assert(Cell('Ｚ').width == 2); // full-width Z
    assert(Cell('角').width == 2); // a CJK character
    assert(Cell('😂').width == 2); // emoji
    assert(Cell('♀').width == 1); // modifier alone
    assert(Cell("\U0001F44D").width == 2); // thumbs up
    assert(Cell("\U0001f1fa\U0001f1f8").width == 2); // US flag (regional indicators)
    assert(Cell("\U0001f9db\u200d\u2640").width == 2); // female vampire
    assert(Cell("🤝 🏽").width == 2); // modified emoji (medium skin tone handshake)
    assert(Cell("\U0001F44D\U0001F3fD").width == 2); // thumbs up, medium skin tone
    assert(Cell("🧛‍♀️").width == 2); // modified emoji

    // The following are broken due to bugs in std.uni and/or the east asian width.
    // At some point it may be easier to refactor this ourself.
    // assert(Cell('\u200d').width == 0); // Zero Width Joiner
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

    private size_t index(Coord pos) nothrow pure const @safe @nogc
    {
        return index(pos.x, pos.y);
    }

    private size_t index(size_t x, size_t y) nothrow pure const @safe @nogc
    {
        assert(size_.x > 0);
        return (y * size_.x + x);
    }

    package bool isLegal(Coord pos) nothrow pure const @safe @nogc
    {
        return ((pos.x >= 0) && (pos.y >= 0) && (pos.x < size_.x) && (pos.y < size_.y));
    }

    this(const size_t cols, const size_t rows) @safe
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

    this(Coord size) @safe
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
    bool dirty(Coord pos) nothrow pure const @safe
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
    void setDirty(Coord pos, bool b) pure @safe
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
    void setAllDirty(bool b) pure @safe
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

    ref Cell opIndex(Coord pos) nothrow @safe
    {
        return this[pos.x, pos.y];
    }

    ref Cell opIndex(size_t x, size_t y) nothrow @safe
    {
        return cells[index(x, y)];
    }

    Cell get(Coord pos) nothrow pure @safe
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
    void opIndexAssign(Cell c, size_t x, size_t y) pure @safe
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

    void opIndexAssign(Cell c, Coord pos) pure @safe
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
    void opIndexAssign(string s, Coord pos) pure @safe
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

    void opIndexAssign(Style style, Coord pos) nothrow pure @safe
    {
        if (isLegal(pos))
        {
            cells[index(pos)].style = style;
        }
    }

    void opIndexAssign(string s, size_t x, size_t y) pure @safe
    {
        if (s == "" || s[0] < ' ')
        {
            s = " ";
        }

        cells[index(x, y)].text = s;
    }

    void opIndexAssign(Style v, size_t x, size_t y) nothrow pure @safe
    {
        cells[index(x, y)].style = v;
    }

    int opDollar(size_t dim)() nothrow pure @safe
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

    void fill(Cell c) pure @safe
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
    void fill(string s) pure @safe
    {
        foreach (i; 0 .. cells.length)
        {
            cells[i].text = s;
        }
    }

    /**
     * Fill the entire contents, including the given style.
     */
    void fill(string s, Style style) pure @safe
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
    void resize(Coord size) @safe
    {
        if (size_ == size)
        {
            return;
        }
        auto newCells = new Cell[size.x * size.y];
        foreach (i; 0 .. newCells.length)
        {
            // pre-fill with whitespace
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

    void resize(int cols, int rows) @safe
    {
        resize(Coord(cols, rows));
    }

    Coord size() const pure nothrow @safe
    {
        return size_;
    }

    // This is the default style we use when writing content using
    // put and similar APIs.
    Style style;

    // This is the current position that will be writing when when using
    // put or write.
    Coord position;

    void put(Grapheme g) @safe
    {
        if (isLegal(position))
        {
            auto ix = index(position);
            string str = toUTF8(g[]);
            cells[ix].text = str;
            cells[ix].style = style;
            auto w = cells[ix].width;
            final switch (w)
            {
            case 0:
                break;
            case 1:
                position.x++;
                if (position.x >= size_.x)
                {
                    // auto wrap
                    position.y++;
                    position.x = 0;
                }
                break;
            case 2:
                position.x++;
                if (isLegal(position))
                {
                    cells[index(position)].text = "";
                }
                position.x++;
                if (position.x >= size_.x)
                {
                    position.y++;
                    position.x = 0;
                }
            }
        }
    }

    // Put uses a range put, and can thus support a formatted writer, but
    // note that this WILL NOT WORK with grapheme clusters, because the formatted
    // writer does not know about unicode segmentation.  Use write() and create
    // a string elsewhere if you need to work with grapheme clusters.  Single code
    // point use cases (i.e. most simple text, or precomposed scripts) will work fine.
    void put(Char)(Char c) @safe if (isSomeChar!Char)
    {
        put(Grapheme(c));
    }

    // Write a string at the current `position`, using the current `style`.
    // This will wrap if it reaches the end of the terminal.
    void write(Str)(Str s) @safe if (isSomeString!Str)
    {
        foreach (g; s.byGrapheme)
        {
            put(g);
        }
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
        st.bg = Color.invalid;
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

unittest
{
    auto cb = new CellBuffer(80, 24);
    cb.put('1');
    cb.position = Coord(5, 10);
    cb.style.attr = Attr.bold;
    cb.put('2');

    assert(cb[0, 0].text == "1");
    assert(cb[5, 10].text == "2");
    assert(cb[5, 10].style.attr == Attr.bold);

    cb.position = Coord(76, 1);
    cb.write("this wraps");
    assert(cb[76, 1].text == "t");
    assert(cb[77, 1].text == "h");
    assert(cb[78, 1].text == "i");
    assert(cb[79, 1].text == "s");
    assert(cb[0, 2].text == " ");
    assert(cb[1, 2].text == "w");
    assert(cb[2, 2].text == "r");
    assert(cb[3, 2].text == "a");
    assert(cb[4, 2].text == "p");
    assert(cb[5, 2].text == "s");

    cb.position = Coord(0, 3);
    cb.write("￥ yen sign");
    assert(cb[0, 3].text == "￥");
    assert(cb[0, 3].width == 2);
    assert(cb[1, 3].text == "");
    assert(cb[1, 3].width == 0);
    assert(cb[2, 3].text == " ");
    assert(cb[2, 3].width == 1);
    assert(cb[3, 3].text == "y");
    assert(cb[4, 3].text == "e");
    assert(cb[5, 3].text == "n");
}
