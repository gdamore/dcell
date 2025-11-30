/**
 * Screen module for dcell provides the common interface for different implementations of KVM type devices.
 *
 * Copyright: Copyright 2022 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.screen;

import core.time;
import std.concurrency;

public import dcell.cell;
public import dcell.cursor;
public import dcell.key;
public import dcell.event;
public import dcell.mouse;

/**
 * Screen is implemented by different platforms to provide a common interface for building
 * text best full-screen user interfaces.
 */
interface Screen
{
    /**
     * Clears the screen.  This doesn't take effect until
     * the show function is called.
     */
    void clear();

    /**
     * Retrieve the contents for a given address.  This is taken from
     * the backing draw buffer, and won't necessarily reflect what is
     * displayed to the user until show is called.
     */
    ref Cell opIndex(size_t x, size_t y);

    /** Convenience for indexing */
    final ref Cell opIndex(Coord pos)
    {
        return this[pos.x, pos.y];
    }

    /**
     * Set the content for for a given location.  This won't necessarily
     * take effect until the show function is called.
     */
    void opIndexAssign(Cell, size_t x, size_t y);


    /** Convenience for indexing. */
    final void opIndexAssign(Cell c, Coord pos)
    {
        this[pos.x, pos.y] = c;
    }

    /**
     * Set content for the cell, preserving existing styling.
     *
     * Params:
     *   s = text (character) to display. Note that only a single character
     *       (including combining marks) is written. If empty or a control
     *       character, a single space is used instead.
     *   x = X coordinate (column)
     *   y = Y coordinate (row)
     */
    final void opIndexAssign(string s, size_t x, size_t y)
    {
        if (s == "" || s[0] < ' ')
        {
            s = " ";
        }
        this[x, y].text = s; // preserve existing style
    }

    /** Convenience variant for Coord. */
    final void opIndexAssign(string s, Coord pos)
    {
        this[pos.x, pos.y] = s; // delegate to (x, y) overload
    }

    /**
     * Set style for the cell, preserving existing text/content.
     *
     * Params:
     *   v = style to apply to the cell
     *   x = X coordinate (column)
     *   y = Y coordinate (row)
     */
    final void opIndexAssign(Style v, size_t x, size_t y)
    {
        this[x, y].style = v; // preserve existing text
    }

    /** Convenience variant for Coord. */
    final void opIndexAssign(Style v, Coord pos)
    {
        this[pos.x, pos.y] = v; // delegate to (x, y) overload
    }

    /**
     * Write a multi-character string horizontally starting at the given
     * location, truncating at the end of the row. Existing cell styles are
     * preserved; only text content is changed.
     *
     * Params:
     *   x = X coordinate (column) to start writing at
     *   y = Y coordinate (row) to start writing at
     *   s = string to write; each Unicode scalar value maps to a single cell
     *       (combining marks are not clustered; behavior mirrors CellBuffer)
     */
    final void write(size_t x, size_t y, string s)
    {
        auto sz = size();
        if (y >= cast(size_t) sz.y) return;
        if (x >= cast(size_t) sz.x) return;
        if (s.length == 0) return;

        import std.utf : decode;
        size_t i = 0;
        while (i < s.length && x < cast(size_t) sz.x)
        {
            auto start = i;
            decode(s, i); // advances i to next code point start
            auto unit = s[start .. i];
            if (unit.length == 0 || unit[0] < ' ')
            {
                unit = " ";
            }
            this[x, y] = unit; // preserves style
            ++x;
        }
    }

    /** Convenience overload using Coord. */
    final void write(Coord pos, string s)
    {
        write(cast(size_t) pos.x, cast(size_t) pos.y, s);
    }

    /**
     * Write a multi-character string starting at the given location, wrapping
     * to the next row when the end of the current row is reached. Writing
     * stops at the bottom of the screen. Existing cell styles are preserved.
     *
     * Params:
     *   x = X coordinate (column) to start writing at
     *   y = Y coordinate (row) to start writing at
     *   s = string to write; each Unicode scalar value maps to a single cell
     */
    final void writeWrap(size_t x, size_t y, string s)
    {
        auto sz = size();
        if (y >= cast(size_t) sz.y) return;
        if (x >= cast(size_t) sz.x && (y + 1) >= cast(size_t) sz.y) return;
        if (s.length == 0) return;

        import std.utf : decode;
        size_t i = 0;
        while (i < s.length && y < cast(size_t) sz.y)
        {
            if (x >= cast(size_t) sz.x)
            {
                x = 0;
                ++y;
                if (y >= cast(size_t) sz.y) break;
            }
            auto start = i;
            decode(s, i);
            auto unit = s[start .. i];
            if (unit.length == 0 || unit[0] < ' ')
            {
                unit = " ";
            }
            this[x, y] = unit;
            ++x;
        }
    }

