// Copyright 2025 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

/**
 * This module implements a command to extra terminfo data from the system,
 * and build a database of Termcap data for use by this library.
 */
module mkinfo;

import std.algorithm : findSplit;
import std.stdio;
import std.process : execute;
import std.string;
import std.conv : to;
import std.outbuffer;
import std.traits;
import std.conv;

import dcell.termcap;
import dcell.database;

/**
 * Caps represents a "parsed" terminfo entry, before it is converted into
 * a Termcap structure.
 */
private struct Caps
{
    string name;
    string desc;
    string[] aliases;
    bool[string] bools;
    int[string] ints;
    string[string] strs;

    int getInt(string s)
    {
        return (s in ints ? ints[s] : 0);
    }

    bool getBool(string s)
    {
        return (s in bools) !is null;
    }

    string getStr(string s)
    {
        return (s in strs ? strs[s] : "");
    }
}

/**
 * Unescape string data emitted by infocmp(1) into binary representations
 * suitable for use by this library.  This understands C style escape
 * sequences such as \n, but also octal sequences.  A lone \0 is understood
 * to represent a special form of NULL.  See terminfo(5) for more information.
 */
private string unescape(string s)
{
    enum escape
    {
        none,
        ctrl,
        esc
    }

    string result;

    escape state = escape.none;

    while (s.length > 0)
    {
        auto c = s[0];
        s = s[1 .. $];
        final switch (state)
        {
        case escape.none:
            switch (c)
            {
            case '\\':
                state = escape.esc;
                break;
            case '^':
                state = escape.ctrl;
                break;
            default:
                result ~= c;
                break;
            }
            break;
        case escape.ctrl:
            result ~= (c ^ (1 << 6)); // flip bit six
            state = escape.none;
            break;
        case escape.esc:
            switch (c)
            {
            case 'E', 'e':
                result ~= '\x1b';
                break;
            case '0', '1', '2', '3', '4', '5', '6', '7':
                if (s.length >= 2 && s[0] >= '0' && s[0] <= '7' && s[1] >= '0' && s[1] <= '7')
                {
                    result ~= ((c - '0') << 6) + ((s[0] - '0') << 3) + (s[1] - '0');
                    s = s[2 .. $];
                }
                else if (c == '0')
                {
                    result ~= '\200';
                }
                break;
            case 'n':
                result ~= '\n';
                break;
            case 'r':
                result ~= '\r';
                break;
            case 't':
                result ~= '\t';
                break;
            case 'b':
                result ~= '\b';
                break;
            case 'f':
                result ~= '\f';
                break;
            case 's':
                result ~= ' ';
                break;
            case 'l':
                result ~= '\n';
                break;
            default:
                result ~= c;
                break;
            }
            state = escape.none;
            break;
        }
    }
    return result;
}

unittest
{
    assert(unescape("123") == "123");
    assert(unescape(`1\n2`) == "1\n2");
    assert(unescape("a^Gb") == "a\007b");
    assert(unescape("1\\_\\007") == "1_\007");
    assert(unescape(`\,\:\0`) == ",:\200");
    assert(unescape(`\e\E`) == "\x1b\x1b");
    assert(unescape(`\r\s\f\l\t\b`) == "\r \f\n\t\b");
}

/**
 * Load capabilities (parsed from infocmp -1 -x).
 *
 * Params: info = output from infocmp -1 -x
 * Returns:
 *   parsed capabilities on success, null otherwise
 */
Caps* parseCaps(string info)
{
    auto cap = new Caps;
    auto first = true;
    foreach (line; splitLines(info))
    {
        // skip empty lines and comments
        if (line.length == 0 || line[0] == '#')
        {
            continue;
        }
        if (first)
        {
            // first line is name|alias|alias...|description
            auto parts = split(line, '|');
            cap.name = parts[0];
            if (parts.length > 1)
            {
                cap.desc = parts[$ - 1];
                cap.aliases = parts[1 .. $ - 1];
            }
            first = false;
            continue;
        }
        if (line[0] != '\t' || line[$ - 1] != ',')
        {
            // this is malformed, but ignore it
            continue;
        }
        line = line[1 .. $ - 1];

        // we can try to split the string across an equals sign.
        // this is guaranteed to be safe even if there are escaped
        // equals signs, because those can only appear *after* a bare
        // one (for a string capability)
        auto nvp = findSplit(line, "=");
        if (nvp[1] == "=")
        {
            // this is a string capability
            cap.strs[nvp[0]] = unescape(nvp[2]);
            continue;

        }
        nvp = findSplit(line, "#");
        if (nvp[1] == "#")
        {
            // numeric capability
            cap.ints[nvp[0]] = to!int(nvp[2]);
            continue;
        }
        // boolean capability
        cap.bools[nvp[0]] = true;
    }
    if (cap.name == "")
    {
        return null;
    }
    return cap;
}

