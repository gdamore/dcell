/**
 * Termio module for dcell contains code associated iwth managing terminal settings such as
 * non-blocking mode.
 *
 * Copyright: Copyright 2022 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.termio;

import std.exception;
import std.range.interfaces;
import dcell.coord;

/**
 * TtyImpl is the interface that implementations should
 * override or supply to support terminal I/O ioctls or
 * equivalent functionality.  It is provided in this form, as
 * some implementations may not be based on actual tty devices.
 */
interface TtyImpl
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
     * Make input blocking or non-blocking.  Blocking input
     * will cause reads against the terminal to block forever
     * until at least one character is returned.  Otherwise it
     * will return in at most
     */
    void blocking(bool b);

    /**
     * Read input.  May return an empty slice if no data
     * is present and blocking is disabled.
     */
    string read();

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
     */
    bool resized();
}

version (Posix)
{
    import core.sys.posix.sys.ioctl;
    import core.sys.posix.termios;
    import core.sys.posix.unistd;
    import std.stdio;

    package class PosixTty : TtyImpl
    {
        this(string dev)
        {
            path = dev;
        }

        void start()
        {
            if (!file.isOpen)
            {
                file = File(path, "r+b");
                fd = file.fileno();
            }
            save();
            watchResize(fd);
        }

        void stop()
        {
            if (file.isOpen())
            {
                ignoreResize(fd);
                flush();
            }
        }

        void close()
        {
            if (file.isOpen)
            {
                stop();
                restore();
                file.close();
            }
        }

        void save()
        {
            if (!isatty(fd))
                throw new Exception("not a tty device");
            enforce(tcgetattr(fd, &saved) >= 0, "failed to get termio state");
        }

        void restore()
        {
            enforce(tcsetattr(fd, TCSAFLUSH, &saved) >= 0, "failed to set termio state");
        }

        void flush()
        {
            file.flush();
        }

        void blocking(bool b) @trusted
        {
            termios tio;
            enforce(tcgetattr(fd, &tio) >= 0);
            tio.c_cc[VMIN] = b ? 1 : 0;
            tio.c_cc[VTIME] = 0;

            enforce(tcsetattr(fd, TCSANOW, &tio) >= 0);
            block = b;
        }

        void raw() @trusted
        {
            termios tio;
            enforce(tcgetattr(fd, &tio) >= 0, "failed to get termio state");
            tio.c_iflag &= ~(IGNBRK | BRKINT | ISTRIP | INLCR | IGNCR | ICRNL | IXON);
            tio.c_oflag &= ~OPOST;
            tio.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
            tio.c_cflag &= ~(CSIZE | PARENB);
            tio.c_cflag |= CS8;
            tio.c_cc[VMIN] = 1; // at least one character
            tio.c_cc[VTIME] = 0; // but block forever
            enforce(tcsetattr(fd, TCSANOW, &tio) >= 0, "failed to set termios");
        }

        Coord windowSize()
        {
            // If cores.sys.posix.sys.ioctl had more complete and accurate data...
            // this structure is fairly consistent amongst all POSIX variants
            struct winSz
            {
                ushort ws_row;
                ushort ws_col;
                ushort ws_xpix;
                ushort ws_ypix;
            }

            version (linux)
            {
                // has TIOCGWINSZ already -- but it might be wrong
                // Linux has different values for TIOCGWINSZ depending
                // on architecture
                // SPARC, PPC, and MIPS use legacy BSD based values.
                // Others use a newer // value.
                version (SPARC64)
                    enum TIOCGWINSZ = 0x40087468;
                else version (SPARC)
                    enum TIOCGWINSZ = 0x40087468;
                else version (PPC)
                    enum TIOCGWINSZ = 0x40087468;
                else version (PPC64)
                    enum TIOCGWINSZ = 0x40087468;
                else version (MIPS32)
                    enum TIOCGWINSZ = 0x40087468;
                else version (MIPS64)
                    enum TIOCGWINSZ = 0x40087468;
                else
                    enum TIOCGWINSZ = 0x5413; // everything else
            }
            else version (Darwin)
                enum TIOCGWINSZ = 0x40087468;
            else version (Solaris)
                enum TIOCGWINSZ = 0x5468;
            else version (OpenBSD)
                enum TIOCGWINSZ = 0x40087468;
            else version (DragonFlyBSD)
                enum TIOCGWINSZ = 0x40087468;
            else version (NetBSD)
                enum TIOCGWINSZ = 0x40087468;
            else version (FreeBSD)
                enum TIOCGWINSZ = 0x40087468;
            else version (AIX)
                enum TIOCGWINSZ = 0x40087468;

            winSz wsz;
            enforce(ioctl(fd, TIOCGWINSZ, &wsz) >= 0);
            return Coord(wsz.ws_col, wsz.ws_row);
        }

        string read()
        {
            // this has to use the underlying read system call
            import unistd = core.sys.posix.unistd;

            ubyte[] buf = new ubyte[128];
            auto rv = unistd.read(fd, cast(void*) buf.ptr, buf.length);
            if (rv < 0)
                return "";
            return cast(string) buf[0 .. rv];
        }

        void write(string s)
        {
            file.write(s);
        }

        bool resized()
        {
            return wasResized(fd);
        }

    private:
        string path;
        File file;
        int fd;
        termios saved;
        bool block;
    }

    TtyImpl newDevTty(string dev = "/dev/tty")
    {
        return new PosixTty(dev);
    }

}
else
{
    TtyImpl newDevTty(string _ = "/dev/tty")
    {
        throw new Exception("not supported");
    }
}

