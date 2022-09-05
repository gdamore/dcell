// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.terminfo.terminal;

version(junk):
import core.thread;
import std.algorithm;
import std.conv;
import std.functional;
import std.process : environment;
import std.range;
import std.stdio;
import std.string;

import dcell.terminfo.termcap;
import dcell.terminfo.database;

/**
 * Terminfo represents the terminal strings and capabilities for a
 * TTY based terminal.  The list of possible entries is not complete,
 * as we only provide entries we have a meaningful use for.
*/
class XTerminfo
{
    const(Termcap)* caps;
    private struct Parameter
    {
        int i;
        string s;
    }


    /** 
     * Construct a Terminfo using the given capabilities.
     *
     * Params: 
     *   tc = capabilities for this terminal
     */
    this(const(Termcap)* tc)
    {
        caps = tc;
    }

    this(XTerminfo src)
    {
        caps = src.caps;
    }

    /**
    Evalutes a terminal capability string and expands it, using the supplied string paramters.

    Params:
        s    = A terminal capability string.  The actual string, not the name of the capability.
        strs = A list of string parameters for the capability.

    Returns:
        The evaluated capability with parameters applied.
    */
    string tParmString(string s, string[] strs...)
    {
        Parameter[] params;
        foreach (string v; strs)
        {
            Parameter p;
            p.s = v;
            params ~= p;
        }
        return tParmInner(s, params);
    }

    /++
        Evaluates a terminal capability string and expands it, using the supplied integer parameters.

        Params: 
            s    = A terminal capability string.  The actual string, not the name of the capability.
            ints = A list of integer parameters for the capability.

        Returns:
            The evaluated capability with parameters applied.
     +/
    string tParm(string s, int[] ints...)
    {
        Parameter[] params;
        foreach (int i; ints)
        {
            Parameter p;
            p.i = i;
            params ~= p;
        }
        return tParmInner(s, params);
    }

