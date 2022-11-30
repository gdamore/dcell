/**
 * Terminal database module for dcell.
 *
 * Copyright: Copyright 2022 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.database;

import core.thread;
import std.algorithm;
import std.conv;
import std.process : environment;
import std.stdio;
import std.string;

public import dcell.termcap;

@safe:

/**
 * Represents a database of terminal entries, indexed by their name.
 */
synchronized class Database
{
    private static Termcap[string] terms;
    private static const(Termcap)*[string] entries;

    /**
     * Adds an entry to the database.
     * This should be called by terminal descriptions.
     *
     * Params:
     *   ti = terminal capabilities to add
     */
    static void put(immutable(Termcap)* tc) @safe
    {
        entries[tc.name] = tc;
        foreach (name; tc.aliases)
        {
            entries[name] = tc;
        }
    }

    /**
     * Looks up an entry in the database.
     * The name is most likely to be taken from the $TERM environment variable.
     * Some massaging of the entry is done to amend with capabilities and support
     * reasonable fallbacks.
     *
     * Params:
     *   name = name of the terminal (typically from $TERM)
     *
     * Returns:
     *   terminal capabilities if known, `null` if not.
     */
    static const(Termcap)* get(string name, bool addTrueColor = false, bool add256Color = false) @safe
    {
        if (name !in entries)
        {
            // this handles fallbacks for each possible color terminal
            // note that going from "-color" to non-color will wind up
            // falling back to b&w.  we could possibly have a method to
            // add 16 and 8 color fallbacks.
            if (endsWith(name, "-truecolor"))
            {
                return get(name[0 .. $ - "-truecolor".length] ~ "-256color", true, true);
            }
            if (endsWith(name, "-256color"))
            {
                return get(name[0 .. $ - "-256color".length] ~ "-88color", addTrueColor, true);
            }
            if (endsWith(name, "-88color"))
            {
                return get(name[0 .. $ - "-88color".length] ~ "-color", addTrueColor, add256Color);
            }
            if (endsWith(name, "-color"))
            {
                return get(name[0 .. $ - "-color".length], addTrueColor, add256Color);
            }
            return null;
        }

        string colorTerm;
        if ("COLORTERM" in environment)
        {
            colorTerm = environment["COLORTERM"];
        }
        auto tc = new Termcap;

        // poor mans copy, but we have to bypass the const,
        // although we're not going to change actual values.
        // we promise not to modify the aliases array.
        *tc = *(entries[name]);

        // For terminals that use "standard" SGR sequences, lets combine the
        // foreground and background together. This saves one byte sent
        // per screen cell.  Not huge, but it might be as much as 10%.
        if (startsWith(tc.setFg, "\x1b[") &&
            startsWith(tc.setBg, "\x1b[") &&
            endsWith(tc.setFg, ";m") &&
            endsWith(tc.setBg, ";m"))
        {
            tc.setFgBg = tc.setFg[0 .. $ - 1]; // drop m
            tc.setFgBg ~= ';';
            tc.setFgBg ~= replace(tc.setBg[2 .. $], "%p1", "%p2");
        }

        if (tc.colors > 256 || canFind(colorTerm, "truecolor") ||
            canFind(colorTerm, "24bit") || canFind(colorTerm, "24-bit"))
        {
            addTrueColor = true;
        }

        if (addTrueColor && tc.setFgBgRGB == "" && tc.setFgRGB == "" && tc.setBgRGB == "")
        {
            // vanilla ISO 8613-6:1994 24-bit color (ala xterm)
            tc.setFgRGB = "\x1b[38;2;%p1%d;%p2%d;%p3%dm";
            tc.setBgRGB = "\x1b[48;2;%p1%d;%p2%d;%p3%dm";
            tc.setFgBgRGB = "\x1b[38;2;%p1%d;%p2%d;%p3%d;48;2;%p4%d;%p5%d;%p6%dm";
            if (tc.resetColors == "")
            {
                tc.resetColors = "\x1b[39;49m;";
            }
            // assume we can also add 256 color
            tc.colors = 1 << 24;
        }

        if (add256Color || (tc.colors >= 256 && tc.setFg == ""))
        {
            if (tc.colors < 256)
                tc.colors = 256;
            tc.setFg = "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m";
            tc.setBg = "\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m";
            tc.setFgBg = "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;;" ~
                "%?%p2%{8}%<%t4%p2%d%e%p2%{16}%<%t10%p2%{8}%-%d%e48;5;%p2%d%;m";
            tc.resetColors = "\x1b[39;49m";
        }

        // if we have mouse support, we can try to assume that we
        // can safely/reasonably add some other features, if they
        // are not provided for explicitly in the database.
        if (tc.mouse != "")
        {
            // changeable cursor shapes
            if (tc.cursorReset == "")
            {
                tc.cursorReset = "\x1b[0 q";
                tc.cursorBlinkingBlock = "\x1b[1 q";
                tc.cursorBlock = "\x1b[2 q";
                tc.cursorBlinkingUnderline = "\x1b[3 q";
                tc.cursorUnderline = "\x1b[4 q";
                tc.cursorBlinkingBar = "\x1b[5 q";
                tc.cursorBar = "\x1b[6 q";
            }
            // bracketed paste
            if (tc.enablePaste == "")
            {
                tc.enablePaste = "\x1b[?2004h";
                tc.disablePaste = "\x1b[?2004l";
                tc.pasteStart = "\x1b[200~";
                tc.pasteEnd = "\x1b[201~";
            }
            // OSC URL support
            if (tc.enterURL == "")
            {
                tc.enterURL = "\x1b]8;;%p1%s\x1b\\";
                tc.exitURL = "\x1b]8;;\x1b\\";
            }
            // OSC window size
            if (tc.setWindowSize == "")
            {
                tc.setWindowSize = "\x1b[8;%p1%p2%d;%dt";
            }
        }

        // Amend some sequences for URXVT.
        // It seems that urxvt at least send ESC as ALT prefix for these,
        // although some places seem to indicate a separate ALT key sequence.
        // Users are encouraged to update to an emulator that more closely
        // matches xterm for better functionality.
        if (tc.keyShfRight == "\x1b[c" && tc.keyShfLeft == "\x1b[d")
        {
            tc.keyShfUp = "\x1b[a";
            tc.keyShfDown = "\x1b[b";
            tc.keyCtrlUp = "\x1b[Oa";
            tc.keyCtrlDown = "\x1b[Ob";
            tc.keyCtrlRight = "\x1b[Oc";
            tc.keyCtrlLeft = "\x1b[Od";
        }
        if (tc.keyShfHome == "\x1b[7$" && tc.keyShfEnd == "\x1b[8$")
        {
            tc.keyCtrlHome = "\x1b[7^";
            tc.keyCtrlEnd = "\x1b[8^";
        }

        // likewise, if we have mouse support, let's try to add backeted
        // paste support.
        return tc;
    }
}

