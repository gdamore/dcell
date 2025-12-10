/**
 * Tty module for dcell defines the interface that platforms must implement
 * for exchanging data for display, and key strokes and other events, between
 * the specific terminal / pty subsystem, and the VT common core.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.tty;

import std.datetime;
import dcell.coord;

/**
 * Tty is the interface that implementations should
 * override or supply to support terminal I/O ioctls or
 * equivalent functionality.  It is provided in this form, as
 * some implementations may not be based on actual tty devices.
 */
interface Tty
{
    /**
     * Save current tty settings.  These can be subsequently
     * restored using restore.
     */
    void save();

    /**
     * Restore tty settings saved with save().
     */
    void restore();

    /**
     * Make the terminal suitable for raw mode input.
     * In this mode the terminal is not suitable for
     * typical interactive shell use, but is good if absolute
     * control over input is needed.  After this, reads
     * will block until one character is presented.  (Same
     * effect as 'blocking(true)'.
     */
    void raw();

    /**
     * Read input.  May return an empty slice if no data
     * is present and blocking is disabled.
     */
    string read(Duration dur = Duration.zero);

    /**
     * Write output.
     */
    void write(string s);

    /**
     * Flush output.
     */
    void flush();

    /**
     * Get window size.
     */
    Coord windowSize();

    /**
     * Stop input scanning.
     */
    void stop();

    /**
     * Close the tty device.
     */
    void close();

    /**
     * Start termio.  This will open the device.
     */
    void start();

    /**
     * Resized returns true if the window was resized since last checked.
     * Normally resize will force the window into non-blocking mode so
     * that the caller can see the resize in a timely fashion.
     * This is edge triggered (reading it will clear the value.)
     */
    bool resized();
}
