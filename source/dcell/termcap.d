/**
 * Termcap module for dcell, contains the structure used to define terminal capabilities.
 *
 * Copyright: Copyright 2022 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.termcap;

import core.thread;
import std.conv;
import std.algorithm;
import std.functional;
import std.range;
import std.stdio;
import std.string;

/**
 * Represents the actual capabilities - this is an entry in a terminfo
 * database.
 */
struct Termcap
{
    string name; /// primary name for terminal, e.g. "xterm"
    immutable(string)[] aliases; /// alternate names for terminal
    int columns; /// `cols`, the number of columns present
    int lines; /// `lines`, the number lines (rows) present
    int colors; // `colors`, the number of colors supported
    string bell; /// `bell`, the sequence to ring a bell
    string clear; /// `clear`, the sequence to clear the screen
    string enterCA; /// `smcup`, sequence to enter cursor addressing mode
    string exitCA; /// `rmcup`, sequence to exit cursor addressing mode
    string showCursor; /// `cnorm`, should display the normal cursor
    string hideCursor; /// `civis`, mark the cursor invisible
    string attrOff; /// `sgr0`, turn off all text attributes and colors
    string underline; /// `smul`, starts underlining
    string bold; /// `bold`, starts bold (maybe intense or double-strike)
    string blink; /// `blink`, starts blinking text
    string reverse; /// `rev`, inverts the foreground and background colors
    string dim; /// `dim`, reduces the intensity of text
    string italic; /// `sitm`, starts italics mode (not widely supported)
    string enterKeypad; /// `smkx`, enables keypad mode
    string exitKeypad; /// `rmkx`, leaves keypad mode
    string setFg; /// `setaf`, sets foreground text color (indexed)
    string setBg; /// `setab`, sets background text color (indexed)
    string resetColors; /// `op`, sets foreground and background to default
    string setCursor; /// `cup`, sets cursor location to row and column
    string cursorBack1; /// `cub1`, move cursor backwards one
    string cursorUp1; /// `cuu1`, mover cursor up one line
    string padChar; /// `pad`, padding character, if non-empty enables padding delays
    string insertChar; /// `ich1`, insert a character, used for inserting at bottom right for automargin terminals
    string keyBackspace; /// `kbs`, backspace key
    string keyF1; // kf1
    string keyF2; // kf2
    string keyF3; // kf3
    string keyF4; // kf4
    string keyF5; // kf5
    string keyF6; // kf6
    string keyF7; // kf7
    string keyF8; // kf8
    string keyF9; // kf9
    string keyF10; // kf10
    string keyF11; // kf11
    string keyF12; // kf12
    string keyF13; // kf13
    string keyF14; // kf14
    string keyF15; // kf15
    string keyF16; // kf16
    string keyF17; // kf17
    string keyF18; // kf18
    string keyF19; // kf19
    string keyF20; // kf20
    string keyF21; // kf21
    string keyF22; // kf22
    string keyF23; // kf23
    string keyF24; // kf24
    string keyF25; // kf25
    string keyF26; // kf26
    string keyF27; // kf27
    string keyF28; // kf28
    string keyF29; // kf29
    string keyF30; // kf30
    string keyF31; // kf31
    string keyF32; // kf32
    string keyF33; // kf33
    string keyF34; // kf34
    string keyF35; // kf35
    string keyF36; // kf36
    string keyF37; // kf37
    string keyF38; // kf38
    string keyF39; // kf39
    string keyF40; // kf40
    string keyF41; // kf41
    string keyF42; // kf42
    string keyF43; // kf43
    string keyF44; // kf44
    string keyF45; // kf45
    string keyF46; // kf46
    string keyF47; // kf47
    string keyF48; // kf48
    string keyF49; // kf49
    string keyF50; // kf50
    string keyF51; // kf51
    string keyF52; // kf52
    string keyF53; // kf53
    string keyF54; // kf54
    string keyF55; // kf55
    string keyF56; // kf56
    string keyF57; // kf57
    string keyF58; // kf58
    string keyF59; // kf59
    string keyF60; // kf60
    string keyF61; // kf61
    string keyF62; // kf62
    string keyF63; // kf63
    string keyF64; // kf64
    string keyInsert; // kich1
    string keyDelete; // kdch1
    string keyHome; // khome
    string keyEnd; // kend
    string keyHelp; // khlp
    string keyPgUp; // kpp
    string keyPgDn; // knp
    string keyUp; // kcuu1
    string keyDown; // kcud1
    string keyLeft; // kcub1
    string keyRight; // kcuf1
    string keyBacktab; // kcbt
    string keyExit; // kext
    string keyClear; // kclr
    string keyPrint; // kprt
    string keyCancel; // kcan
    string mouse; /// `kmouse`, indicates support for mouse mode - XTerm style sequences are assumed
    string altChars; /// `acsc`, alternate characters, used for non-ASCII characters with certain legacy terminals
    string enterACS; /// `smacs`, sequence to switch to alternate character set
    string exitACS; /// `rmacs`, sequence to return to normal character set
    string enableACS; /// `enacs`, sequence to enable alternate character set support
    string keyShfRight; // kRIT
    string keyShfLeft; // kLFT
    string keyShfHome; // kHOM
    string keyShfEnd; // kEND
    string keyShfInsert; // kIC
    string keyShfDelete; // kDC
    bool automargin; /// `am`, if true cursor wraps and advances to next row after last column

