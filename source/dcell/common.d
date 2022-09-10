// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.common;

import dcell.screen;

version (Posix)
{
    import dcell.ttyscreen;

    /**
     * Obtain a new screen. On POSIX this is connected to /dev/tty
     * using the $TERM environment variable (or ansi if not set).
     */
    Screen newScreen()
    {
        return newTtyScreen();
    }
}
else version (Windows)
{
    Screen newScreen()
    {
        import std.exception;

        throw new Exception("windows not supported yet");
        return null;
    }
}
else
{
    Screen newScreen()
    {
        import std.exception;

        throw new Exception("platform not known");
        return null;
    }
}