unittest
{
    assert(parseCaps("\n") is null);
    assert(parseCaps("#junk") is null);
    auto c = parseCaps("myterm|something\n\tam,\n\tcup=123\\t345,\n\tcolor#4,\n\n");
    assert(c !is null);
    assert(c.bools["am"] == true);
    assert(c.ints["color"] == 4);
    assert(c.strs["cup"] == "123\t345");
}

Caps* loadCaps(string name)
{
    auto info = execute(["infocmp", "-x", "-1", name]);
    if (info.status != 0)
    {
        return null;
    }
    return (parseCaps(info.output));
}

private string escape(string s)
{
    string result = "";
    foreach (char c; s)
    {
        switch (c)
        {
        case '\t':
            result ~= `\t`;
            break;
        case '\n':
            result ~= `\n`;
            break;
        case '\r':
            result ~= `\r`;
            break;
        case '\'', '"', '\\':
            result ~= "\\";
            result ~= c;
            break;
        default:
            if (c < ' ')
            {
                result ~= format("\\x%02x", c);
            }
            else
            {
                result ~= c;
            }
            break;
        }
    }
    return result;
}

unittest
{
    assert(escape(`a'b`) == `a\'b`);
    assert(escape(`a\b`) == `a\\b`);
    assert(escape(`a"b`) == `a\"b`);
    assert(escape("a\nb") == `a\nb`);
    assert(escape("a\tb") == `a\tb`);
    assert(escape("a\rb") == `a\rb`);
    assert(escape("a\x1bb") == `a\x1bb`);
}

Termcap* getTermcap(string name)
{
    auto caps = loadCaps(name);
    if (caps == null)
    {
        return null;
    }
    return convertCaps(caps);
}

private Termcap* convertCaps(Caps* caps)
{
    auto tc = new Termcap;
    tc.name = caps.name;
    tc.aliases = cast(immutable(string)[]) caps.aliases;
    tc.colors = caps.getInt("colors");
    tc.columns = caps.getInt("columns");
    tc.lines = caps.getInt("lines");
    tc.bell = caps.getStr("bel");
    tc.clear = caps.getStr("clear");
    tc.enterCA = caps.getStr("smcup");
    tc.exitCA = caps.getStr("rmcup");

    tc.showCursor = caps.getStr("cnorm");
    tc.hideCursor = caps.getStr("civis");
    tc.attrOff = caps.getStr("sgr0");
    tc.underline = caps.getStr("smul");
    tc.bold = caps.getStr("bold");
    tc.blink = caps.getStr("blink");
    tc.dim = caps.getStr("dim");
    tc.italic = caps.getStr("sitm");
    tc.reverse = caps.getStr("rev");
    tc.enterKeypad = caps.getStr("smkx");
    tc.exitKeypad = caps.getStr("rmkx");
    tc.setFg = caps.getStr("setaf");
    tc.setBg = caps.getStr("setab");
    tc.resetColors = caps.getStr("op");
    tc.setCursor = caps.getStr("cup");
    tc.cursorBack1 = caps.getStr("cub1");
    tc.cursorUp1 = caps.getStr("cuu1");
    tc.insertChar = caps.getStr("ich1");
    tc.automargin = caps.getBool("am");
    tc.altChars = caps.getStr("acsc");
    tc.enterACS = caps.getStr("smacs");
    tc.exitACS = caps.getStr("rmacs");
    tc.enableACS = caps.getStr("enacs");
    tc.strikethrough = caps.getStr("smxx");
    tc.mouse = caps.getStr("kmous");

    // Technically the RGB flag that is provided for xterm-direct is not
    // quite right.  The problem is that the -direct flag that was introduced
    // with ncurses 6.1 requires a parsing for the parameters that we lack.
    // For this case we'll just assume it's XTerm compatible.  Someday this
    // may be incorrect, but right now it is correct, and nobody uses it
    // anyway.
    if (caps.getBool("Tc"))
    {
        // This presumes XTerm 24-bit true color.
        tc.colors = 1 << 24;
    }
    else if (caps.getBool("RGB"))
    {
        // This is for xterm-direct, which uses a different scheme entirely.
        // (ncurses went a very different direction from everyone else, and
        // so it's unlikely anything is using this definition.)
        tc.colors = 1 < 24;
        tc.setBg = "\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m";
        tc.setFg = "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m";
    }

    // We only support colors in ANSI 8 or 256 color mode.
    if (tc.colors < 8 || tc.setFg == "")
    {
        tc.colors = 0;
    }
    if (tc.setCursor == "")
    {
        return null; // terminal is not addressable
    }

    return tc;
}

