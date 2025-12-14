/**
 * Windows TTY support for dcell.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.wintty;

// dfmt off
version (Windows):
// dfmt on

import core.sys.windows.windows;
import std.datetime;
import std.exception;
import std.range.interfaces;
import dcell.coord;
import dcell.tty;

// Kernel32.dll functions
extern (Windows) @nogc nothrow
{
    BOOL ReadConsoleInputW(HANDLE hConsoleInput, INPUT_RECORD* lpBuffer, DWORD nLength, DWORD* lpNumEventsRead);

    BOOL GetNumberOfConsoleInputEvents(HANDLE hConsoleInput, DWORD* lpcNumberOfEvents);

    BOOL FlushConsoleInputBuffer(HANDLE hConsoleInput);

    DWORD WaitForMultipleObjects(DWORD nCount, const HANDLE* lpHandles, BOOL bWaitAll, DWORD dwMilliseconds);

    BOOL SetConsoleMode(HANDLE hConsoleHandle, DWORD dwMode);

    BOOL GetConsoleMode(HANDLE hConsoleHandle, DWORD* lpMode);

    BOOL GetConsoleScreenBufferInfo(HANDLE hConsoleOutput, CONSOLE_SCREEN_BUFFER_INFO* lpConsoleScreenBufferInfo);

    HANDLE CreateEventW(SECURITY_ATTRIBUTES* secAttr, BOOL bManualReset, BOOL bInitialState, LPCWSTR lpName);

    BOOL SetEvent(HANDLE hEvent);

    BOOL WriteConsoleW(HANDLE hFile, LPCVOID buf, DWORD nNumBytesToWrite, LPDWORD lpNumBytesWritten, LPVOID rsvd);

    BOOL CloseHandle(HANDLE hObject);
}

@nogc:
nothrow:

/**
 * WinTty impleements the Tty using the VT input mode and the Win32 ReadConsoleInput and WriteConsole APIs.
 * We use this instead of ReadFile/WriteFile in order to obtain resize events, and access to the screen size.
 * The terminal is expected to be connected the the process' STD_INPUT_HANDLE and STD_OUTPUT_HANDLE.
 */
class WinTty : Tty
{

    /**
     * Default constructor.
     * This expects the terminal to be connected to STD_INPUT_HANDLE and STD_OUTPUT_HANDLE.
     */
    this()
    {
        input = GetStdHandle(STD_INPUT_HANDLE);
        output = GetStdHandle(STD_OUTPUT_HANDLE);
        eventH = CreateEventW(null, true, false, null);
    }

    void save()
    {

        GetConsoleMode(output, &omode);
        GetConsoleMode(input, &imode);
    }

    void restore()
    {
        SetConsoleMode(output, omode);
        SetConsoleMode(input, imode);
    }

    void start()
    {
        save();
        if (!started)
        {
            started = true;
            FlushConsoleInputBuffer(input);
        }
    }

    void stop()
    {
        SetEvent(eventH);
    }

    void close()
    {
        // NB: We do not close the standard input and output handles.
        CloseHandle(eventH);
    }

    void raw()
    {
        SetConsoleMode(input, ENABLE_VIRTUAL_TERMINAL_INPUT | ENABLE_WINDOW_INPUT | ENABLE_EXTENDED_FLAGS);
        SetConsoleMode(output,
            ENABLE_PROCESSED_OUTPUT | ENABLE_VIRTUAL_TERMINAL_PROCESSING | DISABLE_NEWLINE_AUTO_RETURN);
    }

    void flush()
    {
    }

    string read(Duration dur = Duration.zero)
    {
        HANDLE[2] handles;
        handles[0] = input;
        handles[1] = eventH;

        DWORD dly;
        if (dur.isNegative || dur == Duration.max)
        {
            dly = INFINITE;
        }
        else
        {
            dly = cast(DWORD)(dur.total!"msecs");
        }

        auto rv = WaitForMultipleObjects(2, handles.ptr, false, dly);
        string result = null;

        // WaitForMultipleObjects returns WAIT_OBJECT_0 + the index.
        switch (rv)
        {
        case WAIT_OBJECT_0 + 1: // w.cancelFlag
            return result;
        case WAIT_OBJECT_0: // input
            INPUT_RECORD[128] recs;
            DWORD nrec;
            ReadConsoleInput(input, recs.ptr, 128, &nrec);

            foreach (ev; recs[0 .. nrec])
            {
                switch (ev.EventType)
                {
                case KEY_EVENT:
                    if (ev.KeyEvent.bKeyDown && ev.KeyEvent.AsciiChar != 0)
                    {
                        auto chr = ev.KeyEvent.AsciiChar;
                        result ~= chr;
                    }
                    break;
                case WINDOW_BUFFER_SIZE_EVENT:
                    wasResized = true;
                    break;
                default: // we could process focus, etc. here, but we already
                    // get them inline via VT sequences
                    break;
                }
            }

            return result;
        default:
            return result;
        }
    }

    // Write output
    void write(string s) @nogc nothrow
    {
        import std.utf;

        wchar[128] buf;
        uint l = 0;
        foreach (wc; s.byWchar)
        {
            buf[l++] = wc;
            if (l == buf.length)
            {
                WriteConsoleW(output, buf.ptr, l, null, null);
                l = 0;
            }
        }
        if (l != 0)
        {
            WriteConsoleW(output, buf.ptr, l, null, null);
        }
    }

    Coord windowSize()
    {
        CONSOLE_SCREEN_BUFFER_INFO info;
        GetConsoleScreenBufferInfo(output, &info);
        return Coord(info.srWindow.Right - info.srWindow.Left + 1,
            info.srWindow.Bottom - info.srWindow.Top + 1);
    }

    bool resized()
    {
        bool result = wasResized;
        wasResized = false;
        return result;
    }

    void wakeUp()
    {
        SetEvent(eventH);
    }

private:
    HANDLE output;
    HANDLE input;
    HANDLE eventH;
    DWORD omode;
    DWORD imode;
    bool started;
    bool wasResized;
}
