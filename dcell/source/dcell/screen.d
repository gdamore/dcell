// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.screen;

public import dcell.cell;
public import dcell.cursor;
public import dcell.key;
public import dcell.mouse;

interface Screen
{
    /**
     * Clears the screen.  This doesn't take effect until
     * the show function is called.
     */
    void clear();

    /**
     * Retrive the contents for a given address.  This is taken from
     * the backing draw buffer, and won't necessarily reflect what is
     * displayed to the user until show is called.
     */
    ref Cell opIndex(Coord);

    /**
     * Set the content for for a given location.  This won't necessarily
     * take effect until the show function is called.
     */
    void opIndexAssign(Cell, Coord);

    /** Convenience for indexing */
    final const(Cell) opIndex(int x, int y)
    {
        return this[Coord(x, y)];
    }

    /** Convenience for indexing. */
    final void opIndexAssign(Cell c, int x, int y)
    {
        this[Coord(x, y)] = c;
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

    // TODO: event posting, and polling (for keyboard)

    /**
     * Enable backeted paste mode mode.  Bracketed paste mode
     * will pasted content in a single event, and is therefore
     * distinguishable from individually typed characters.
     *
     * Params: 
     *   b = true to enable bracketed paste, false for disable
     */
    void enablePaste(bool b);

    /**
     * Do we have a mouse? This may be overly optimitistic for some
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
     * Set the default style used when clearning the screen, etc.
     */
    void setStyle(Style);

    /**
     * Fill the entire screen with the given content and style.
     */
    void fill(string s, Style style);

    /**
     * Applications should call this in response to receiving
     * a resize event.  (This can't be done automatically to
     * avoid thread safety issues.)
     */
    void resize();

    /**
     * Fill the entire screen with the given content, but preserve the style.
     */
    void fill(string s);

    /**
     * Start should be called to start processing.  Once this begins,
     * events (see event.d) will be delivered to the caller via
     * std.concurrency.send().  Additioanlly, this may change terminal
     * settings to put the input stream into raw mode, etc.
     */
    void start();

    /**
     * Stop is called to stop processing on teh screen.  The terminal
     * settings will be restored, and the screen may be cleared. Input
     * events will no longer be delivered.  This should be called when
     * the program is exited, or if suspending (to run a subshell process
     * interactively for example).
     */
    void stop();
}
