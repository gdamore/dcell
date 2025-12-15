/**
 * Screen module for dcell provides the common interface for different implementations of KVM type devices.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.screen;

import core.time;

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
    void clear() @safe;

    /**
     * Retrieve the contents for a given address.  This is taken from
     * the backing draw buffer, and won't necessarily reflect what is
     * displayed to the user until show is called.
     */
    ref Cell opIndex(size_t x, size_t y) @safe;

    /** Convenience for indexing */
    final ref Cell opIndex(Coord pos) @safe
    {
        return this[pos.x, pos.y];
    }

    /**
     * Set the content for for a given location.  This won't necessarily
     * take effect until the show function is called.
     */
    void opIndexAssign(Cell, size_t x, size_t y) @safe;

    /** Convenience for indexing. */
    final void opIndexAssign(Cell c, Coord pos) @safe
    {
        this[pos.x, pos.y] = c;
    }

    /** Support $ operation in indices. */
    size_t opDollar(size_t dim)() @safe
    {
        static if (dim == 0)
        {
            return size().x;
        }
        else
        {
            return size().y;
        }
    }

    /**
     * Show the cursor at its current location.
     */
    void showCursor(Cursor) @safe;

    /**
     * Move the cursor to the given location, and show
     * it using the appropriate style.
     *
     * Params:
     *  pos = position of the cursor
     *  cur = cursor style
     */
    void showCursor(Coord pos, Cursor cur = Cursor.current) @safe;

    /**
     * Obtain the terminal window size.
     * The x, y represent the number of columns and rows.
     * The highest valid address will be coord.x-1, coord.y-1.
     *
     * Returns: terminal dimensions
     */
    Coord size() @safe;

    /**
     * Wait for at least one event to be posted, for up to the given time.
     * Params:
     *   timeout = maximum duration to wait for an event to arrive
     *   resched = if no event was posted, the caller should make another
     *             attempt no later than this in order to handle incompletely parsed events
     *
     * Returns: true if at least one event is available, false otherwise.
     */
    bool waitForEvent(Duration timeout, ref Duration resched) @safe;

    /**
     * Wait for at least one event to be posted.
     * This simpler version can be used when the caller is in a simple poll/handle
     * loop (typical for some simple applications.)
     *
     * Params:
     *   timeout = maximum duration to wait for an event to arrive
     *
     * Returns: True if at least one event is available, false otherwise.
     */
    final bool waitForEvent(Duration timeout = Duration.max) @safe
    {
        Duration resched;
        return waitForEvent(timeout, resched);
    }

    /**
     * Obtain the list of events.  The returned value is both an input range of `Event`,
     * (for receiving events), and an output range of `Event`.
     */
    EventQ events() @safe;

    /**
     * Enable bracketed paste mode mode.  Bracketed paste mode
     * will pasted content in a single event, and is therefore
     * distinguishable from individually typed characters.
     *
     * Params:
     *   b = true to enable bracketed paste, false for disable
     */
    void enablePaste(bool b) @safe;

    /**
     * Enable mouse mode.  This can cause terminals/emulators
     * to behave differently -- for example affecting the ability
     * to scroll or use copy/paste.
     *
     * Params:
     *   en = mouse events to report (mask)
     */
    void enableMouse(MouseEnable en) @safe;

    /**
     * Enable typical mouse features. This enables tracking, but
     * leaves drag events disabled.  Enabling mouse drag will impair
     * use of copy-paste at the OS level, which many users tend to
     * find frustrating.
     */
    final void enableMouse() @safe
    {
        enableMouse(MouseEnable.buttons | MouseEnable.motion);
    }

    /**
     * Disable all mouse handling/capture.
     */
    final void disableMouse() @safe
    {
        enableMouse(MouseEnable.disable);
    }

    /**
     * Enable or disable the alternate screen. This must be called
     * before start().  Note that this is best effort -- not every
     * terminal actually supports this.  This is on by default.
     * It can be disabled by setting DCELL_ALTSCREEN=disable in the
     * environment.
     */
    void enableAlternateScreen(bool on) @safe;

    /**
     * Set the title of the window. This only works for emulators running
     * in a windowing environment, and is not universally supported.
     * Setting an empty string as the title may let the emulator set
     * a specific default, but it may also leave it empty - it depends
     * on the specific terminal implementation.
     */
    void setTitle(string) @safe;

    /**
     * If the terminal supports color, this returns the
     * the number of colors.
     *
     * Returns: the number of colors supported (max 256), or 0 if monochrome
     */
    int colors() nothrow @safe;

    /**
     * Show content on the screen, doing so efficiently.
     */
    void show() @safe;

    /**
     * Update the screen, writing every cell.  This should be done
     * to repair screen damage, for example.
     */
    void sync() @safe;

    /**
     * Emit a beep or bell.  This is done immediately.
     */
    void beep() @safe;

    /**
     * Attempt to resize the terminal.  YMMV.
     */
    void setSize(Coord) @safe;

    /**
     * Fill the entire screen with the given content and style.
     * Content is not drawn until the show() or sync() functions are called.
     */
    void fill(string s, Style style) @safe;

    /**
     * Fill the entire screen with the given content, but preserve the style.
     */
    void fill(string s) @safe;

    /**
     * Applications should call this in response to receiving
     * a resize event.  (This can't be done automatically to
     * avoid thread safety issues.)
     */
    void resize() @safe;

    /**
     * Start sets up the terminal.  This changes terminal
     * settings to put the input stream into raw mode, etc.
     */
    void start() @safe;

    /**
     * Stop is called to stop processing on the screen.  The terminal
     * settings will be restored, and the screen may be cleared.
     *
     * This should be called when the program is exited, or if suspending
     * (to run a sub-shell process interactively for example).
     */
    void stop() @safe;

    /**
     * The style property is used when writing content to the screen
     * using the simpler write() API.
     */
    @property ref Style style() @safe;
    @property Style style(const(Style)) @safe;

    /**
     * The position property is used when writing content to the screen
     * when using the simpler write() API.  The position will advance as
     * content is written.
     */
    @property Coord position() const @safe;
    @property Coord position(const(Coord)) @safe;

    void write(string) @safe;
    void write(wstring) @safe;
    void write(dstring) @safe;
}