@safe unittest
{
    static immutable Termcap caps = {
        name: "mytest", aliases: ["mytest-1", "mytest-2"]
    };
    static immutable Termcap caps2 = {
        name: "ctest", mouse: ":mouse", colors: 1 << 24
    };

    Database.put(&caps);
    Database.put(&caps2);

    assert(Database.get("nosuch") is null);
    auto tc = Database.get("mytest");
    assert((tc !is null) && tc.name == "mytest");
    assert(Database.get("mytest-1") !is null);
    assert(Database.get("mytest-2") !is null);

    environment["COLORTERM"] = "truecolor";
    tc = Database.get("mytest-truecolor");
    assert(tc !is null);
    assert(tc.colors == 1 << 24);
    assert(tc.setFgBgRGB != "");
    assert(tc.setFg != "");
    assert(tc.resetColors != "");

    environment["COLORTERM"] = "";
    tc = Database.get("mytest-256color");
    assert(tc !is null);
    assert(tc.colors == 256);
    assert(tc.setFgBgRGB == "");
    assert(tc.setFgBg != "");
    assert(tc.setFg != "");
    assert(tc.resetColors != "");

    tc = Database.get("ctest");
    assert(tc !is null);
    assert(tc.colors == 1 << 24);
    assert(tc.setFgBgRGB != "");
    assert(tc.setFg != "");
    assert(tc.resetColors != "");
    assert(tc.enablePaste != ""); // xterm like
}
