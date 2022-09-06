// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.devtty;

version (Posix)
{
    import std.exception;
    import std.stdio;
    import core.sys.posix.fcntl;
    import core.sys.posix.unistd;
    import core.sys.posix.termios;
    import core.sys.posix.sys.ioctl;
    import core.stdc.errno;

    import dcell.tty;

    /**
     * A tty implemented on top of the /dev/tty device found on common
     * POSIX systems.
     */
    class DevTty : Tty
    {
        private int fd;
        private File f;
        private string path;
        private termios saved;

        this(string name = "/dev/tty")
        {
            path = name;
        }

        private void makeraw()
        {
            enforce(tcgetattr(fd, &saved) >= 0, "failed to get termio state");
            termios raw = saved;
            raw.c_iflag ^= IGNBRK | BRKINT | ISTRIP | INLCR | IGNCR | ICRNL | IXON;
            raw.c_oflag ^= OPOST;
            raw.c_lflag ^= ECHO | ECHONL | ICANON | ISIG | IEXTEN;
            raw.c_cflag ^= CSIZE | PARENB;
            raw.c_cflag |= CS8;
            raw.c_cc[VMIN] = 1; // at least one character
            raw.c_cc[VTIME] = 0; // but block forever
            enforce(tcsetattr(fd, TCSANOW, &raw) >= 0, "failed to set termios");
        }

        private void restore()
        {
            enforce(tcsetattr(fd, TCSANOW, &saved) >= 0, "failed to restore termios");
        }

        void start()
        {
            f = File(path, "r+b");
            fd = f.fileno();
            if (!isatty(fd))
            {
                throw new ErrnoException("not a tty", ENOTTY);
            }

            makeraw();
            // setup signal notification? or let that be done via elsewhere?
        }

        void stop()
        {
            restore();
            // TODO: signal the reader
            f.close();
        }

        void notifyResize(void delegate())
        {
            // TODO: implement for SIGWINCH
        }

        void drain()
        {
            termios tio;
            enforce(tcgetattr(fd, &tio) >= 0);
            // set this to non-blocking
            tio.c_cc[VMIN] = 0;
            tio.c_cc[VTIME] = 0;
            enforce(tcsetattr(fd, TCSANOW, &tio) >= 0);
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
                // Linux has different values for TIOCGWINSZ depending on architecture
                // SPARC, PPC, and MIPS use legacy BSD based values.  Others use a newer
                // value.
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

        void write(ubyte[] b)
        {
            f.rawWrite(b);
        }

        ubyte[] read()
        {
            auto b = new ubyte[128];
            return f.rawRead(b);
        }

        ref File file()
        {
            return f;
        }
    }

    unittest
    {
        auto dt = new DevTty("/etc/this-file-does-not-exist");
        assertThrown!ErrnoException(dt.start(),
            `should have failed to open a non-existant file`);
    }

    unittest
    {
        auto dt = new DevTty("/dev/null");
        assertThrown!ErrnoException(dt.start(),
            `should have failed to open non-tty device`);
    }

    unittest
    {
        DevTty dt;
        import std.stdio;
        import std.exception;

        if (isatty(stdin.fileno()))
        {
            int rows, cols;
            dt = new DevTty();
            dt.start();
            assert(dt.file().fileno() >= 0);
            auto wsz = dt.windowSize();
            dt.write(cast(ubyte[]) "Here is some text.\r\n");
            dt.drain();
            auto b = dt.read();
            dt.stop();
            writefln("Terminal size %dx%d", wsz.x, wsz.y);
        }
    }
}
