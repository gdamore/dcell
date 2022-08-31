// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.screen;

public import dcell.cell;
public import dcell.cursor;
public import dcell.key;

abstract class Screen
{
    abstract int setup();
    abstract void teardown();

    /**
     * Clears the screen.  This doesn't take effect until
     * the show function is called.
     */
    abstract void clear();

    /**
     * Retrive the contents for a given address.  This is taken from
     * the backing draw buffer, and won't necessarily reflect what is
     * displayed to the user until show is called.
     */
    abstract const(Cell) opIndex(Coord);

    /**
     * Set the content for for a given location.  This won't necessarily
     * take effect until the show function is called.
     */
    abstract void opIndexAssign(Cell, Coord);

    /** Convenience for indexing */
    const(Cell) opIndex(int x, int y)
    {
        return this[Coord(x, y)];
    }

    /** Convenience for indexing. */
    void opIndexAssign(Cell c, int x, int y)
    {
        this[Coord(x, y)] = c;
    }

    /**
     * Show the cursor at its current location.
     */
    abstract void showCursor(Cursor);

    /**
     * Move the cursor to the given location, and show
     * it using the appropriate style.
     *
     * Params:
     *  pos = position of the cursor
     *  cur = cursor style
     */
    abstract void showCursor(Coord pos, Cursor cur=Cursor.current);

    /**
     * It would be nice to know if a given key is supported by
     * a terminal.  Note that this is best-effort, and some terminals
     * may present the ability to support a key, without actually having
     * such a physical key and some combinations may be suppressed by
     * the emulator or the environment the emulator runs in.
     *
     * Returns: true if the key appears to be supported on the terminal.
     */
    abstract bool hasKey(Key);

    /**
     * Obtain the terminal window size.
     * The x, y represent the number of columns and rows.
     * The highest valid address will be coord.x-1, coord.y-1.
     *
     * Returns: terminal dimensions
     */
    abstract Coord size();

    // TODO: event posting, and polling (for keyboard)

    /**
     * Enable backeted paste mode mode.  Bracketed paste mode
     * will pasted content in a single event, and is therefore
     * distinguishable from individually typed characters.
     *
     * Params: 
     *   b = true to enable bracketed paste, false for disable
     */
    abstract void enablePaste(bool b);

    /**
     * Do we have a mouse? This may be overly optimitistic for some
     * terminals, but it is a good first guess.
     *
     * Returns: true if the terminal is thought to support mouse events
     */
    abstract bool hasMouse();

    /**
     * If the terminal supports color, this returns the
     * the number of colors.
     *
     * Returns: the number of colors supported (max 256), or 0 if monochrome
     */
    abstract int colors();

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
     * Emit a beep or bell.  This is done immediately.
     */
    abstract void beep();

    /**
     * Attempt to resize the terminal.  YMMV.
     */
    abstract void setSize(Coord);
}