version (Posix)
{
    import core.atomic;
    import core.sys.posix.signal;

    private __gshared int sigRaised = 0;
    private __gshared int sigFd = -1;
    private extern (C) void handleSigWinCh(int _) nothrow
    {
        int fd = sigFd;
        atomicStore(sigRaised, 1);
        termios tio;
        // wake the input loop so it can see the signal
        // this is crummy but its the best way to get this noticed.
        if (tcgetattr(fd, &tio) >= 0)
        {
            tio.c_cc[VMIN] = 0;
            tio.c_cc[VTIME] = 1;
            tcsetattr(fd, TCSANOW, &tio);
        }
    }

    // We don't have a stanrdard definition of SIGWINCH
    version (linux)
    {
        // Legacy Linux is not even self-compatible ick.
        version (MIPS_Any)
            enum SIGWINCH = 20;
        else
            enum SIGWINCH = 28;
    }
    else version (Solaris)
        enum SIGWINCH = 20;
    else version (OSX)
        enum SIGWINCH = 28;
    else version (FreeBSD)
        enum SIGWINCH = 28;
    else version (NetBSD)
        enum SIGWINCH = 28;
    else version (DragonFlyBSD)
        enum SIGWINCH = 28;
    else version (OpenBSD)
        enum SIGWINCH = 28;
    else version (AIX)
        enum SIGWINCH = 28;
    else
        static assert(0, "no version");

    void watchResize(int fd)
    {
        if (atomicLoad(sigFd) == -1)
        {
            sigFd = fd;
            sigaction_t sa;
            sa.sa_handler = &handleSigWinCh;
            sigaction(SIGWINCH, &sa, null);
        }
    }

    void ignoreResize(int fd)
    {
        if (atomicLoad(sigFd) == fd)
        {
            sigaction_t sa;
            sa.sa_handler = SIG_IGN;
            sigaction(SIGWINCH, &sa, null);
            sigFd = -1;
        }
    }

    bool wasResized(int fd)
    {
        if (fd == atomicLoad(sigFd) && fd != -1)
        {
            return atomicExchange(&sigRaised, 0) != 0;
        }
        else
        {
            return false;
        }
    }
}