    // Non-standard additions to terminfo.  YMMV.
    string strikethrough; // smxx
    string setFgBg; /// sequence to set both foreground and background together, using indexed colors
    string setFgBgRGB; /// sequence to set both foreground and background together, using RGB colors
    string setFgRGB; /// sequence to set foreground color to RGB value
    string setBgRGB; /// sequence to set background color RGB value
    string keyShfUp;
    string keyShfDown;
    string keyShfPgUp;
    string keyShfPgDn;
    string keyCtrlUp;
    string keyCtrlDown;
    string keyCtrlRight;
    string keyCtrlLeft;
    string keyMetaUp;
    string keyMetaDown;
    string keyMetaRight;
    string keyMetaLeft;
    string keyAltUp;
    string keyAltDown;
    string keyAltRight;
    string keyAltLeft;
    string keyCtrlHome;
    string keyCtrlEnd;
    string keyMetaHome;
    string keyMetaEnd;
    string keyAltHome;
    string keyAltEnd;
    string keyAltShfUp;
    string keyAltShfDown;
    string keyAltShfLeft;
    string keyAltShfRight;
    string keyMetaShfUp;
    string keyMetaShfDown;
    string keyMetaShfLeft;
    string keyMetaShfRight;
    string keyCtrlShfUp;
    string keyCtrlShfDown;
    string keyCtrlShfLeft;
    string keyCtrlShfRight;
    string keyCtrlShfHome;
    string keyCtrlShfEnd;
    string keyAltShfHome;
    string keyAltShfEnd;
    string keyMetaShfHome;
    string keyMetaShfEnd;
    string enablePaste; /// sequence to enable delimited paste mode
    string disablePaste; /// sequence to disable delimited paste mode
    string pasteStart; /// sequence sent by terminal to indicate start of a paste buffer
    string pasteEnd; /// sequence sent by terminal to indicated end of a paste buffer
    string cursorReset; /// sequence to reset the cursor shape to default
    string cursorBlock; /// sequence to change the cursor to a solid block
    string cursorUnderline; /// sequence to change the cursor to a steady underscore
    string cursorBar; /// sequence to change the cursor to a steady vertical bar
    string cursorBlinkingBlock; /// sequence to change the cursor to a blinking block
    string cursorBlinkingUnderline; /// sequence to change the cursor to a blinking underscore
    string cursorBlinkingBar; /// sequence to change the cursor to a blinking vertical bar
    string enterURL; /// sequence to start making text a clickable link
    string exitURL; /// sequence to stop making text clickable link
    string setWindowSize; /// sequence to resize the window (rarely supported)

    /** Permits a constant value to be assigned to a mutable value. */
    void opAssign(scope const(Termcap)* other) @trusted
    {
        foreach (i, ref v; this.tupleof)
        {
            v = other.tupleof[i];
        }
    }

    /**
     * Put a string to an out range, which is normally a file
     * to an interactive terminal like /dev/tty or stdin, while
     * interpreting embedded delay sequences of the form
     * $<DELAY> (where DELAY is given in milliseconds, and must
     * be a positive rational number of milliseconds).  However,
     * we no longer need to delay as no terminal actually needs
     * this (sorry ancient physical vt100 terminals), so we drop it.
     */
    static void puts(R)(R output, string s, void delegate() flush = null)
            if (isOutputRange!(R, ubyte))
    {
        while (s.length > 0)
        {
            auto beg = indexOf(s, "$<");
            if (beg == -1)
            {
                cast(void) copy(s, output);
                return;
            }
            cast(void) copy(s[0 .. beg], output);
            s = s[beg .. $];
            auto end = indexOf(s, ">");
            if (end < 0)
            {
                // unterminated escape, emit it as is
                cast(void) copy(s, output);
                return;
            }
            auto val = s[2 .. end];
            s = s[end + 1 .. $];
            int usec = 0;
            int mult = 1000; // 1 ms
            bool dot = false;
            bool valid = true;

            while (valid && val.length > 0)
            {
                switch (val[0])
                {
                case '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
                    usec *= 10;
                    usec += val[0] - '0';
                    if (dot && mult > 1)
                    {
                        mult /= 10;
                    }
                    break;

                case '.':
                    if (!dot)
                    {
                        dot = true;
                    }
                    else
                    {
                        valid = false;
                    }
                    break;

                default:
                    valid = false;
                    break;
                }
                val = val[1 .. $];
            }
        }
    }

    unittest
    {
        import std.datetime : Clock;
        import core.time : seconds;
        import std.outbuffer;

        auto now = Clock.currTime();
        auto ob = new OutBuffer();

        puts(ob, "AB$<1000>C");
        puts(ob, "DEF$<100.5>\n");

        assert(ob.toString() == "ABCDEF\n");
        // negative tests -- we don't care what's in the file (UB), but it must not panic
        puts(ob, "Z$<123..0123>"); // malformed dots
        puts(ob, "LMN$<12X>"); // invalid number
        puts(ob, "GHI$<123JKL"); // unterminated delay
    }