    /** Convenience overload using Coord for wrapping write. */
    final void writeWrap(Coord pos, string s)
    {
        writeWrap(cast(size_t) pos.x, cast(size_t) pos.y, s);
    }

    /**
     * Write a string with a uniform style applied to each written cell,
     * truncating at the end of the row.
     *
     * Params:
     *   x = X coordinate (column)
     *   y = Y coordinate (row)
     *   s = string to write
     *   st = style to apply to each written cell
     */
    final void write(size_t x, size_t y, string s, Style st)
    {
        auto sz = size();
        if (y >= cast(size_t) sz.y) return;
        if (x >= cast(size_t) sz.x) return;
        if (s.length == 0) return;

        import std.utf : decode;
        size_t i = 0;
        while (i < s.length && x < cast(size_t) sz.x)
        {
            auto start = i;
            decode(s, i);
            auto unit = s[start .. i];
            if (unit.length == 0 || unit[0] < ' ')
            {
                unit = " ";
            }
            this[x, y] = unit;
            this[x, y] = st;
            ++x;
        }
    }

    /** Convenience overload using Coord for styled write. */
    final void write(Coord pos, string s, Style st)
    {
        write(cast(size_t) pos.x, cast(size_t) pos.y, s, st);
    }

    /**
     * Write a string with a uniform style applied, wrapping across rows as
     * needed until either the entire string is written or the bottom of the
     * screen is reached.
     */
    final void writeWrap(size_t x, size_t y, string s, Style st)
    {
        auto sz = size();
        if (y >= cast(size_t) sz.y) return;
        if (x >= cast(size_t) sz.x && (y + 1) >= cast(size_t) sz.y) return;
        if (s.length == 0) return;

        import std.utf : decode;
        size_t i = 0;
        while (i < s.length && y < cast(size_t) sz.y)
        {
            if (x >= cast(size_t) sz.x)
            {
                x = 0;
                ++y;
                if (y >= cast(size_t) sz.y) break;
            }
            auto start = i;
            decode(s, i);
            auto unit = s[start .. i];
            if (unit.length == 0 || unit[0] < ' ')
            {
                unit = " ";
            }
            this[x, y] = unit;
            this[x, y] = st;
            ++x;
        }
    }

    /** Convenience overload using Coord for styled, wrapping write. */
    final void writeWrap(Coord pos, string s, Style st)
    {
        writeWrap(cast(size_t) pos.x, cast(size_t) pos.y, s, st);
    }

    /** Support $ operation in indices. */
    size_t opDollar(size_t dim)() {
        static if (dim == 0) {
            return size().x;
        } else {
            return size().y;
        }
    }

    /**
     * Show the cursor at its current location.
     */
    void showCursor(Cursor);

    /**
     * Move the cursor to the given location, and show
     * it using the appropriate style.
     *
     * Params:
     *  pos = position of the cursor
     *  cur = cursor style
     */
    void showCursor(Coord pos, Cursor cur = Cursor.current);

    /**
     * It would be nice to know if a given key is supported by
     * a terminal.  Note that this is best-effort, and some terminals
     * may present the ability to support a key, without actually having
     * such a physical key and some combinations may be suppressed by
     * the emulator or the environment the emulator runs in.
     *
     * Returns: true if the key appears to be supported on the terminal.
     */
    bool hasKey(Key);

    /**
     * Obtain the terminal window size.
     * The x, y represent the number of columns and rows.
     * The highest valid address will be coord.x-1, coord.y-1.
     *
     * Returns: terminal dimensions
     */
    Coord size();

    /**
     * If start was called without a Tid to send to, then events
     * are delivered into a queue that can be polled via this API.
     * This function is thread safe.
     * Params:
     *   dur = maximum time to wait, if no event is available then EventType.none is returned.
     * Returns:
     *   The event, which will be EventType.none if it times out, or EventType.closed if it is stopped.
     */
    Event receiveEvent(Duration dur);

    /**
     * Receive events, without a timeout.  This only works if start
     * was called without a tid.
     */
    Event receiveEvent();

    /**
     * Enable bracketed paste mode mode.  Bracketed paste mode
     * will pasted content in a single event, and is therefore
     * distinguishable from individually typed characters.
     *
     * Params:
     *   b = true to enable bracketed paste, false for disable
     */
    void enablePaste(bool b);

    /**
     * Do we have a mouse? This may be overly optimistic for some
     * terminals, but it is a good first guess.
     *
     * Returns: true if the terminal is thought to support mouse events
     */
    bool hasMouse();

    /**
     * Enable mouse mode.  This can cause terminals/emulators
     * to behave differently -- for example affecting the ability
     * to scroll or use copy/paste.
     *
     * Params:
     *   en = mouse events to report (mask)
     */
    void enableMouse(MouseEnable en);

