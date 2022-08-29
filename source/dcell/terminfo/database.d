// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.terminfo.database;

import core.thread;
import std.algorithm;
import std.conv;
import std.process : environment;
import std.stdio;
import std.string;

public import dcell.terminfo.termcap;
import dcell.terminfo.terminal;

/**
 * Represents a database of terminal entries, indexed by their name.
 */
synchronized class Database
{
    private alias iterm = const Termcap*;
    private static Termcap[string] terms;
    //private static Termcap*[string] entries;
    private static const(Termcap)*[string] entries;

    /**
     * Adds an entry to the database.
     * This should be called by terminal descriptions.
     *
     * Params:
     *   ti = terminal capabilities to add
     */
    static void put(const(Termcap)* tc)
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
    static const(Termcap)* get(string name, bool addTrueColor = false, bool add256Color = false)
    {
        if (name !in entries)
        {
            // this handles fallbacks for each possible color terminal
            // note that going from "-color" to non-color will wind up
            // falling back to b&w.  we could possibly have a method to
            // add 16 and 8 color fallbacks.
            if (endsWith(name, "-truecolor"))
            {
                return get(name[0 .. $ - "-truecolor".length]~"-256color", true, true);
            }
            if (endsWith(name, "-256color"))
            {
                return get(name[0 .. $ - "-256color".length]~"-88color", addTrueColor, true);
            }
            if (endsWith(name, "-88color"))
            {
                return get(name[0..$-"-88color".length]~"-color", addTrueColor, add256Color);
            }
            if (endsWith(name, "-color"))
            {
                return get(name[0..$-"-color".length], addTrueColor, add256Color);
            }
            return null;
        }

        auto colorTerm = environment["COLORTERM"];
        auto tc = new Termcap;

        // poor mans copy, but we have to bypass the const,
        // although we're not going to change actual values.
        // we promise not to modify the aliases array.
        *tc = *(cast(Termcap *)(entries[name]));

        if (tc.truecolor || canFind(colorTerm, "truecolor") ||
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
            if (tc.colors < 256)
            {
                add256Color = true;
            }
        }

        if (add256Color)
        {
            tc.colors = 256;
            tc.setFg = "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m";
            tc.setBg = "\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m";
            tc.setFgBg = "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;;" ~
                "%?%p2%{8}%<%t4%p2%d%e%p2%{16}%<%t10%p2%{8}%-%d%e48;5;%p2%d%;m";
            tc.resetColors = "\x1b[39;49m";
        }

        return tc;
    }
}

unittest
{
    Termcap caps;
    caps.name = "mytest";
    caps.aliases = ["mytest-1", "mytest-2"];

    Database.put(&caps);

    assert(Database.get("nosuch") is null);
    auto tc = Database.get("mytest");
    assert((tc !is null) && tc.name == "mytest");
    assert(Database.get("mytest-1") !is null);
    assert(Database.get("mytest-2") !is null);

    environment["COLORTERM"] = "truecolor";
    tc = Database.get("mytest-truecolor");
    assert(tc !is null);
    assert(tc.colors == 256);
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

    caps.truecolor = true;
    caps.aliases = [];
    caps.name = "ctest";
    Database.put(&caps);
    tc = Database.get("ctest");
    assert(tc !is null);
    assert(tc.colors == 256);
    assert(tc.setFgBgRGB != "");
    assert(tc.setFg != "");
    assert(tc.resetColors != "");

    auto ti = new Terminfo(tc);
    assert(ti !is null);
    assert(ti.caps.colors == 256);
    assert(ti.caps.setFgBgRGB != "");
    assert(ti.caps.setFg != "");
    assert(ti.caps.resetColors != "");
}