    unittest
    {
        import std.datetime;
        import std.outbuffer;

        auto now = Clock.currTime();
        auto ob = new OutBuffer();

        puts(ob, "AB$<100>C");
        puts(ob, "DEF$<100.5>\n");
        auto end = Clock.currTime();

        assert(ob.toString() == "ABCDEF\n");
    }

    unittest
    {
        import std.outbuffer;
        import std.datetime;

        class Flusher : OutBuffer
        {
            private int flushes = 0;
            void flush()
            {
                flushes++;
            }
        }

        auto f = new Flusher();
        puts(f, "ABC$<100>DEF", &f.flush);
        auto end = Clock.currTime();
        assert(f.toString() == "ABCDEF");
    }

    unittest
    {
        import std.range;

        auto o = nullSink();
        puts(o, "Z$<123..0123>"); // malformed dots
        puts(o, "LMN$<12X>"); // invalid number
        puts(o, "GHI$<123JKL"); // unterminated delay
    }

    private struct Parameter
    {
        int i;
        string s;
    }

    /**
     * Evaluates a terminal capability string and expands it, using the supplied integer parameters.
     *
     * Params:
     *   s = A terminal capability string.  The actual string, not the name of the capability.
     *   args = A list of parameters for the capability.
     *
     *  Returns:
     *    The evaluated capability with parameters applied.
     */

    static string param(string s, int[] args...) pure @safe
    {
        Parameter[] ps = new Parameter[args.length];
        foreach (i, val; args)
        {
            ps[i].i = val;
        }
        return paramInner(s, ps);
    }

    static string param(string s, string[] args...) pure @safe
    {
        Parameter[] ps = new Parameter[args.length];
        foreach (i, val; args)
        {
            ps[i].s = val;
        }
        return paramInner(s, ps);
    }

    static string param(string s) pure @safe
    {
        return paramInner(s, []);
    }

    private static paramInner(string s, Parameter[] params) pure @safe
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

    @safe unittest
    {
        assert(param("%i%p1%d;%p2%d", 2, 3) == "3;4"); // increment (goto)
        assert(param("%{50}%{3}%-%d") == "47"); // subtraction
        assert(param("%{50}%{5}%/%d") == "10"); // division
        assert(param("%p1%p2%/%d", 50, 3) == "16"); // division with truncation
        assert(param("%p1%p2%/%d", 5, 0) == "0"); // division by zero
        assert(param("%{50}%{3}%m%d") == "2"); // modulo
        assert(param("%p1%p2%m%d", 5, 0) == "0"); // modulo (division by zero)
        assert(param("%{4}%{25}%*%d") == "100"); // multiplication
        assert(param("%p1%l%d", "four") == "4"); // strlen
        assert(param("%p1%p2%=%d", 2, 2) == "1"); // equal
        assert(param("%p1%p2%=%d", 2, 3) == "0"); // equal (false)
        assert(param("%?%p1%p2%<%ttrue%efalse%;", 7, 8) == "true"); // NB: push/pop reverses order
        assert(param("%?%p1%p2%>%ttrue%efalse%;", 7, 8) == "false"); // NB: push/pop reverses order
        assert(param("x%p1%cx", 65) == "xAx"); // emit using %c, 'A' == 65 (ASCII)
        assert(param("x%'a'%p1%+%cx", 1) == "xbx"); // literal character encodes ASCII value
        assert(param("x%%x") == "x%x"); // literal % character
        assert(param("%_") == "%_"); // unrecognized sequence
        assert(param("%p2%d") == "0"); // invalid parameter, evaluates to zero (undefined behavior)
        assert(param("%p1%Pgx%gg%gg%dx%c", 65) == "x65xA"); // saved variables (dynamic)
        assert(param("%p1%PZx%gZ%d%gZ%dx", 789) == "x789789x"); // saved variables (static)
        assert(param("%gB%d") == "0"); // saved values are zero if not changed
        assert(param("%p1%Ph%p2%gh%+%Ph%p3%gh%*%d", 1, 2, 5) == "15"); // overwrite saved values
        assert(param("%p1%p2%&%d", 3, 10) == "2");
        assert(param("%p1%p2%|%d", 3, 10) == "11");
        assert(param("%p1%p2%^%d", 3, 10) == "9");
        assert(param("%p1%~%p2%&%d", 2, 0xff) == "253"); // bit complement, but mask it down
        assert(param("%p1%p2%<%p2%p3%<%A%d", 1, 2, 3) == "1"); // AND
        assert(param("%p1%p2%<%p2%p3%<%A%d", 1, 3, 2) == "0"); // AND false
        assert(param("%p1%p2%<%p2%p3%<%!%A%d", 1, 3, 2) == "1"); // NOT (and)
        assert(param("%p1%p2%<%p1%p2%=%O%d", 1, 1) == "1"); // OR
        assert(param("%p1[%s]", "garrett") == "[garrett]"); // string parameteter
    }
}
