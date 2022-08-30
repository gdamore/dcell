// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.tty;

/**
 * A common interface for TTY style devices, such as serial ports or
 * terminal line disciplines used by terminal emulators.
 */
interface Tty {
    /** 
     * Start should activate the TTY for use.  This means that the terminal
     * should be in raw mode (unbuffered) mode.  Implementations need to save any
     * state that will be restored at stop.  May throw an exception on failure.
     */
    void start();

    /** 
     * Stop uisng this TTY.  This might be temporary.  State should be restored
     * (collected in start), and the terminal should behave in cooked mode.
     * Once called, read and write will no longer be called.
     */
    void stop();

    /** 
     * Drain the terminal.  This is a hack required for certain UNIX implementations
     * that won't wake a reader when the terminal is closed.  Typically the
     * implementation will need to set VMIN and VTIME both to zero, to force
     * into full non-blockining mode to wake the reader.  Implementations that
     * don't have this problem can make this a no-op.  Note that this does not
     * cease I/O -- it is only prepatory to stop.
     */
    void drain();

    /**
     * Notify when the window size changes.  Typically this is wired up to
     * SIGWINCH.  The delegate should call windowSize to determine the actual
     * new size.
     */
    void notifyResize(void delegate());

    /** 
     * Return the window size (width, then height).
     */
    void windowSize(ref int width, ref int height);

    /**
     * Read some data (bytes) from the tty.
     */
    byte[] read();
 
    /**
     * Write some bytes to the tty.
    */
    void write(byte[]);
}
