// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.screen;

public import dcell.cell;

abstract class Screen
{
    abstract int setup();
    abstract void teardown();

    /// Clears the screen.
    abstract void clear();

    abstract void set(int x, int y, Cell c);
    abstract Cell get(int x, int y);

    abstract void hideCursor();
    abstract void showCursor(Coord);

    // TODO: setCursorStyle();

    abstract Coord size();

    int width()
    {
        return size().x;
    }

    int height()
    {
        return size().y;
    }

    // TODO: event posting, and polling (for keyboard)

    abstract void enablePaste();
    abstract void disablePaste();

    abstract bool hasMouse();
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
     * Emit a beep or bell.
     */
    abstract void beep();

    /**
     * Attempt to resize the terminal.  YMMV.
     */
    abstract void setSize(int rows, int cols);
}
