/// Copyright: 2022 Garrett D'Amore
/// License: MIT
module github.gdamore.dcell.terminfo;

import core.thread;
import std.algorithm;
import std.conv;
import std.process : environment;
import std.stdio;
import std.string;

/** 
 * Represents the actual capabilities - this is an entry in a terminfo
 * database.
 */
struct Termcap
{
    string name; /// primary name for terminal, e.g. "xterm"
    string[] aliases; /// alternate names for terminal
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
    bool likeXTerm; /// true if this simulates XTerm, enables extra features
    bool truecolor; /// true if this terminal supports 24-bit (RGB) color
    string cursorDefault; /// sequence to reset the cursor shape to deafult
    string cursorBlinkingBlock; /// sequence to change the cursor to a blinking block
    string cursorSteadyBlock; /// sequence to change the cursor to a solid block
    string cursorBlinkingUnderline; /// sequence to change the cursor to a blinking underscore
    string cursorSteadyUnderline; /// sequence to change the cursor to a steady underscore
    string cursorBlinkingBar; /// sequence to change the cursor to a blinking vertical bar
    string cussorSteadyBar; /// sequence to change the cursor to a steady vertical bar
    string enterURL; /// sequence to start making text a clickable link
    string exitURL; /// sequence to stop making text clickable link
    string setWindowSize; /// sequence to resize the window (rarely supported)
}

/**
Terminfo represents the terminal strings and capabilities for a
TTY based terminal.  The list of possible entries is not complete,
as we only provide entries we have a meaningful use for.
*/
class Terminfo
{
    Termcap caps;
    private struct Parameter
    {
        int i;
        string s;
    }

    /**
    Emits the string, evaluating any inline padding escapes and applying
    delays.  These escapes are of the form $<delay> where delay is a number
    of milliseconds (decimal fractions are permitted).  All output from
    terminfo should be emitted using this function to ensure any embedded
    delays are applied.  (Note that most modern terminals do not need delays.)
    This implementation injects delays using the clock, rather that using
    padding characters, but a padding character must be supplied or the
    delay wil be ignored.

    Params:
        s = string to emit (possibly with delay escapes)
        f = file to write write it to
    */
    void tPuts(string s, File f)
    {
        while (s.length > 0)
        {
            auto beg = indexOf(s, "$<");
            if (beg == -1)
            {
                f.write(s);
                return;
            }
            f.write(s[0 .. beg]); // write the part *before* the time
            s = s[beg .. $];
            auto end = indexOf(s, ">");
            if (end < 0)
            {
                // unterminated escape, emit it as is
                f.write(s);
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

            if (caps.padChar.length > 0 && valid)
            {
                Thread.sleep(usec.usecs * mult);
            }
        }
    }

    unittest
    {
        import std.datetime : Clock;
        import core.time : seconds;

        auto ti = new Terminfo;
        auto tmp = std.stdio.File.tmpfile();
        ti.caps.padChar = " ";
        auto now = Clock.currTime();
        ti.tPuts("AB$<1000>C", tmp);
        ti.tPuts("DEF$<100.5>\n", tmp);
        auto end = Clock.currTime();
        assert(end > now);
        assert(now + seconds(1) <= end);
        assert(now + seconds(2) > end);

        tmp.rewind();
        auto content = tmp.readln();
        assert(content == "ABCDEF\n");
        // negative tests -- we don't care what's in the file (UB), but it must not panic
        ti.tPuts("Z$<123..0123>", tmp); // malformed dots 
        ti.tPuts("LMN$<12X>", tmp); // invalid number
        ti.tPuts("GHI$<123JKL", tmp); // unterminated delay
    }

    /** 
     * Create an empty Terminfo.  This is mostly useless until the caps
     * member is set.
     */
    this()
    {
    }

    /** 
     * Construct a Terminfo using the given capabilities.
     *
     * Params: 
     *   tc = 
     * Returns: 
     */
    this(const(Termcap) *tc)
    {
        caps = *cast(Termcap *)tc;
    }

    this(Terminfo src)
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

    string tGoto(int col, int row)
    {
        return tParm(caps.setCursor, row, col);
    }

    string tColor(int fg, int bg)
    {
        string rv = "";
        if (caps.colors == 8)
        {
            // map 16 colors (4 bits) to 8 (3 bits), colors lose intensity
            if (fg > 7 && fg < 16)
            {
                fg -= 8;
            }
            if (bg > 8 && bg < 16)
            {
                bg -= 8;
            }
        }
        if (caps.colors > fg && fg >= 0)
        {
            rv ~= tParm(caps.setFg, fg);
        }
        if (caps.colors > bg && bg >= 0)
        {
            rv ~= tParm(caps.setBg, bg);
        }
        return rv;
    }

    unittest
    {
        // these are taken from xterm, mostly
        Terminfo ti = new Terminfo;
        ti.caps.setCursor = "\x1b[%i%p1%d;%p2%dH";
        ti.caps.colors = 256;
        ti.caps.setFg = "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m";
        ti.caps.setBg = "\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m";
        ti.caps.enterURL = "\x1b]8;;%p1%s\x1b\\";
        assert(ti.tParm(ti.caps.setCursor, 3, 4) == "\x1b[4;5H");
        assert(ti.tGoto(3, 4) == "\x1b[5;4H");
        // this does not use combined foreground and background, only separate strings
        assert(ti.tColor(2, 3) == "\x1b[32m\x1b[43m");
        // covers the else clause handling
        assert(ti.tColor(2, 13) == "\x1b[32m\x1b[105m");
        ti.caps.colors = 8;
        assert(ti.tColor(10, 11) == "\x1b[32m\x1b[43m"); // intense colors with just 8 colors
        assert(ti.tParmString(ti.caps.enterURL, "https://www.example.com") == "\x1b]8;;https://www.example.com\x1b\\");
        // tests of operators
        ti.caps.setCursor = "\x1b%p1%p2%+%d;";
        assert(ti.tParm(ti.caps.setCursor, 3, 4) == "\x1b7;");
        ti.caps.setCursor = "\x1b%p1%p2%-%d;";
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
}

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

        auto colorTerm = environment.get("COLORTERM");
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
                auto ext = name ~ suffix;
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
    assert(!(ti is null) && ti.caps.name == "mytest");
    // assert(Database.lookup("mytest") == ti);
    // assert(Database.lookup("mytest-1") == ti);
    // assert(Database.lookup("mytest-2") == ti);
}
