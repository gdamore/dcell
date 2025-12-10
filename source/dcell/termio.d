/**
 * Termio module for dcell contains code associated iwth managing terminal settings such as
 * non-blocking mode.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.termio;

import std.datetime;
import std.exception;
import std.range.interfaces;
import dcell.coord;
import dcell.tty;

version (OSX)
{
    version = UseSelect;
}
else version (iOS)
{
    version = UseSelect;
}
else version (tvOS)
{
    version = UseSelect;
}
else version (VisionOS)
{
    version = UseSelect;
}
else
{
    version = UsePoll;
}

//dfmt off
version (Posix):
//dfmt on

import core.sys.posix.sys.ioctl;
import core.sys.posix.termios;
import core.sys.posix.unistd;
import core.sys.posix.fcntl;
import std.process;
import std.stdio;

package class PosixTty : Tty
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

    void raw()
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
        else version (Apple)
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

    // On macOS, we have to use a select() based implementation because poll()
    // does not work reasonably on /dev/tty. (This was very astonishing when first
    // we discovered it -- POLLNVAL for device files.)
    version (UseSelect) string read(Duration dur = Duration.zero)
    {
        // this has to use the underlying read system call
        import unistd = core.sys.posix.unistd;
        import core.sys.posix.sys.select; // Or similar module for select bindings

        fd_set readFds;
        timeval timeout;
        timeval* tvp;

        FD_ZERO(&readFds);
        FD_SET(fd, &readFds);
        FD_SET(sigRfd, &readFds);

        if (dur.isNegative || dur == Duration.max)
        {
            tvp = null;
        }
        else
        {
            auto usecs = dur.total!"usecs";

            timeout.tv_sec = cast(typeof(timeout.tv_sec)) usecs / 1_000_000;
            timeout.tv_usec = cast(typeof(timeout.tv_usec)) usecs % 1_000_000;
            tvp = &timeout;
        }

        import std.algorithm : max;

        int num = select(max(fd, sigRfd) + 1, &readFds, null, null, tvp);

        if (num < 1)
        {
            return "";
        }

        string result;

        if (FD_ISSET(fd, &readFds))
        {
            ubyte[128] buf;
            auto nread = unistd.read(fd, cast(void*) buf.ptr, buf.length);
            if (nread > 0)
            {
                result = cast(string)(buf[0 .. nread]).dup;
            }
        }
        if (FD_ISSET(sigRfd, &readFds))
        {
            ubyte[1] buf;
            // this can fail, we're just clearning the signaled state
            unistd.read(sigRfd, buf.ptr, 1);
        }
        return result;
    }

    version (UsePoll) string read(Duration dur = Duration.zero)
    {
        // this has to use the underlying read system call
        import unistd = core.sys.posix.unistd;
        import core.sys.posix.poll;
        import core.sys.posix.fcntl;

        pollfd[2] pfd;
        pfd[0].fd = fd;
        pfd[0].events = POLLRDNORM;
        pfd[0].revents = 0;

        pfd[1].fd = sigRfd;
        pfd[1].events = POLLRDNORM;
        pfd[1].revents = 0;

        int dly;
        if (dur.isNegative || dur == Duration.max)
        {
            dly = -1;
        }
        else
        {
            dly = cast(int)(dur.total!"msecs");
        }

        string result;

        long rv = poll(pfd.ptr, 2, dly);
        if (rv < 1)
        {
            return result;
        }
        if (pfd[0].revents & POLLRDNORM)
        {
            ubyte[128] buf;
            auto nread = unistd.read(fd, cast(void*) buf.ptr, buf.length);
            if (nread > 0)
            {
                result = cast(string)(buf[0 .. nread]).dup;
            }
        }
        if (pfd[1].revents & POLLRDNORM)
        {
            ubyte[1] buf;
            // this can fail, and its fine (just clearing the signaled state)
            unistd.read(sigRfd, buf.ptr, 1);
        }
        import std.format;

        return result;
    }

    void write(string s)
    {
        file.write(s);
    }

    bool resized()
    {
        // NB: resized is edge triggered.
        return wasResized(fd);
    }

private:
    string path;
    File file;
    int fd;
    termios saved;
    bool block;
}

import core.atomic;
import core.sys.posix.signal;

private:

__gshared int sigRaised = 0;
__gshared int sigFd = -1;
__gshared Pipe sigPipe;
__gshared int sigWfd;
__gshared int sigRfd;

extern (C) void handleSigWinCh(int _) nothrow
{
    atomicStore(sigRaised, 1);

    // wake any reader so it can see the update
    // this is crummy but its the best way to get this noticed.
    ubyte[1] buf;
    import unistd = core.sys.posix.unistd;

    // we do not care if this fails
    unistd.write(sigWfd, buf.ptr, 1);
}

// We don't have a standard definition of SIGWINCH
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
    import std.process;
    import core.sys.posix.fcntl;

    if (atomicLoad(sigFd) == -1)
    {
        // create the pipe for notifications if not already done so.
        sigPipe = pipe();
        sigWfd = sigPipe.writeEnd.fileno();
        sigRfd = sigPipe.readEnd.fileno();
        fcntl(sigWfd, F_SETFL, O_NONBLOCK);
        fcntl(sigRfd, F_SETFL, O_NONBLOCK);

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
        sigPipe.close();
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
