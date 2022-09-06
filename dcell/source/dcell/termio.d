// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

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

    bool eof();

    bool error();

    void stop();

    void start();
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
            file = File(path, "r+");
            fd = file.fileno();
            save();
        }

        void stop()
        {
            flush();
            restore();
            file.close();
        }

        void save()
        {
            if (!isatty(fd))
                throw new Exception("not a tty device");
            enforce(tcgetattr(fd, &saved) >= 0, "failed to get termio state");
        }

        void restore()
        {
            enforce(tcsetattr(fd, TCSANOW, &saved) >= 0, "failed to set termio state");
        }

        void flush()
        {
            file.flush();
        }

        void blocking(bool b)
        {
            termios tio;
            enforce(tcgetattr(fd, &tio) >= 0);
            tio.c_cc[VMIN] = b ? 1 : 0;
            tio.c_cc[VTIME] = b ? 0 : 1;
            enforce(tcsetattr(fd, TCSANOW, &tio) >= 0);
            block = b;
        }

        void raw()
        {
            termios tio;
            enforce(tcgetattr(fd, &tio) >= 0, "failed to get termio state");
            tio.c_iflag ^= IGNBRK | BRKINT | ISTRIP | INLCR | IGNCR | ICRNL | IXON;
            tio.c_oflag ^= OPOST;
            tio.c_lflag ^= ECHO | ECHONL | ICANON | ISIG | IEXTEN;
            tio.c_cflag ^= CSIZE | PARENB;
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
            auto rv = unistd.read(file.fileno(), cast(void *)buf.ptr, buf.length);
            if (rv < 0)
                return "";
            return cast(string) buf[0 .. rv];
        }

        void write(string s)
        {
            file.rawWrite(s);
        }

        bool eof() @safe const
        {
            return file.eof();
        }

        bool error() @safe const
        {
            return file.error();
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
    TtyImpl newDevTty(string p = "/dev/tty")
    {
        throw new Exception("not supported");
    }
}