/**
 * Parser module for dcell contains the code for parsing terminfo escapes
 * as they arrive on /dev/tty.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.parser;

import core.time;
import std.algorithm : max;
import std.ascii;
import std.conv : to;
import std.process : environment;
import std.string;
import std.utf : decode, UTFException;

import dcell.event;
import dcell.key;
import dcell.mouse;

package:

struct KeyCode
{
    Key key;
    Modifiers mod;
}

struct CsiKey
{
    char M; // Mode
    int P; // Parameter (first)
}

// Fixed set of keys that are returned as CSI sequences (apart from Csi-U and Csi-_)
// All terminals we support use some of these, and they do not overlap/collide.
immutable KeyCode[CsiKey] csiAllKeys = [
    CsiKey('A'): KeyCode(Key.up),
    CsiKey('B'): KeyCode(Key.down),
    CsiKey('C'): KeyCode(Key.right),
    CsiKey('D'): KeyCode(Key.left),
    CsiKey('F'): KeyCode(Key.end),
    CsiKey('H'): KeyCode(Key.home),
    CsiKey('L'): KeyCode(Key.insert),
    CsiKey('P'): KeyCode(Key.f1),
    CsiKey('Q'): KeyCode(Key.f2),
    CsiKey('S'): KeyCode(Key.f4),
    CsiKey('Z'): KeyCode(Key.backtab),
    CsiKey('a'): KeyCode(Key.up, Modifiers.shift),
    CsiKey('b'): KeyCode(Key.down, Modifiers.shift),
    CsiKey('c'): KeyCode(Key.right, Modifiers.shift),
    CsiKey('d'): KeyCode(Key.left, Modifiers.shift),
    CsiKey('q', 1): KeyCode(Key.f1), // all these 'q' are for aixterm
    CsiKey('q', 2): KeyCode(Key.f2),
    CsiKey('q', 3): KeyCode(Key.f3),
    CsiKey('q', 4): KeyCode(Key.f4),
    CsiKey('q', 5): KeyCode(Key.f5),
    CsiKey('q', 6): KeyCode(Key.f6),
    CsiKey('q', 7): KeyCode(Key.f7),
    CsiKey('q', 8): KeyCode(Key.f8),
    CsiKey('q', 9): KeyCode(Key.f9),
    CsiKey('q', 10): KeyCode(Key.f10),
    CsiKey('q', 11): KeyCode(Key.f11),
    CsiKey('q', 12): KeyCode(Key.f12),
    CsiKey('q', 13): KeyCode(Key.f13),
    CsiKey('q', 14): KeyCode(Key.f14),
    CsiKey('q', 15): KeyCode(Key.f15),
    CsiKey('q', 16): KeyCode(Key.f16),
    CsiKey('q', 17): KeyCode(Key.f17),
    CsiKey('q', 18): KeyCode(Key.f18),
    CsiKey('q', 19): KeyCode(Key.f19),
    CsiKey('q', 20): KeyCode(Key.f20),
    CsiKey('q', 21): KeyCode(Key.f21),
    CsiKey('q', 22): KeyCode(Key.f22),
    CsiKey('q', 23): KeyCode(Key.f23),
    CsiKey('q', 24): KeyCode(Key.f24),
    CsiKey('q', 25): KeyCode(Key.f25),
    CsiKey('q', 26): KeyCode(Key.f26),
    CsiKey('q', 27): KeyCode(Key.f27),
    CsiKey('q', 28): KeyCode(Key.f28),
    CsiKey('q', 29): KeyCode(Key.f29),
    CsiKey('q', 30): KeyCode(Key.f30),
    CsiKey('q', 31): KeyCode(Key.f31),
    CsiKey('q', 32): KeyCode(Key.f32),
    CsiKey('q', 33): KeyCode(Key.f33),
    CsiKey('q', 34): KeyCode(Key.f34),
    CsiKey('q', 35): KeyCode(Key.f35),
    CsiKey('q', 36): KeyCode(Key.f36),
    CsiKey('q', 144): KeyCode(Key.clear),
    CsiKey('q', 146): KeyCode(Key.end),
    CsiKey('q', 150): KeyCode(Key.pgUp),
    CsiKey('q', 154): KeyCode(Key.pgDn),
    CsiKey('z', 214): KeyCode(Key.home),
    CsiKey('z', 216): KeyCode(Key.pgUp),
    CsiKey('z', 220): KeyCode(Key.end),
    CsiKey('z', 222): KeyCode(Key.pgDn),
    CsiKey('z', 224): KeyCode(Key.f1),
    CsiKey('z', 225): KeyCode(Key.f2),
    CsiKey('z', 226): KeyCode(Key.f3),
    CsiKey('z', 227): KeyCode(Key.f4),
    CsiKey('z', 228): KeyCode(Key.f5),
    CsiKey('z', 229): KeyCode(Key.f6),
    CsiKey('z', 230): KeyCode(Key.f7),
    CsiKey('z', 231): KeyCode(Key.f8),
    CsiKey('z', 232): KeyCode(Key.f9),
    CsiKey('z', 233): KeyCode(Key.f10),
    CsiKey('z', 234): KeyCode(Key.f11),
    CsiKey('z', 235): KeyCode(Key.f12),
    CsiKey('z', 247): KeyCode(Key.insert),
    CsiKey('^', 1): KeyCode(Key.home, Modifiers.ctrl),
    CsiKey('^', 2): KeyCode(Key.insert, Modifiers.ctrl),
    CsiKey('^', 3): KeyCode(Key.del, Modifiers.ctrl),
    CsiKey('^', 4): KeyCode(Key.end, Modifiers.ctrl),
    CsiKey('^', 5): KeyCode(Key.pgUp, Modifiers.ctrl),
    CsiKey('^', 6): KeyCode(Key.pgDn, Modifiers.ctrl),
    CsiKey('^', 7): KeyCode(Key.home, Modifiers.ctrl),
    CsiKey('^', 8): KeyCode(Key.end, Modifiers.ctrl),
    CsiKey('^', 11): KeyCode(Key.f23),
    CsiKey('^', 12): KeyCode(Key.f24),
    CsiKey('^', 13): KeyCode(Key.f25),
    CsiKey('^', 14): KeyCode(Key.f26),
    CsiKey('^', 15): KeyCode(Key.f27),
    CsiKey('^', 17): KeyCode(Key.f28), // 16 is a gap
    CsiKey('^', 18): KeyCode(Key.f29),
    CsiKey('^', 19): KeyCode(Key.f30),
    CsiKey('^', 20): KeyCode(Key.f31),
    CsiKey('^', 21): KeyCode(Key.f32),
    CsiKey('^', 23): KeyCode(Key.f33), // 22 is a gap
    CsiKey('^', 24): KeyCode(Key.f34),
    CsiKey('^', 25): KeyCode(Key.f35),
    CsiKey('^', 26): KeyCode(Key.f36),
    CsiKey('^', 28): KeyCode(Key.f37), // 27 is a gap
    CsiKey('^', 29): KeyCode(Key.f38),
    CsiKey('^', 31): KeyCode(Key.f39), // 30 is a gap
    CsiKey('^', 32): KeyCode(Key.f40),
    CsiKey('^', 33): KeyCode(Key.f41),
    CsiKey('^', 34): KeyCode(Key.f42),
    CsiKey('@', 23): KeyCode(Key.f43),
    CsiKey('@', 24): KeyCode(Key.f44),
    CsiKey('@', 1): KeyCode(Key.home, Modifiers.shift | Modifiers.ctrl),
    CsiKey('@', 2): KeyCode(Key.insert, Modifiers.shift | Modifiers.ctrl),
    CsiKey('@', 3): KeyCode(Key.del, Modifiers.shift | Modifiers.ctrl),
    CsiKey('@', 4): KeyCode(Key.end, Modifiers.shift | Modifiers.ctrl),
    CsiKey('@', 5): KeyCode(Key.pgUp, Modifiers.shift | Modifiers.ctrl),
    CsiKey('@', 6): KeyCode(Key.pgDn, Modifiers.shift | Modifiers.ctrl),
    CsiKey('@', 7): KeyCode(Key.home, Modifiers.shift | Modifiers.ctrl),
    CsiKey('@', 8): KeyCode(Key.end, Modifiers.shift | Modifiers.ctrl),
    CsiKey('$', 1): KeyCode(Key.home, Modifiers.shift),
    CsiKey('$', 2): KeyCode(Key.insert, Modifiers.shift),
    CsiKey('$', 3): KeyCode(Key.del, Modifiers.shift),
    CsiKey('$', 4): KeyCode(Key.end, Modifiers.shift),
    CsiKey('$', 5): KeyCode(Key.pgUp, Modifiers.shift),
    CsiKey('$', 6): KeyCode(Key.pgDn, Modifiers.shift),
    CsiKey('$', 7): KeyCode(Key.home, Modifiers.shift),
    CsiKey('$', 8): KeyCode(Key.end, Modifiers.shift),
    CsiKey('$', 23): KeyCode(Key.f21),
    CsiKey('$', 24): KeyCode(Key.f22),
    CsiKey('~', 1): KeyCode(Key.home),
    CsiKey('~', 2): KeyCode(Key.insert),
    CsiKey('~', 3): KeyCode(Key.del),
    CsiKey('~', 4): KeyCode(Key.end),
    CsiKey('~', 5): KeyCode(Key.pgUp),
    CsiKey('~', 6): KeyCode(Key.pgDn),
    CsiKey('~', 7): KeyCode(Key.home),
    CsiKey('~', 8): KeyCode(Key.end),
    CsiKey('~', 11): KeyCode(Key.f1),
    CsiKey('~', 12): KeyCode(Key.f2),
    CsiKey('~', 13): KeyCode(Key.f3),
    CsiKey('~', 14): KeyCode(Key.f4),
    CsiKey('~', 15): KeyCode(Key.f5),
    CsiKey('~', 16): KeyCode(Key.f6),
    CsiKey('~', 18): KeyCode(Key.f7),
    CsiKey('~', 19): KeyCode(Key.f8),
    CsiKey('~', 20): KeyCode(Key.f9),
    CsiKey('~', 21): KeyCode(Key.f10),
    CsiKey('~', 23): KeyCode(Key.f11),
    CsiKey('~', 24): KeyCode(Key.f12),
    CsiKey('~', 25): KeyCode(Key.f13),
    CsiKey('~', 26): KeyCode(Key.f14),
    CsiKey('~', 28): KeyCode(Key.f15),
    CsiKey('~', 29): KeyCode(Key.f16),
    CsiKey('~', 31): KeyCode(Key.f17),
    CsiKey('~', 32): KeyCode(Key.f18),
    CsiKey('~', 33): KeyCode(Key.f19),
    CsiKey('~', 34): KeyCode(Key.f20),
    // CsiKey('~', 200): KeyCode(keyPasteStart),
    // CsiKey('~', 201): KeyCode(keyPasteEnd),
];

// keys by their SS3 - used in application mode usually (legacy VT-style)
immutable KeyCode[char] ss3Keys = [
    'A': KeyCode(Key.up),
    'B': KeyCode(Key.down),
    'C': KeyCode(Key.right),
    'D': KeyCode(Key.left),
    'F': KeyCode(Key.end),
    'H': KeyCode(Key.home),
    'P': KeyCode(Key.f1),
    'Q': KeyCode(Key.f2),
    'R': KeyCode(Key.f3),
    'S': KeyCode(Key.f4),
    't': KeyCode(Key.f5),
    'u': KeyCode(Key.f6),
    'v': KeyCode(Key.f7),
    'l': KeyCode(Key.f8),
    'w': KeyCode(Key.f9),
    'x': KeyCode(Key.f10),
];

// linux terminal uses these non ECMA keys prefixed by CSI-[
immutable KeyCode[char] linuxFKeys = [
    'A': KeyCode(Key.f1),
    'B': KeyCode(Key.f2),
    'C': KeyCode(Key.f3),
    'D': KeyCode(Key.f4),
    'E': KeyCode(Key.f5),
];

immutable KeyCode[int] csiUKeys = [
    27: KeyCode(Key.esc),
    9: KeyCode(Key.tab),
    13: KeyCode(Key.enter),
    127: KeyCode(Key.backspace),
    // 57_358: KeyCode(KeyCapsLock),
    // 57_359: KeyCode(KeyScrollLock),
    // 57_360: KeyCode(KeyNumLock),
    57_361: KeyCode(Key.print),
    57_362: KeyCode(Key.pause),
    // 57_363: KeyCode(Key.menu),
    57_376: KeyCode(Key.f13),
    57_377: KeyCode(Key.f14),
    57_378: KeyCode(Key.f15),
    57_379: KeyCode(Key.f16),
    57_380: KeyCode(Key.f17),
    57_381: KeyCode(Key.f18),
    57_382: KeyCode(Key.f19),
    57_383: KeyCode(Key.f20),
    57_384: KeyCode(Key.f21),
    57_385: KeyCode(Key.f22),
    57_386: KeyCode(Key.f23),
    57_387: KeyCode(Key.f24),
    57_388: KeyCode(Key.f25),
    57_389: KeyCode(Key.f26),
    57_390: KeyCode(Key.f27),
    57_391: KeyCode(Key.f28),
    57_392: KeyCode(Key.f29),
    57_393: KeyCode(Key.f30),
    57_394: KeyCode(Key.f31),
    57_395: KeyCode(Key.f32),
    57_396: KeyCode(Key.f33),
    57_397: KeyCode(Key.f34),
    57_398: KeyCode(Key.f35),
    // TODO: KP keys
    // TODO: Media keys
];

// windows virtual key codes per microsoft
immutable KeyCode[int] winKeys = [
    0x03: KeyCode(Key.cancel), // vkCancel
    0x08: KeyCode(Key.backspace), // vkBackspace
    0x09: KeyCode(Key.tab), // vkTab
    0x0d: KeyCode(Key.enter), // vkReturn
    0x12: KeyCode(Key.clear), // vClear
    0x13: KeyCode(Key.pause), // vkPause
    0x1b: KeyCode(Key.esc), // vkEscape
    0x21: KeyCode(Key.pgUp), // vkPrior
    0x22: KeyCode(Key.pgDn), // vkNext
    0x23: KeyCode(Key.end), // vkEnd
    0x24: KeyCode(Key.home), // vkHome
    0x25: KeyCode(Key.left), // vkLeft
    0x26: KeyCode(Key.up), // vkUp
    0x27: KeyCode(Key.right), // vkRight
    0x28: KeyCode(Key.down), // vkDown
    0x2a: KeyCode(Key.print), // vkPrint
    0x2c: KeyCode(Key.print), // vkPrtScr
    0x2d: KeyCode(Key.insert), // vkInsert
    0x2e: KeyCode(Key.del), // vkDelete
    0x2f: KeyCode(Key.help), // vkHelp
    0x70: KeyCode(Key.f1), // vkF1
    0x71: KeyCode(Key.f2), // vkF2
    0x72: KeyCode(Key.f3), // vkF3
    0x73: KeyCode(Key.f4), // vkF4
    0x74: KeyCode(Key.f5), // vkF5
    0x75: KeyCode(Key.f6), // vkF6
    0x76: KeyCode(Key.f7), // vkF7
    0x77: KeyCode(Key.f8), // vkF8
    0x78: KeyCode(Key.f9), // vkF9
    0x79: KeyCode(Key.f10), // vkF10
    0x7a: KeyCode(Key.f11), // vkF11
    0x7b: KeyCode(Key.f12), // vkF12
    0x7c: KeyCode(Key.f13), // vkF13
    0x7d: KeyCode(Key.f14), // vkF14
    0x7e: KeyCode(Key.f15), // vkF15
    0x7f: KeyCode(Key.f16), // vkF16
    0x80: KeyCode(Key.f17), // vkF17
    0x81: KeyCode(Key.f18), // vkF18
    0x82: KeyCode(Key.f19), // vkF19
    0x83: KeyCode(Key.f20), // vkF20
    0x84: KeyCode(Key.f21), // vkF21
    0x85: KeyCode(Key.f22), // vkF22
    0x86: KeyCode(Key.f23), // vkF23
    0x87: KeyCode(Key.f24), // vkF24
];

class Parser
{

    Event[] events() pure
    {
        auto res = evs;
        evs = null;
        return cast(Event[]) res;
    }

    bool parse(string b)
    {
        buf ~= b;
        scan();
        return parseState == ParseState.ini;
    }

    bool empty() const pure
    {
        return buf.length == 0;
    }

private:
    enum ParseState
    {
        ini, // initial state
        esc, // escaped
        utf, // inside a UTF-8
        csi, // control sequence introducer
        osc, // operating system command
        dcs, // device control string
        sos, // start of string (unused)
        pm, // privacy message (unused)
        apc, // application program command
        str, // string terminator
        ss2, // single shift 2
        ss3, // single shift 3
        lnx, // linux F-key (not ECMA-48 compliant - bogus CSI)
    }

    ParseState parseState;
    ParseState strState;
    Parser nested; // nested parser, required for Windows key processing with 3rd party terminals
    string csiParams;
    string csiInterm;
    string scratch;

    bool escaped;
    ubyte[] buf;
    ubyte[] accum;
    Event[] evs;
    int utfLen; // how many UTF bytes are expected
    ubyte escChar; // character immediately following escape (zero if none)
    const KeyCode[string] keyCodes;
    bool partial; // record partially parsed sequences
    MonoTime keyStart; // when the timer started
    Duration seqTime = msecs(50); // time to fully decode a partial sequence
    bool buttonDown; // true if buttons were down
    bool pasting;
    dstring pasteBuf;

    void postKey(Key k, dchar dch, Modifiers mod)
    {
        if (pasting)
        {
            if (dch != 0)
            {
                pasteBuf ~= dch;
            }
        }
        else
        {
            evs ~= newKeyEvent(k, dch, mod);
        }
    }

    void scan()
    {
        while (!buf.empty)
        {
            ubyte ch = buf[0];
            buf = buf[1 .. $];
            escChar = 0;

            final switch (parseState)
            {
            case ParseState.utf:
                accum ~= ch;
                if (accum.length >= utfLen)
                {
                    parseState = ParseState.ini;
                    size_t index = 0;
                    dchar dch = decode(cast(string) accum, index);
                    accum = null;
                    postKey(Key.rune, dch, Modifiers.none);
                }
                break;
            case ParseState.ini:
                if (ch >= 0x80)
                {
                    accum = null;
                    parseState = ParseState.utf;
                    accum ~= ch;
                    if ((ch & 0xE0) == 0xC0)
                    {
                        utfLen = 2;
                    }
                    else if ((ch & 0xF0) == 0xE0)
                    {
                        utfLen = 3;
                    }
                    else if ((ch & 0xF0) == 0xF0)
                    {
                        utfLen = 4;
                    }
                    else
                    {
                        // garbled - got a non-leading byte (e.g. 0x80 through 0xBF)
                        parseState = ParseState.ini;
                        accum = null;
                    }
                    continue;
                }
                switch (ch)
                {
                case '\x1b':
                    parseState = ParseState.esc;
                    keyStart = MonoTime.currTime();
                    continue;
                case '\t':
                    postKey(Key.tab, ch, Modifiers.none);
                    break;
                case '\b', '\x7F':
                    postKey(Key.backspace, ch, Modifiers.none);
                    break;
                case '\n', '\r':
                    // will be converted by postKey
                    postKey(Key.enter, ch, Modifiers.none);
                    break;
                default:
                    // simple runes
                    if (ch >= ' ')
                    {
                        postKey(Key.rune, ch, Modifiers.none);
                    }
                    // Control keys below here - legacy handling
                    else if (ch == 0)
                    {
                        postKey(Key.rune, ' ', Modifiers.ctrl);
                    }
                    else if (ch < '\x1b')
                    {
                        postKey(Key.rune, ch + 0x60, Modifiers.ctrl);
                    }
                    else
                    {
                        // control keys
                        postKey(Key.rune, ch + 0x40, Modifiers.ctrl);
                    }
                    break;
                }
                break;
            case ParseState.esc:
                switch (ch)
                {
                case '[':
                    parseState = ParseState.csi;
                    csiInterm = null;
                    csiParams = null;
                    escChar = ch; // save the escChar, it might be just esc as alt
                    break;
                case ']':
                    parseState = ParseState.osc;
                    scratch = null;
                    escChar = ch; // save the escChar, it might be just esc as alt
                    break;
                case 'N':
                    parseState = ParseState.ss2; // no known uses
                    scratch = null;
                    escChar = ch; // save the escChar, it might be just esc as alt
                    break;
                case 'O':
                    parseState = ParseState.ss3;
                    scratch = null;
                    escChar = ch; // save the escChar, it might be just esc as alt
                    break;
                case 'X':
                    parseState = ParseState.sos;
                    scratch = null;
                    escChar = ch; // save the escChar, it might be just esc as alt
                    break;
                case '^':
                    parseState = ParseState.pm;
                    scratch = null;
                    escChar = ch; // save the escChar, it might be just esc as alt
                    break;
                case '_':
                    parseState = ParseState.apc;
                    scratch = null;
                    escChar = ch; // save the escChar, it might be just esc as alt
                    break;
                case '\\': // string terminator reached, (orphaned?)
                    parseState = ParseState.ini;
                    break;
                case '\t': // Linux console only, does not conform to ECMA
                    parseState = ParseState.ini;
                    postKey(Key.backtab, 0, Modifiers.none);
                    break;
                case '\x1b':
                    // leading ESC to capture alt
                    escaped = true;
                    break;
                default:
                    // treat as alt-key ... legacy emulators only (no CSI-u or other)
                    parseState = parseState.ini;
                    escaped = false;
                    if (ch >= ' ')
                    {
                        postKey(Key.rune, ch, Modifiers.meta);
                    }
                    else if (ch < '\x1b')
                    {
                        postKey(Key.rune, ch + 0x60, Modifiers.meta | Modifiers.ctrl);
                    }
                    else
                    {
                        postKey(Key.rune, ch + 0x40, Modifiers.meta | Modifiers.ctrl);
                    }
                }
                break;
            case ParseState.ss2:
                // no known uses
                parseState = ParseState.ini;
                break;
            case ParseState.ss3:
                parseState = ParseState.ini;
                if (ch in ss3Keys)
                {
                    auto k = ss3Keys[ch];
                    postKey(k.key, 0, k.mod);
                }
                break;

            case ParseState.apc, ParseState.pm, ParseState.sos, ParseState.dcs: // these we just eat
                switch (ch)
                {
                case '\x1b':
                    strState = parseState;
                    parseState = ParseState.str;
                    break;
                case '\x07': // bell - some send this instead of ST
                    parseState = ParseState.ini;
                    break;
                default:
                    break;
                }
                break;
            case ParseState.osc: // not sure if used
                switch (ch)
                {
                case '\x1b':
                    strState = parseState;
                    parseState = ParseState.str;
                    break;
                case '\x07':
                    handleOsc();
                    break;
                default:
                    scratch ~= (ch & 0x7F);
                    break;
                }
                break;
            case ParseState.str:
                if (ch == '\\' || ch == '\x07')
                {
                    parseState = ParseState.ini;
                    if (strState == ParseState.osc)
                    {
                        handleOsc();
                    }
                    else
                    {
                        parseState = ParseState.ini;
                    }
                }
                else
                {
                    scratch ~= '\x1b';
                    scratch ~= ch;
                    parseState = strState;
                }
                break;
            case ParseState.lnx:
                if (ch in linuxFKeys)
                {
                    auto k = linuxFKeys[ch];
                    postKey(k.key, 0, Modifiers.none);
                }
                parseState = ParseState.ini;
                break;

            case ParseState.csi:
                // usual case for incoming keys
                // NB: rxvt uses terminating '$' which is not a legal CSI terminator,
                // for certain shifted key sequences.  We special case this, and it's ok
                // because no other terminal seems to use this for CSI intermediates from
                // the terminal to the host (queries in the other direction can use it.)
                if (ch >= 0x30 && ch <= 0x3F)
                { // parameter bytes
                    csiParams ~= ch;
                }
                else if (ch == '$' && !csiParams.empty)
                {
                    // rxvt $ terminator (not technically legal)
                    handleCsi(ch, csiParams, csiInterm);
                }
                else if ((ch >= 0x20) && (ch <= 0x2F))
                {
                    // intermediate bytes, rarely used
                    csiInterm ~= ch;
                }
                else if (ch >= 0x40 && ch <= 0x7F)
                {
                    // final byte
                    handleCsi(ch, csiParams, csiInterm);
                }
                else
                {
                    // bad parse, just swallow it all
                    parseState = ParseState.ini;
                }
                break;
            }
        }

        auto now = MonoTime.currTime();
        if ((now - keyStart) > seqTime)
        {
            if (parseState == ParseState.esc)
            {
                postKey(Key.esc, '\x1b', Modifiers.none);
                parseState = ParseState.ini;
            }
            else if (escChar != 0)
            {
                postKey(Key.rune, escChar, Modifiers.alt);
                escChar = 0;
                parseState = ParseState.ini;
            }
        }
    }

    void handleOsc()
    {
        // TODO: OSC 52 is for clipboard
        //   	if content, ok := strings.CutPrefix(str, "52;c;"); ok {
        // 	decoded := make([]byte, base64.StdEncoding.DecodedLen(len(content)))
        // 	if count, err := base64.StdEncoding.Decode(decoded, []byte(content)); err == nil {
        // 		ip.post(NewEventClipboard(decoded[:count]))
        // 		return
        // 	}
        // }

        // string is located in scratch.
        parseState = ParseState.ini;
    }

    void handleCsi(ubyte mode, string params, string interm)
    {
        parseState = ParseState.ini;

        if (!interm.empty)
        {
            // we don't know what to do with these for now
            return;
        }

        auto hasLT = false;
        int plen, p0, p1, p2, p3, p4, p5;

        // extract numeric parameters
        if (!params.empty && params[0] == '<')
        {
            hasLT = true;
            params = params[1 .. $];
        }
        if ((!params.empty) && params[0] >= '0' && params[0] <= '9')
        {
            int[6] pints;
            string[] parts = split(params, ";");
            plen = cast(int) parts.length;
            foreach (i, ps; parts)
            {
                if (i < 6 && !ps.empty)
                {
                    try
                    {
                        pints[i] = ps.to!int;
                    }
                    catch (Exception)
                    {
                    }
                }
            }

            // None of the use cases use care about have more than three parameters.
            p0 = pints[0];
            p1 = pints[1];
            p2 = pints[2];
            p3 = pints[3];
            p4 = pints[4];
            p5 = pints[5];
        }

        // leading less than is only used for mouse reports.
        if (hasLT)
        {
            if (mode == 'm' || mode == 'M')
            {
                handleMouse(mode, p0, p1, p2);
            }
            return;
        }

        switch (mode)
        {
        case 'I': // focus in
            evs ~= newFocusEvent(true);
            return;
        case 'O': // focus out
            evs ~= newFocusEvent(false);
            return;
        case '[': // linux console F-key - CSI-[ modifies next key
            parseState = ParseState.lnx;
            return;
        case 'u': // CSI-u kitty keyboard protocol
            if (plen > 0)
            {
                Modifiers mod = Modifiers.none;
                Key key = Key.rune;
                dchar chr = 0;
                if (p0 in csiUKeys)
                {
                    auto k = csiUKeys[p0];
                    key = k.key;
                }
                else
                {
                    chr = cast(dchar) p0;
                }

                evs ~= newKeyEvent(key, chr, plen > 1 ? calcModifier(p1) : Modifiers.none);
            }
            return;

        case '_':
            if (plen > 0)
            {
                handleWinKey(p0, p1, p2, p3, p4, p5);
            }
            return;

        case 't':
            // if (P.length == 3 && P[0] == 8)
            // {
            //     // window size report
            //     auto h = p1;
            //     auto w = p2;
            //     if (h != rows || w != cols)
            //     {
            //         setSize(w, h);
            //     }
            // }
            return;

        case '~':

            // look for modified keys (note that unmodified keys are handled below)
            auto ck = CsiKey(mode, p0);
            auto mod = plen > 1 ? calcModifier(p1) : Modifiers.none;

            if (ck in csiAllKeys)
            {
                auto kc = csiAllKeys[ck];
                evs ~= newKeyEvent(kc.key, 0, mod);
                return;
            }

            // this might be XTerm modifyOtherKeys protocol
            // CSI 27; modifiers; chr; ~
            if (p0 == 27 && p2 > 0 && p2 <= 0xff)
            {
                if (p2 < ' ' || p2 == 0x7F)
                {
                    evs ~= newKeyEvent(cast(Key) p2, 0, mod);
                }
                else
                {
                    evs ~= newKeyEvent(Key.rune, p2, mod);
                }
                return;
            }

            if (p0 == 200)
            {
                pasting = true;
                pasteBuf = null;
            }
            else if (p0 == 201)
            {
                if (pasting)
                {
                    evs ~= newPasteEvent(pasteBuf);
                    pasting = false;
                    pasteBuf = null;
                }
            }

            break;

        case 'P':
            // aixterm uses this for KeyDelete, but it is F1 for others
            if (environment.get("TERM") == "aixterm")
            {
                evs ~= newKeyEvent(Key.del, 0, Modifiers.none);
                return;
            }
            // other cases we use the lookup (P is an SS3 key)
            goto default;

        default:

            if ((mode in ss3Keys) && p0 == 1 && plen > 1)
            {
                auto kc = ss3Keys[mode];
                evs ~= newKeyEvent(kc.key, 0, calcModifier(p1));
            }
            else
            {
                auto ck = CsiKey(mode, p0);
                if (ck in csiAllKeys)
                {
                    auto kc = csiAllKeys[ck];
                    evs ~= newKeyEvent(kc.key, 0, kc.mod);
                }
            }
            return;
        }
    }

    void handleMouse(ubyte mode, int p0, int p1, int p2)
    {
        // XTerm mouse events only report at most one button at a time,
        // which may include a wheel button.  Wheel motion events are
        // reported as single impulses, while other button events are reported
        // as separate press & release events.
        //
        auto btn = p0;
        auto x = p1 - 1;
        auto y = p2 - 1;
        bool motion = (btn & 0x20) != 0;
        bool scroll = (btn & 0x42) == 0x40;
        btn &= ~0x20;
        if (mode == 'm')
        {
            // mouse release, clear all buttons
            btn |= 0x03;
            btn &= ~0x40;
            buttonDown = false;
        }
        else if (motion)
        {
            // Some broken terminals appear to send
            // mouse button one motion events, instead of
            // encoding 35 (no buttons) into these events.
            // We resolve these by looking for a non-motion
            // event first.
            if (!buttonDown)
            {
                btn |= 0x03;
                btn &= ~0x40;
            }
        }
        else if (!scroll)
        {
            buttonDown = true;
        }

        auto button = Buttons.none;
        auto mod = Modifiers.none;

        // Mouse wheel has bit 6 set, no release events.  It should be noted
        // that wheel events are sometimes misdelivered as mouse button events
        // during a click-drag, so we debounce these, considering them to be
        // button press events unless we see an intervening release event.
        final switch (btn & 0x43)
        {
        case 0:
            button = Buttons.button1;
            break;
        case 1:
            button = Buttons.button3; // Note we prefer to treat right as button 2
            break;
        case 2:
            button = Buttons.button2; // And the middle button as button 3
            break;
        case 3:
            button = Buttons.none;
            break;
        case 0x40:
            button = Buttons.wheelUp;
            break;
        case 0x41:
            button = Buttons.wheelDown;
            break;
        case 0x42:
            button = Buttons.wheelLeft;
            break;
        case 0x43:
            button = Buttons.wheelRight;
            break;
        }

        if ((btn & 0x4) != 0)
        {
            mod |= Modifiers.shift;
        }
        if ((btn & 0x8) != 0)
        {
            mod |= Modifiers.alt;
        }
        if ((btn & 0x10) != 0)
        {
            mod |= Modifiers.ctrl;
        }

        evs ~= newMouseEvent(x, y, button, mod);
    }

    void handleWinKey(int p0, int p1, int p2, int p3, int p4, int p5)
    {
        // win32-input-mode
        //  ^[ [ Vk ; Sc ; Uc ; Kd ; Cs ; Rc _
        // Vk: the value of wVirtualKeyCode - any number. If omitted, defaults to '0'.
        // Sc: the value of wVirtualScanCode - any number. If omitted, defaults to '0'.
        // Uc: the decimal value of UnicodeChar - for example, NUL is "0", LF is
        //     "10", the character 'A' is "65". If omitted, defaults to '0'.
        // Kd: the value of bKeyDown - either a '0' or '1'. If omitted, defaults to '0'.
        // Cs: the value of dwControlKeyState - any number. If omitted, defaults to '0'.
        // Rc: the value of wRepeatCount - any number. If omitted, defaults to '1'.
        //
        // Note that some 3rd party terminal emulators (not Terminal) suffer from a bug
        // where other events, such as mouse events, are doubly encoded, using Vk 0
        // for each character.  (So a CSI-M sequence is encoded as a series of CSI-_
        // sequences.)  We consider this a bug in those terminal emulators -- Windows 11
        // Terminal does not suffer this brain damage. (We've observed this with both Alacritty
        // and WezTerm.)
        //
        if (p3 == 0)
        {
            // key up event ignore ignore
            return;
        }
        if (p0 == 0 && p2 == 27 && nested is null)
        {
            nested = new Parser();
        }

        if (nested !is null && p2 > 0 && p2 < 0x80)
        {
            // only ASCII in win32-input-mode
            nested.buf ~= cast(ubyte) p2;
            nested.scan();
            foreach (ev; nested.evs)
            {
                evs ~= ev;
            }
            nested.evs = null;
            return;
        }

        auto key = Key.rune;
        auto chr = p2;
        auto mod = Modifiers.none;
        auto rpt = max(1, p5);

        if (p0 in winKeys)
        {
            auto kc = winKeys[p0];
            key = kc.key;
            chr = 0;
        }
        else if (chr == 0 && p0 >= 0x30 && p0 <= 0x39)
        {
            chr = p0;
        }
        else if (chr < ' ' && p0 >= 0x41 && p0 <= 0x5a)
        {
            key = cast(Key) p0;
            chr = 0;
        }
        else if (key == 0x11 || key == 0x13 || key == 0x14)
        {
            // lone modifiers
            return;
        }

        // Modifiers
        if ((p4 & 0x010) != 0)
        {
            mod |= Modifiers.shift;
        }
        if ((p4 & 0x000c) != 0)
        {
            mod |= Modifiers.ctrl;
        }
        if ((p4 & 0x0003) != 0)
        {
            mod |= Modifiers.alt;
        }
        if (key == Key.rune && chr > ' ' && mod == Modifiers.shift)
        {
            // filter out lone shift for printable chars
            mod = Modifiers.none;
        }
        if (((mod & (Modifiers.ctrl | Modifiers.alt)) == (Modifiers.ctrl | Modifiers.alt)) && (
                chr != 0))
        {
            // Filter out ctrl+alt (it means AltGr)
            mod = Modifiers.none;
        }

        for (; rpt > 0; rpt--)
        {
            if (key != key.rune || chr != 0)
            {
                evs ~= newKeyEvent(key, chr, mod);
            }
        }
    }

    // calculate the modifiers from the CSI modifier parameter.
    Modifiers calcModifier(int n)
    {
        n--;
        Modifiers m;
        if ((n & 1) != 0)
        {
            m |= Modifiers.shift;
        }
        if ((n & 2) != 0)
        {
            m |= Modifiers.alt;
        }
        if ((n & 4) != 0)
        {
            m |= Modifiers.ctrl;
        }
        if ((n & 8) != 0)
        {
            m |= Modifiers.meta; // kitty calls this Super
        }
        if ((n & 16) != 0)
        {
            m |= Modifiers.hyper;
        }
        if ((n & 32) != 0)
        {
            m |= Modifiers.meta; // for now not separating from Super
        }
        // Not doing (kitty only):
        // caps_lock 0b1000000   (64)
        // num_lock  0b10000000  (128)

        return m;
    }

    Event newFocusEvent(bool focused)
    {
        Event ev =
        {
            type: EventType.focus, when: MonoTime.currTime(), focus: {
                focused: focused
            }
        };
        return ev;
    }

    Event newKeyEvent(Key k, dchar dch = 0, Modifiers mod = Modifiers.none)
    {
        if (escaped)
        {
            mod |= Modifiers.alt;
            escaped = false;
        }
        Event ev = {
            type: EventType.key, when: MonoTime.currTime(), key: {
                key: k, ch: dch, mod: mod
            }
        };
        return ev;
    }

    Event newMouseEvent(int x, int y, Buttons btn, Modifiers mod)
    {
        Event ev = {
            type: EventType.mouse, when: MonoTime.currTime, mouse: {
                pos: Coord(x, y),
                btn: btn,
                mod: mod,
            }
        };
        return ev;
    }

    // NB: it is possible for x and y to be outside the current coordinates
    // (happens for click drag for example).  Consumer of the event should clip
    // the coordinates as needed.
    Event newMouseEvent(int x, int y, int btn)
    {
        Event ev = {
            type: EventType.mouse, when: MonoTime.currTime, mouse: {
                pos: Coord(x, y)
            }
        };

        // Mouse wheel has bit 6 set, no release events.  It should be noted
        // that wheel events are sometimes misdelivered as mouse button events
        // during a click-drag, so we debounce these, considering them to be
        // button press events unless we see an intervening release event.

        switch (btn & 0x43)
        {
        case 0:
            ev.mouse.btn = Buttons.button1;
            break;
        case 1:
            ev.mouse.btn = Buttons.button3;
            break;
        case 2:
            ev.mouse.btn = Buttons.button2;
            break;
        case 3:
            ev.mouse.btn = Buttons.none;
            break;
        case 0x40:
            ev.mouse.btn = Buttons.wheelUp;
            break;
        case 0x41:
            ev.mouse.btn = Buttons.wheelDown;
            break;
        default:
            break;
        }
        if (btn & 0x4)
            ev.mouse.mod |= Modifiers.shift;
        if (btn & 0x8)
            ev.mouse.mod |= Modifiers.alt;
        if (btn & 0x10)
            ev.mouse.mod |= Modifiers.ctrl;
        return ev;
    }

    Event newPasteEvent(dstring buffer)
    {
        Event ev = {
            type: EventType.paste, when: MonoTime.currTime(), paste: {
                content: buffer
            }
        };
        return ev;
    }

    bool parseSequence(string seq)
    {
        if (startsWith(buf, seq))
        {
            buf = buf[seq.length .. $]; // yank the sequence
            return true;
        }
        if (startsWith(seq, buf))
        {
            partial = true;
        }
        return false;
    }

    unittest
    {
        import core.thread;

        // taken from xterm, but pared down
        Parser p = new Parser();
        assert(p.empty());
        assert(p.parse("")); // no data, is fine
        assert(p.parse("\x1bOC"));
        auto ev = p.events();

        assert(ev.length == 1);
        assert(ev[0].type == EventType.key);
        assert(ev[0].key.key == Key.right);

        // this tests that the timed pase parsing works -
        // escape sequences are kept partially until we
        // have a match or we have waited long enough.
        assert(p.parse(['\x1b', 'O']) == false);
        ev = p.events();
        assert(ev.length == 0);
        Thread.sleep(p.seqTime * 2);
        assert(p.parse([]) == true);
        ev = p.events();
        assert(ev.length == 1);
        assert(ev[0].type == EventType.key);
        assert(ev[0].key.key == Key.rune);
        assert(ev[0].key.mod == Modifiers.alt);

        // lone escape
        assert(p.parse(['\x1b']) == false);
        ev = p.events();
        assert(ev.length == 0);
        Thread.sleep(p.seqTime * 2);
        assert(p.parse([]) == true);
        ev = p.events();
        assert(ev.length == 1);
        assert(ev[0].type == EventType.key);
        assert(ev[0].key.key == Key.esc);
        assert(ev[0].key.mod == Modifiers.none);

        // try injecting paste events
        assert(p.parse(['\x1b', '[', '2', '0', '0', '~']));
        assert(p.parse(['A']));
        assert(p.parse(['\x1b', '[', '2', '0', '1', '~']));

        ev = p.events();
        assert(ev.length == 1);
        assert(ev[0].type == EventType.paste);
        assert(ev[0].paste.content == "A");

        // mouse events
        assert(p.parse(['\x1b', '[', '<', '3', ';', '2', ';', '3', 'M']));
        ev = p.events();
        assert(ev.length == 1);
        assert(ev[0].type == EventType.mouse);
        assert(ev[0].mouse.pos.x == 1);
        assert(ev[0].mouse.pos.y == 2);

        // unicode
        string b = [0xe2, 0x82, 0xac];
        assert(p.parse(b));
        ev = p.events();
        assert(ev.length == 1);
        assert(ev[0].type == EventType.key);
        assert(ev[0].key.key == Key.rune);
        assert(ev[0].key.ch == '€');
    }
}