    /**
     * Enable typical mouse features. This enables tracking, but
     * leaves drag events disabled.  Enabling mouse drag will impair
     * use of copy-paste at the OS level, which many users tend to
     * find frustrating.
     */
    final void enableMouse()
    {
        enableMouse(MouseEnable.buttons | MouseEnable.motion);
    }

    /**
     * Disable all mouse handling/capture.
     */
    final void disableMouse()
    {
        enableMouse(MouseEnable.disable);
    }

    /**
     * If the terminal supports color, this returns the
     * the number of colors.
     *
     * Returns: the number of colors supported (max 256), or 0 if monochrome
     */
    int colors();

    /**
     * Show content on the screen, doing so efficiently.
     */
    void show();

    /**
     * Update the screen, writing every cell.  This should be done
     * to repair screen damage, for example.
     */
    void sync();

    /**
     * Emit a beep or bell.  This is done immediately.
     */
    void beep();

    /**
     * Attempt to resize the terminal.  YMMV.
     */
    void setSize(Coord);

    /**
     * Set the default style used when clearing the screen, etc.
     */
    void setStyle(Style);

    /**
     * Fill the entire screen with the given content and style.
     * Content is not drawn until the show() or sync() functions are called.
     */
    void fill(string s, Style style);

    /**
     * Fill the entire screen with the given content, but preserve the style.
     */
    void fill(string s);

    /**
     * Applications should call this in response to receiving
     * a resize event.  (This can't be done automatically to
     * avoid thread safety issues.)
     */
    void resize();

    /**
     * Start should be called to start processing.  Once this begins,
     * events (see event.d) will be delivered to the caller via
     * std.concurrency.send().  Additionally, this may change terminal
     * settings to put the input stream into raw mode, etc.
     */
    void start();
    void start(Tid);

    /**
     * Stop is called to stop processing on the screen.  The terminal
     * settings will be restored, and the screen may be cleared. Input
     * events will no longer be delivered.  This should be called when
     * the program is exited, or if suspending (to run a sub-shell process
     * interactively for example).
     */
    void stop();
}

version(unittest)
private class FakeScreen : Screen
{
    private CellBuffer buffer;
    private Style defStyle;

    this(Coord sz)
    {
        buffer = new CellBuffer(sz);
    }

    // Clear screen to spaces using current default style.
    void clear()
    {
        buffer.fill(" ", defStyle);
    }

    // Indexing into our backing buffer.
    ref Cell opIndex(size_t x, size_t y)
    {
        return buffer[x, y];
    }

    // Assign a full Cell into our backing buffer.
    void opIndexAssign(Cell c, size_t x, size_t y)
    {
        buffer[x, y] = c;
    }

    // Note: string convenience assignment is provided by Screen's final
    // overloads; we don't re-declare them here to avoid overriding finals.

    // Cursor-related helpers (no-ops for tests).
    void showCursor(Cursor cur) {}
    void showCursor(Coord pos, Cursor cur = Cursor.current) {}

    // Basic capabilities not used in tests.
    bool hasKey(Key) { return false; }

    // Current size of the buffer.
    Coord size()
    {
        return buffer.size();
    }

    // Event APIs return none for tests.
    Event receiveEvent(Duration) { return Event(EventType.none); }
    Event receiveEvent() { return Event(EventType.none); }

    // Paste & mouse control (no-ops for tests).
    void enablePaste(bool) {}
    bool hasMouse() { return false; }
    void enableMouse(MouseEnable) {}

    // Color reporting (not used).
    int colors() { return 0; }

    // Rendering flush/sync (no-ops).
    void show() {}
    void sync() {}

    // Bell (no-op).
    void beep() {}

    // Sizing and default style.
    void setSize(Coord sz) { buffer.resize(sz); }
    void setStyle(Style st) { defStyle = st; }

    // Fill helpers delegate to buffer.
    void fill(string s, Style style) { buffer.fill(s, style); }
    void fill(string s) { buffer.fill(s); }

    // Resize notification (not needed for tests).
    void resize() {}

    // Lifecycle (no-ops for tests).
    void start() {}
    void start(Tid) {}
    void stop() {}
}

