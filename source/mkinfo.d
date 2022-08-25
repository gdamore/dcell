/** 
 * Copyright: 2022 Garrett D'Amore
 *
 * This module implements a command to extra terminfo data from the system,
 * and build a database of Termcap data for use by this library.
 */
module mkinfo;

import std.stdio;

/**
* Caps represents a "parsed" terminfo entry, before it is converted into
* a Termcap structure.
*/
struct Caps
{
    string name;
    string desc;
    string[] aliases;
    bool[string] bools;
    int[string] ints;
    string[string] strs;
}

/**
* Unescape string data emitted by infocmp(1) into binary representations
* suitable for use by this library.  This understands C style escape
* sequences such as \n, but also octal sequences.  A lone \0 is understood
* to represent a zero byte.
*/
string unescape(string s)
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
