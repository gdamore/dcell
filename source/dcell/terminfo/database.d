/// Copyright: 2022 Garrett D'Amore
/// License: MIT
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
    Represents a database of terminal entries, indexed by their name.
*/
synchronized class Database
{
    private static Termcap[string] terms;

    /**
    Adds an entry to the database.
    This should be called by terminal descriptions.

    Params:
        ti = terminal capabilities to add
    */
    static void add(Termcap tc)
    {
        terms[tc.name] = tc;
        foreach (name; tc.aliases)
        {
            terms[name] = tc;
        }
    }

    /**
    Looks up an entry in the database.
    The name is most likely to be taken from the $TERM environment variable.

    Params:
        name = name of the terminal (typically from $TERM)

    Returns:
        terminal entry if known, `null` if not.
    */
    static Terminfo lookup(string name)
    {
        auto addTrueColor = false;
        auto add256Color = false;
        auto valid = false;
        immutable string[] exts = ["-256color", "-88color", "-color", ""];
        string base = "";
        Termcap tc;

        auto colorTerm = environment["COLORTERM"];
        if (canFind(colorTerm, "truecolor") ||
            canFind(colorTerm, "24bit") || canFind(colorTerm, "24-bit"))
        {
            addTrueColor = true;
        }
        if (name in terms)
        {
            valid = true;
            tc = terms[name];
            if (tc.truecolor)
            {
                addTrueColor = true;
            }
        }
        else if (endsWith(name, "-truecolor"))
        {
            base = name[0 .. $ - "-truecolor".length];
            addTrueColor = true;
            add256Color = true;
        }
        else if (endsWith(name, "256color"))
        {
            base = name[0 .. $ - "-256color".length];
            add256Color = true;
        }
        if (!valid && base != "")
        {
            foreach (suffix; exts)
            {
                auto ext = base ~ suffix;
                if (ext in terms)
                {
                    tc = terms[ext];
                    valid = true;
                    break;
                }
            }
        }

        if (!valid)
        {
            return null;
        }

        // NB: tcell has TCELL_TRUECOLOR, but we defer to the value
        // of COLORTERM.  The TCELL_TRUECOLOR thing was created before
        // COLORTERM was widely adopted.

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

        return new Terminfo(&tc);
    }
}

unittest
{
    Termcap caps;
    caps.name = "mytest";
    caps.aliases = ["mytest-1", "mytest-2"];

    Database.add(caps);

    assert(Database.lookup("nosuch") is null);
    auto ti = Database.lookup("mytest");
    assert((ti !is null) && ti.caps.name == "mytest");
    // assert(Database.lookup("mytest") == ti);
    // assert(Database.lookup("mytest-1") == ti);
    // assert(Database.lookup("mytest-2") == ti);

    environment["COLORTERM"] = "truecolor";
    ti = Database.lookup("mytest-truecolor");
    assert(ti !is null);
    assert(ti.caps.colors == 256);
    assert(ti.caps.setFgBgRGB != "");
    assert(ti.caps.setFg != "");
    assert(ti.caps.resetColors != "");

    environment["COLORTERM"] = "";
    ti = Database.lookup("mytest-256color");
    assert(ti !is null);
    assert(ti.caps.colors == 256);
    assert(ti.caps.setFgBgRGB == "");
    assert(ti.caps.setFgBg != "");
    assert(ti.caps.setFg != "");
    assert(ti.caps.resetColors != "");

    caps.truecolor = true;
    caps.aliases = [];
    caps.name = "ctest";
    Database.add(caps);
    ti = Database.lookup("ctest");
    assert(ti !is null);
    assert(ti.caps.colors == 256);
    assert(ti.caps.setFgBgRGB != "");
    assert(ti.caps.setFg != "");
    assert(ti.caps.resetColors != "");

    ti = new Terminfo(ti);
    assert(ti !is null);
    assert(ti.caps.colors == 256);
    assert(ti.caps.setFgBgRGB != "");
    assert(ti.caps.setFg != "");
    assert(ti.caps.resetColors != "");
}