unittest
{
    // Test helper: construct a small fake screen for exercising Screen conveniences.
    Screen screen = new FakeScreen(Coord(4, 3));

    // Test 1: Write simple glyph at X,Y and verify text and style preservation.
    auto beforeStyle = screen[2, 1].style; // capture existing style
    screen[2, 1] = "A"; // use string convenience (x, y)
    assert(screen[2, 1].text == "A");
    assert(screen[2, 1].style == beforeStyle); // style preserved

    // Test 2: Write via Coord overload and verify text.
    screen[Coord(0, 0)] = "Z"; // use Coord convenience
    assert(screen[0, 0].text == "Z");

    // Test 3: Empty string is normalized to a single space.
    screen[1, 1] = "";
    assert(screen[1, 1].text == " ");

    // Test 4: Control character is normalized to a single space.
    screen[1, 2] = "\n";
    assert(screen[1, 2].text == " ");

    // Test 5: Style is preserved when writing a string.
    Style styled;
    styled.fg = Color.red;
    styled.bg = Color.blue;
    styled.attr = Attr.bold;
    // seed a non-default style using Cell assignment
    screen[3, 0] = Cell("X", styled);
    // now write string and ensure style unchanged while text updated
    screen[3, 0] = "=";
    assert(screen[3, 0].text == "=");
    assert(screen[3, 0].style == styled);
}

unittest
{
    // Test style assignment via (x, y): style updates while text is preserved.
    Screen screen = new FakeScreen(Coord(4, 3));
    screen[1, 1] = "T"; // seed some text
    auto beforeText = screen[1, 1].text;

    Style s;
    s.fg = Color.green;
    s.bg = Color.black;
    s.attr = Attr.underline;

    screen[1, 1] = s; // use Style convenience (x, y)
    assert(screen[1, 1].style == s); // style applied
    assert(screen[1, 1].text == beforeText); // text preserved

    // Test style assignment via Coord overload: same guarantees hold.
    Style s2;
    s2.fg = Color.yellow;
    s2.bg = Color.blue;
    s2.attr = Attr.reverse;

    screen[Coord(2, 0)] = "X"; // seed text
    screen[Coord(2, 0)] = s2;   // apply style via Coord
    assert(screen[2, 0].style == s2); // style applied
    assert(screen[2, 0].text == "X"); // text preserved
}

unittest
{
    // Write basic (truncate): ensure writing stops at end of row.
    Screen screen = new FakeScreen(Coord(4, 2));
    screen.clear();
    screen.write(1, 0, "ABC");
    assert(screen[1, 0].text == "A");
    assert(screen[2, 0].text == "B");
    assert(screen[3, 0].text == "C");
    // Writing at last column truncates remainder
    screen.write(3, 1, "XYZ");
    assert(screen[3, 1].text == "X");
}

unittest
{
    // Write via Coord (truncate)
    Screen screen = new FakeScreen(Coord(4, 2));
    screen.clear();
    screen.write(Coord(0, 1), "Hi");
    assert(screen[0, 1].text == "H");
    assert(screen[1, 1].text == "i");
}

unittest
{
    // Wrap across rows: string continues on next line.
    Screen screen = new FakeScreen(Coord(3, 2));
    screen.clear();
    screen.writeWrap(2, 0, "WXYZ");
    assert(screen[2, 0].text == "W");
    assert(screen[0, 1].text == "X");
    assert(screen[1, 1].text == "Y");
    assert(screen[2, 1].text == "Z");
}

unittest
{
    // Control and empty normalization: control → space; empty → no-ops
    Screen screen = new FakeScreen(Coord(4, 1));
    screen.clear();
    screen.write(0, 0, "\n\t");
    assert(screen[0, 0].text == " ");
    assert(screen[1, 0].text == " ");
    screen.writeWrap(Coord(2, 0), ""); // no writes
    assert(screen[2, 0].text == " ");
}

unittest
{
    // Style application (truncate): both text and style applied to written cells.
    Screen screen = new FakeScreen(Coord(4, 1));
    screen.clear();
    Style st; st.fg = Color.green; st.bg = Color.black; st.attr = Attr.bold;
    screen.write(1, 0, "AB", st);
    assert(screen[1, 0].text == "A" && screen[1, 0].style == st);
    assert(screen[2, 0].text == "B" && screen[2, 0].style == st);
    // Unaffected cell keeps default style (not asserting exact default value, just that text stayed space)
    assert(screen[0, 0].text == " ");
}

unittest
{
    // Style application with wrap: style applied across wrapped cell.
    Screen screen = new FakeScreen(Coord(3, 2));
    screen.clear();
    Style st; st.fg = Color.yellow; st.bg = Color.blue; st.attr = Attr.reverse;
    screen.writeWrap(2, 0, "ab", st);
    assert(screen[2, 0].text == "a" && screen[2, 0].style == st);
    assert(screen[0, 1].text == "b" && screen[0, 1].style == st);
}

unittest
{
    // Non-ASCII smoke test: ensure Unicode chars are placed as units.
    Screen screen = new FakeScreen(Coord(4, 1));
    screen.clear();
    screen.write(0, 0, "角🙂");
    assert(screen[0, 0].text == "角");
    assert(screen[1, 0].text == "🙂");
}
