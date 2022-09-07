// Copyright 2022 Garrett D'Amore
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
*     parsed capabilities on success, null otherwise
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
    tc.aliases = caps.aliases;
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
    tc.keyF1 = caps.getStr("kf1");
    tc.keyF2 = caps.getStr("kf2");
    tc.keyF3 = caps.getStr("kf3");
    tc.keyF4 = caps.getStr("kf4");
    tc.keyF5 = caps.getStr("kf5");
    tc.keyF6 = caps.getStr("kf6");
    tc.keyF7 = caps.getStr("kf7");
    tc.keyF8 = caps.getStr("kf8");
    tc.keyF9 = caps.getStr("kf9");
    tc.keyF10 = caps.getStr("kf10");
    tc.keyF11 = caps.getStr("kf11");
    tc.keyF12 = caps.getStr("kf12");
    tc.keyInsert = caps.getStr("kich1");
    tc.keyDelete = caps.getStr("kdch1");
    tc.keyBackspace = caps.getStr("kbs");
    tc.keyHome = caps.getStr("khome");
    tc.keyEnd = caps.getStr("kend");
    tc.keyUp = caps.getStr("kcuu1");
    tc.keyDown = caps.getStr("kcud1");
    tc.keyRight = caps.getStr("kcuf1");
    tc.keyLeft = caps.getStr("kcub1");
    tc.keyPgDn = caps.getStr("knp");
    tc.keyPgUp = caps.getStr("kpp");
    tc.keyBacktab = caps.getStr("kcbt");
    tc.keyExit = caps.getStr("kext");
    tc.keyCancel = caps.getStr("kcan");
    tc.keyPrint = caps.getStr("kprt");
    tc.keyHelp = caps.getStr("khlp");
    tc.keyClear = caps.getStr("kclr");
    tc.altChars = caps.getStr("acsc");
    tc.enterACS = caps.getStr("smacs");
    tc.exitACS = caps.getStr("rmacs");
    tc.enableACS = caps.getStr("enacs");
    tc.strikethrough = caps.getStr("smxx");
    tc.mouse = caps.getStr("kmous");

    // Lookup high level function keys.
    tc.keyShfInsert = caps.getStr("kIC");
    tc.keyShfDelete = caps.getStr("kDC");
    tc.keyShfRight = caps.getStr("kRIT");
    tc.keyShfLeft = caps.getStr("kLFT");
    tc.keyShfHome = caps.getStr("kHOM");
    tc.keyShfEnd = caps.getStr("kEND");
    tc.keyF13 = caps.getStr("kf13");
    tc.keyF14 = caps.getStr("kf14");
    tc.keyF15 = caps.getStr("kf15");
    tc.keyF16 = caps.getStr("kf16");
    tc.keyF17 = caps.getStr("kf17");
    tc.keyF18 = caps.getStr("kf18");
    tc.keyF19 = caps.getStr("kf19");
    tc.keyF20 = caps.getStr("kf20");
    tc.keyF21 = caps.getStr("kf21");
    tc.keyF22 = caps.getStr("kf22");
    tc.keyF23 = caps.getStr("kf23");
    tc.keyF24 = caps.getStr("kf24");
    tc.keyF25 = caps.getStr("kf25");
    tc.keyF26 = caps.getStr("kf26");
    tc.keyF27 = caps.getStr("kf27");
    tc.keyF28 = caps.getStr("kf28");
    tc.keyF29 = caps.getStr("kf29");
    tc.keyF30 = caps.getStr("kf30");
    tc.keyF31 = caps.getStr("kf31");
    tc.keyF32 = caps.getStr("kf32");
    tc.keyF33 = caps.getStr("kf33");
    tc.keyF34 = caps.getStr("kf34");
    tc.keyF35 = caps.getStr("kf35");
    tc.keyF36 = caps.getStr("kf36");
    tc.keyF37 = caps.getStr("kf37");
    tc.keyF38 = caps.getStr("kf38");
    tc.keyF39 = caps.getStr("kf39");
    tc.keyF40 = caps.getStr("kf40");
    tc.keyF41 = caps.getStr("kf41");
    tc.keyF42 = caps.getStr("kf42");
    tc.keyF43 = caps.getStr("kf43");
    tc.keyF44 = caps.getStr("kf44");
    tc.keyF45 = caps.getStr("kf45");
    tc.keyF46 = caps.getStr("kf46");
    tc.keyF47 = caps.getStr("kf47");
    tc.keyF48 = caps.getStr("kf48");
    tc.keyF49 = caps.getStr("kf49");
    tc.keyF50 = caps.getStr("kf50");
    tc.keyF51 = caps.getStr("kf51");
    tc.keyF52 = caps.getStr("kf52");
    tc.keyF53 = caps.getStr("kf53");
    tc.keyF54 = caps.getStr("kf54");
    tc.keyF55 = caps.getStr("kf55");
    tc.keyF56 = caps.getStr("kf56");
    tc.keyF57 = caps.getStr("kf57");
    tc.keyF58 = caps.getStr("kf58");
    tc.keyF59 = caps.getStr("kf59");
    tc.keyF60 = caps.getStr("kf60");
    tc.keyF61 = caps.getStr("kf61");
    tc.keyF62 = caps.getStr("kf62");
    tc.keyF63 = caps.getStr("kf63");
    tc.keyF64 = caps.getStr("kf64");

    // And the same thing for rxvt.
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

    // Technically the RGB flag that is provided for xterm-direct is not
    // quite right.  The problem is that the -direct flag that was introduced
    // with ncurses 6.1 requires a parsing for the parameters that we lack.
    // For this case we'll just assume it's XTerm compatible.  Someday this
    // may be incorrect, but right now it is correct, and nobody uses it
    // anyway.
    if (caps.getBool("Tc"))
    {
        // This presumes XTerm 24-bit true color.
        tc.colors = 1<<24;
    }
    else if (caps.getBool("RGB"))
    {
        // This is for xterm-direct, which uses a different scheme entirely.
        // (ncurses went a very different direction from everyone else, and
        // so it's unlikely anything is using this definition.)
        tc.colors = 1<24;
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
    // For padding, we lookup the pad char.  If that isn't present,
    // and npc is *not* set, then we assume a null byte.
    tc.padChar = caps.getStr("pad");
    if (tc.padChar == "")
    {
        if (!caps.getBool("npc"))
        {
            tc.padChar = "\u0000";
        }
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

OutBuffer mkTermSource(Termcap* tc, string modname)
{
    auto ob = new OutBuffer;

    ob.writefln("// Generated automatically.  DO NOT HAND-EDIT.");
    ob.writefln("");
    ob.writefln("module %s;", modname);
    ob.writefln("");
    ob.writefln("import dcell.terminfo.database;");
    ob.writefln("");
    ob.writefln("// %s", tc.name);
    ob.writefln("static immutable Termcap term = {");

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
    ob.writefln("");
    ob.writefln("static this()");
    ob.writefln("{");
    ob.writefln("    Database.add(&term);");
    ob.writefln("}");
    return ob;
}

unittest
{
    assert(getTermcap("nosuch") is null);
    auto tc = getTermcap("xterm-256color");
    assert(tc !is null);
    auto ob = mkTermSource(tc, "gdamore.dcell.terminfo.xterm256color");
    writefln("HERE IT IS\n%s\n", ob.toString());
}

version (unittest)
{
    // when unittest with dub, we don't want a main program
}
else
{
    void main()
    {
        // blah blah
    }
}