    private string tParmInner(string s, Parameter[] params)
    {
        enum Skip
        {
            emit,
            toElse,
            toEnd
        }

        char[] input;
        char[] output;
        Parameter[byte] saved;
        Parameter[] stack;
        Skip skip;

        input = s.dup;

        void push(Parameter p)
        {
            stack ~= p;
        }

        void pushInt(int i)
        {
            Parameter p;
            p.i = i;
            push(p);
        }

        // pop a parameter from the stack.
        // If the stack is empty, returns a zero value Parameter.
        Parameter pop()
        {
            Parameter p;
            if (stack.length > 0)
            {
                p = stack[$ - 1];
                stack = stack[0 .. $ - 1];
            }
            return p;
        }

        int popInt()
        {
            return pop().i;
        }

        string popStr()
        {
            return pop().s;
        }

        char nextCh()
        {
            char ch;
            if (input.length > 0)
            {
                ch = input[0];
                input = input[1 .. $];
            }
            return (ch);
        }

        // We do not currently support the printf style formats.
        // We are not aware of any use by such formats in any real-world
        // terminfo descriptions.

        while (input.length > 0)
        {
            Parameter p;
            int i1, i2;

            // In some cases we need to pop both parameters
            // into local variables before evaluating.  This is required
            // to ensure both pops are evaluated in a specific order.
            // In some cases the order of a binary operation is not important
            // and then we can write it as push(pop op pop).  Also, it turns out
            // that the right most parameter is pushed first, and the left most last.
            // So for example, the divisor is pushed before the numerator.  This
            // seems somewhat counterintuitive, but it is the current behavior of ncurses.

            auto ch = nextCh();

            if (ch != '%')
            {
                if (skip == Skip.emit)
                {
                    output ~= ch;
                }
                continue;
            }

            ch = nextCh();

            if (skip == skip.toElse)
            {
                if (ch == 'e' || ch == ';')
                {
                    skip = Skip.emit;
                }
                continue;
            }
            else if (skip == skip.toEnd)
            {
                if (ch == ';')
                {
                    skip = Skip.emit;
                }
                continue;
            }

            switch (ch)
            {
            case '%': // literal %
                output ~= ch;
                break;

            case 'i': // increment both parameters (ANSI cup support)
                if (params.length >= 2)
                {
                    params[0].i++;
                    params[1].i++;
                }
                break;

            case 'c': // integer as character
                output ~= cast(byte) popInt();
                break;

            case 's': // character or string
                output ~= popStr();
                break;

            case 'd': // decimal value
                output ~= to!string(popInt());
                break;

            case 'p': // push i'th parameter (could be string or integer)
                ch = nextCh();
                if (ch >= '1' && (ch - '1') < params.length)
                {
                    push(params[ch - '1']);
                }
                else
                {
                    pushInt(0);
                }
                break;

            case 'P': // pop and store
                ch = nextCh();
                if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z'))
                {
                    saved[ch] = pop();
                }
                break;

            case 'g': // recall and push
                ch = nextCh();
                if (ch in saved)
                {
                    push(saved[ch]);
                }
                else
                {
                    pushInt(0);
                }
                break;

            case '\'': // push a character (will be of form %'c')
                ch = nextCh();
                pushInt(cast(byte) ch);
                nextCh(); // consume the closing '
                break;

            case '{': // push integer, terminated by '}'
                i1 = 0;
                ch = nextCh();
                while ((ch >= '0') && (ch <= '9'))
                {
                    i1 *= 10;
                    i1 += ch - '0';
                    ch = nextCh();
                }
                pushInt(i1);
                break;

            case 'l': // push(strlen(pop))
                pushInt(cast(int) popStr().length);
                break;

            case '+': // pop two parameters, add the result
                pushInt(popInt() + popInt());
                break;

            case '-':
                i1 = popInt();
                i2 = popInt();
                pushInt(i2 - i1);
                break;

            case '*':
                pushInt(popInt() * popInt());
                break;

            case '/':
                i1 = popInt();
                i2 = popInt();
                if (i1 != 0)
                {
                    pushInt(i2 / i1);
                }
                else
                {
                    pushInt(0);
                }
                break;

            case 'm': // modulo
                i1 = popInt();
                i2 = popInt();
                if (i1 != 0)
                {
                    pushInt(i2 % i1);
                }
                else
                {
                    pushInt(0);
                }
                break;

            case '&': // bitwise AND
                pushInt(popInt() & popInt());
                break;

            case '|': // bitwise OR
                pushInt(popInt() | popInt());
                break;

            case '^': // bitwise XOR
                pushInt(popInt() ^ popInt());
                break;

            case '~': // bit complement
                pushInt(~popInt());
                break;

            case '!': // NOT
                pushInt(!popInt());
                break;

            case 'A': // logical AND
                i1 = popInt(); // pop both (no short circuit evaluation)
                i2 = popInt();
                pushInt(i1 && i2);
                break;

            case 'O': // logical OR
                i1 = popInt(); // pop both
                i2 = popInt();
                pushInt(i1 || i2);
                break;

            case '=': // numeric compare
                pushInt(popInt() == popInt());
                break;

            case '<':
                i1 = popInt();
                i2 = popInt();
                pushInt(i2 < i1);
                break;

            case '>':
                i1 = popInt();
                i2 = popInt();
                pushInt(i2 > i1);
                break;

            case '?': // start of conditional
                break;

            case ';':
                break;

            case 't': // then
                if (!popInt())
                {
                    skip = Skip.toElse;
                }
                break;

            case 'e':
                // We've already processed the true branch of the conditional.
                // We won't process anything more for the rest of the conditional,
                // including any other branches.
                skip = Skip.toEnd;
                break;

            default:
                // Unrecognized sequence, so just emit it.
                output ~= '%';
                output ~= ch;
                break;
            }
        }

        return to!string(output);
    }