unittest
{
    assert(getTermcap("nosuch") is null);
    auto tc = getTermcap("xterm-256color");
    assert(tc !is null);
    tc = getTermcap("vt100");
    tc = getTermcap("rxvt");
}

// there might be better ways to do this

OutBuffer mkTermSource(Termcap*[] tcs, string modname)
{
    auto ob = new OutBuffer;

    ob.writefln("// Generated automatically.  DO NOT HAND-EDIT.");
    ob.writefln("");
    ob.writefln("module %s;", modname);
    ob.writefln("");
    ob.writefln("import dcell.database;");

    void addInt(string n, int i)
    {
        if (i != 0)
        {
            ob.writefln("    %s: %d,", n, i);
        }
    }

    void addStr(string n, string s)
    {
        if (s != "")
        {
            ob.writefln("    %s: \"%s\",", n, escape(s));
        }
    }

    void addBool(string n, bool b)
    {
        if (b)
        {
            ob.writefln("    %s: true,", n);
        }
    }

    void addArr(string n, string[] a)
    {
        if (a.length > 0)
        {
            ob.writef("    %s: [", n);
            foreach (i, string s; a)
            {
                if (i > 0)
                {
                    ob.writef(", ");
                }
                ob.writef(`"%s"`, escape(s));
            }
            ob.writefln("],");
        }
    }

    foreach (num, Termcap* tc; tcs)
    {
        ob.writefln("");
        ob.writefln("// %s", tc.name);
        ob.writefln("static immutable Termcap term%d = {", num);

        auto names = FieldNameTuple!Termcap;
        foreach (int i, ref x; tc.tupleof)
        {
            auto n = names[i];

            static if (is(typeof(x) == int))
            {
                addInt(n, x);
            }
            static if (is(typeof(x) == string))
            {
                addStr(n, x);
            }
            static if (is(typeof(x) == bool))
            {
                addBool(n, x);
            }
            static if (is(typeof(x) == string[]))
            {
                addArr(n, x);
            }
        }

        ob.writefln("};");
    }
    ob.writefln("");
    ob.writefln("static this()");
    ob.writefln("{");
    foreach (num, _; tcs)
    {
        ob.writefln("    Database.put(&term%d);", num);
    }
    ob.writefln("}");
    return ob;
}

unittest
{
    assert(getTermcap("nosuch") is null);
    auto tc = getTermcap("xterm-256color");
    assert(tc !is null);
    auto ob = mkTermSource([tc], "dcell.terminfo.xterm256color");
}

void main(string[] args)
{
    import core.stdc.stdlib;
    import std.getopt;
    import std.path;
    import std.process;

    string[] terms;
    string directory = ".";

    auto help = getopt(args, "directory", &directory);
    if (help.helpWanted)
    {
        defaultGetoptFormatter(stderr.lockingTextWriter(),
            "Emit terminal database", help.options);
        exit(1);
    }
    args = args[1 .. $];
    if (args.length != 0)
    {
        terms = args;
    }
    else
    {
        terms ~= environment.get("TERM", "ansi");
    }
    foreach (index, string name; terms)
    {
        Termcap*[] tcs;
        auto tc = getTermcap(name);
        if (tc is null)
        {
            throw new Exception("failed to get term for " ~ name);
        }
        tcs ~= tc;

        // look for common variants
        foreach (unused, suffix; [
                "16color", "88color", "256color", "truecolor", "direct"
            ])
        {
            tc = getTermcap(name ~ "-" ~ suffix);
            if (tc !is null)
            {
                tcs ~= tc;
            }
        }

        string pkg;
        pkg = replace(name, "-", "");
        pkg = replace(pkg, ".", "");
        auto ob = mkTermSource(tcs, "dcell.terminfo." ~ pkg);
        import std.file;

        auto autof = chainPath(directory, pkg ~ ".d");
        write(autof, ob.toString());
    }
}
