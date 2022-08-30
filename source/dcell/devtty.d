// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.devtty;

import std.exception;
import std.stdio;
import core.sys.posix.fcntl;
import core.sys.posix.unistd;
import core.sys.posix.termios;
import core.sys.posix.sys.ioctl;

import dcell.tty;

version(POSIX):

/**
 * A tty implemented on top of the /dev/tty device found on common
 * POSIX systems.
 */
class DevTty : Tty
{
    private int fd;
    private File f;
    string path;
    termios saved;

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
        enforce(tcsetattr(fd, TCSANOW, &raw), "failed to set termios");
    }

    private void restore()
    {
        enforce(tcsetattr(fd, TCSANOW, &saved) >= 0, "failed to restore termios");
    }

    void start()
    {
        f = File(path, "r+b");
        fd = f.fileno();
        enforce(isatty(fd), "file must be a tty");

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
        enforce(tcgetattr(fd, &tio));
        // set this to non-blocking
        tio.c_cc[VMIN] = 0;
        tio.c_cc[VTIME] = 0;
        enforce(tcsetattr(fd, TCSANOW, &tio));
    }

    void windowSize(ref int width, ref int height)
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
        { // has TIOCGWINSZ already -- but it might be wrong
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
        width = wsz.ws_col;
        height = wsz.ws_row;
    }

    void write(byte[] b)
    {
        f.rawWrite(b);
    }

    byte[] read()
    {
        auto b = new byte[128];
        return f.rawRead(b);
    }
}