        /+
    unittest
    {
        // these are taken from xterm, mostly
        Termcap tc;
        Terminfo ti = new Terminfo(&tc);
        tc.setCursor = "\x1b[%i%p1%d;%p2%dH";
        tc.colors = 256;
        tc.setFg = "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m";
        tc.setBg = "\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m";
        tc.enterURL = "\x1b]8;;%p1%s\x1b\\";
        assert(ti.tParm(tc.setCursor, 3, 4) == "\x1b[4;5H");
        assert(ti.tGoto(3, 4) == "\x1b[5;4H");
        // this does not use combined foreground and background, only separate strings
        assert(ti.tColor(2, 3) == "\x1b[32m\x1b[43m");
        // covers the else clause handling
        assert(ti.tColor(2, 13) == "\x1b[32m\x1b[105m");
        tc.colors = 8;
        assert(ti.tColor(10, 11) == "\x1b[32m\x1b[43m"); // intense colors with just 8 colors
        assert(ti.tParmString(ti.caps.enterURL, "https://www.example.com") == "\x1b]8;;https://www.example.com\x1b\\");
        // tests of operators
        tc.setCursor = "\x1b%p1%p2%+%d;";
        assert(ti.tParm(ti.caps.setCursor, 3, 4) == "\x1b7;");
        tc.setCursor = "\x1b%p1%p2%-%d;";
        assert(ti.tParm(ti.caps.setCursor, 4, 3) == "\x1b1;");
        assert(ti.tParm("%{50}%{3}%-%d") == "47"); // subtraction
        assert(ti.tParm("%{50}%{5}%/%d") == "10"); // division
        assert(ti.tParm("%p1%p2%/%d", 50, 3) == "16"); // division with truncation
        assert(ti.tParm("%p1%p2%/%d", 5, 0) == "0"); // division by zero
        assert(ti.tParm("%{50}%{3}%m%d") == "2"); // modulo
        assert(ti.tParm("%p1%p2%m%d", 5, 0) == "0"); // modulo (division by zero)
        assert(ti.tParm("%{4}%{25}%*%d") == "100"); // multiplication
        assert(ti.tParmString("%p1%l%d", "four") == "4"); // strlen
        assert(ti.tParm("%p1%p2%=%d", 2, 2) == "1"); // equal
        assert(ti.tParm("%p1%p2%=%d", 2, 3) == "0"); // equal (false)
        assert(ti.tParm("%?%p1%p2%<%ttrue%efalse%;", 7, 8) == "true"); // NB: push/pop reverses order
        assert(ti.tParm("%?%p1%p2%>%ttrue%efalse%;", 7, 8) == "false"); // NB: push/pop reverses order
        assert(ti.tParm("x%p1%cx", 65) == "xAx"); // emit using %c, 'A' == 65 (ASCII)
        assert(ti.tParm("x%'a'%p1%+%cx", 1) == "xbx"); // literal character encodes ASCII value
        assert(ti.tParm("x%%x") == "x%x"); // literal % character
        assert(ti.tParm("%_") == "%_"); // unrecognized sequence
        assert(ti.tParm("%p2%d") == "0"); // invalid parameter, evaluates to zero (undefined behavior)
        assert(ti.tParm("%p1%Pgx%gg%gg%dx%c", 65) == "x65xA"); // saved variables (dynamic)
        assert(ti.tParm("%p1%PZx%gZ%d%gZ%dx", 789) == "x789789x"); // saved variables (static)
        assert(ti.tParm("%gB%d") == "0"); // saved values are zero if not changed
        assert(ti.tParm("%p1%Ph%p2%gh%+%Ph%p3%gh%*%d", 1, 2, 5) == "15"); // overwrite saved values
        assert(ti.tParm("%p1%p2%&%d", 3, 10) == "2");
        assert(ti.tParm("%p1%p2%|%d", 3, 10) == "11");
        assert(ti.tParm("%p1%p2%^%d", 3, 10) == "9");
        assert(ti.tParm("%p1%~%p2%&%d", 2, 0xff) == "253"); // bit complement, but mask it down
        assert(ti.tParm("%p1%p2%<%p2%p3%<%A%d", 1, 2, 3) == "1"); // AND
        assert(ti.tParm("%p1%p2%<%p2%p3%<%A%d", 1, 3, 2) == "0"); // AND false
        assert(ti.tParm("%p1%p2%<%p2%p3%<%!%A%d", 1, 3, 2) == "1"); // NOT (and)
        assert(ti.tParm("%p1%p2%<%p1%p2%=%O%d", 1, 1) == "1"); // OR
    }
    +/
}
