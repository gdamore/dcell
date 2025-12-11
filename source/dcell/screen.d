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

    /** Support $ operation in indices. */
    size_t opDollar(size_t dim)()
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
     * Obtain the terminal window size.
     * The x, y represent the number of columns and rows.
     * The highest valid address will be coord.x-1, coord.y-1.
     *
     * Returns: terminal dimensions
     */
    Coord size();

    /**
     * Wait for an event, up to the given duration.  This is used
     * to rescan for changes as well, so it should be called as
     * frequently.
     */
    Event waitEvent(Duration dur = msecs(100));

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
     * Enable or disable the alternate screen. This must be called
     * before start().  Note that this is best effort -- not every
     * terminal actually supports this.  This is on by default.
     * It can be disabled by setting DCELL_ALTSCREEN=disable in the
     * environment.
     */
    void enableAlternateScreen(bool on);

    /**
     * Set the title of the window. This only works for emulators running
     * in a windowing environment, and is not universally supported.
     * Setting an empty string as the title may let the emulator set
     * a specific default, but it may also leave it empty - it depends
     * on the specific terminal implementation.
     */
    void setTitle(string);

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
     * Start sets up the terminal.  This changes terminal
     * settings to put the input stream into raw mode, etc.
     */
    void start();

    /**
     * Stop is called to stop processing on the screen.  The terminal
     * settings will be restored, and the screen may be cleared.
     *
     * This should be called when the program is exited, or if suspending
     * (to run a sub-shell process interactively for example).
     */
    void stop();
}
