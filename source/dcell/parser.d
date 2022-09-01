// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.parser;

import core.time;
import std.string;
import std.utf;

import dcell.key;
import dcell.mouse;
import dcell.event;
import dcell.terminfo;

package:
synchronized class Parser
{

    this(const Termcap* tc)
    {
        caps = cast(shared const Termcap*) tc;
        addKeys();
    }

    Event[] events()
    {
        auto res = evs;
        evs = null;
        return cast(Event[]) res;
    }

    bool parse(byte[] b)
    {
        auto now = MonoTime.currTime();
        if (b.length != 0) {
            // if we are adding to it, restart the timer
            keyStart = now;
        }
        buf ~= b;
        while (buf.length != 0)
        {
            partial = false;
            if (parseRune()) {
                keyStart = now;
                continue;
            }
            if (parseFnKey()) {
                keyStart = now;
                continue;
            }
            auto expire = ((now - keyStart) > seqTime);

            // TODO: MOUSE

            if (!partial || expire) {
                if (buf[0] == '\x1b') {
                    if (buf.length == 1) {
                        evs ~= newKeyEvent(Key.esc);
                        escaped = false;
                    } else {
                        escaped = true;
                    }
                    buf = buf[1..$];
                    keyStart = now;
                    continue;
                }
                // no matches or timeout waiting for data, yank off the first byte
                evs ~= newKeyEvent(Key.rune, buf[0], escaped ? Modifiers.alt : Modifiers.none);
                escaped = false;
                keyStart = now;
                continue;
            }
            // we must have partial data, so wait and come back in a bit
            return false;
        }

        return true;
    }

    bool empty()
    {
        return buf.length == 0;
    }

private:
    struct KeyCode
    {
        Key key;
        Modifiers mod;
    }

    const Termcap* caps;
    bool escaped;
    byte[] buf;
    Event[] evs;
    KeyCode[string] keyCodes;
    bool[Key] keyExist;
    bool partial; // record partially parsed sequences
    MonoTime keyStart; // when the timer started
    Duration seqTime = msecs(50); // time to fully decode a partial sequence

    // addKey loads a key sequence, and optionally replaces
    // a previously existing one if it matches.
    void addKey(Key key, string val, Modifiers mod = Modifiers.none, Key replace = cast(Key) 0)
    {
        if (val == "")
            return;
        if ((val !in keyCodes) || keyCodes[val].key == replace)
        {
            keyExist[key] = true;
            keyCodes[val] = KeyCode(key, mod);
        }
    }

    void addXTermKey(Key key, string val)
    {
        if (val.length > 2 && val[0] == '\x1b' && val[1] == '[' && val[$ - 1] == '~')
        {
            // These suffixes are calculated assuming Xterm style modifier suffixes.
            // Please see https://invisible-island.net/xterm/ctlseqs/ctlseqs.pdf for
            // more information (specifically "PC-Style Function Keys").
            val = val[0 .. $ - 1]; // drop trailing ~
            addKey(key, val ~ ";2~", Modifiers.shift, cast(Key)(key + 12));
            addKey(key, val ~ ";3~", Modifiers.alt, cast(Key)(key + 48));
            addKey(key, val ~ ";4~", Modifiers.alt | Modifiers.shift, cast(Key)(key + 60));
            addKey(key, val ~ ";5~", Modifiers.ctrl, cast(Key)(key + 24));
            addKey(key, val ~ ";6~", Modifiers.ctrl | Modifiers.shift, cast(Key)(key + 36));
            addKey(key, val ~ ";7~", Modifiers.alt | Modifiers.ctrl);
            addKey(key, val ~ ";8~", Modifiers.shift | Modifiers.alt | Modifiers.ctrl);
            addKey(key, val ~ ";9~", Modifiers.meta);
            addKey(key, val ~ ";10~", Modifiers.meta | Modifiers.shift);
            addKey(key, val ~ ";11~", Modifiers.meta | Modifiers.alt);
            addKey(key, val ~ ";12~", Modifiers.meta | Modifiers.shift | Modifiers.alt);
            addKey(key, val ~ ";13~", Modifiers.meta | Modifiers.ctrl);
            addKey(key, val ~ ";14~", Modifiers.meta | Modifiers.ctrl | Modifiers.shift);
            addKey(key, val ~ ";15~", Modifiers.meta | Modifiers.ctrl | Modifiers.alt);
            addKey(key, val ~ ";16~",
                Modifiers.meta | Modifiers.ctrl | Modifiers.shift | Modifiers.alt);
        }
        else if (val.length == 3 && val[0] == '\x1b' && val[1] == '0')
        {
            val = val[2 .. $];
            addKey(key, "\x1b[1;2" ~ val, Modifiers.shift, cast(Key)(key + 12));
            addKey(key, "\x1b[1;3" ~ val, Modifiers.alt, cast(Key)(key + 48));
            addKey(key, "\x1b[1;5" ~ val, Modifiers.ctrl, cast(Key)(key + 24));
            addKey(key, "\x1b[1;6" ~ val, Modifiers.ctrl | Modifiers.shift, cast(Key)(key + 36));
            addKey(key, "\x1b[1;4" ~ val, Modifiers.alt | Modifiers.shift, cast(Key)(key + 60));
            addKey(key, "\x1b[1;7" ~ val, Modifiers.alt | Modifiers.ctrl);
            addKey(key, "\x1b[1;8" ~ val, Modifiers.shift | Modifiers.alt | Modifiers.ctrl);
            addKey(key, "\x1b[1;9" ~ val, Modifiers.meta,);
            addKey(key, "\x1b[1;10" ~ val, Modifiers.meta | Modifiers.shift);
            addKey(key, "\x1b[1;11" ~ val, Modifiers.meta | Modifiers.alt);
            addKey(key, "\x1b[1;12" ~ val, Modifiers.meta | Modifiers.alt | Modifiers.shift);
            addKey(key, "\x1b[1;13" ~ val, Modifiers.meta | Modifiers.ctrl);
            addKey(key, "\x1b[1;14" ~ val, Modifiers.meta | Modifiers.ctrl | Modifiers.shift);
            addKey(key, "\x1b[1;15" ~ val, Modifiers.meta | Modifiers.ctrl | Modifiers.alt);
            addKey(key, "\x1b[1;16" ~ val,
                Modifiers.meta | Modifiers.ctrl | Modifiers.alt | Modifiers.shift);
        }
    }

    void addXTermKeys()
    {
        if (caps.keyRight != "\x1b[;2C") // does this look "xtermish"?
            return;
        addXTermKey(Key.right, caps.keyRight);
        addXTermKey(Key.left, caps.keyLeft);
        addXTermKey(Key.up, caps.keyUp);
        addXTermKey(Key.down, caps.keyDown);
        addXTermKey(Key.insert, caps.keyInsert);
        addXTermKey(Key.del, caps.keyDelete);
        addXTermKey(Key.pgUp, caps.keyPgUp);
        addXTermKey(Key.pgDn, caps.keyPgDn);
        addXTermKey(Key.home, caps.keyHome);
        addXTermKey(Key.end, caps.keyEnd);
        addXTermKey(Key.f1, caps.keyF1);
        addXTermKey(Key.f2, caps.keyF2);
        addXTermKey(Key.f3, caps.keyF3);
        addXTermKey(Key.f4, caps.keyF4);
        addXTermKey(Key.f5, caps.keyF5);
        addXTermKey(Key.f6, caps.keyF6);
        addXTermKey(Key.f7, caps.keyF7);
        addXTermKey(Key.f8, caps.keyF8);
        addXTermKey(Key.f9, caps.keyF9);
        addXTermKey(Key.f10, caps.keyF10);
        addXTermKey(Key.f11, caps.keyF11);
        addXTermKey(Key.f12, caps.keyF12);
    }

    void addCtrlKeys()
    {
        // we look breifly at all the keyCodes we
        // have, to find their starting character.
        // the vast majority of these will be escape.
        bool[char] initials;
        foreach (esc, KeyCode; keyCodes)
        {
            if (esc != "")
                initials[esc[0]] = true;
        }
        // Add key mappings for control keys.
        for (char i = 0; i < ' '; i++)
        {

            // If this is starting character (typically esc) of other sequences,
            // then do not set up the fast path mapping for it.
            // We need to let the read do the whole timeout thing.
            if (i in initials)
                continue;

            Key k = cast(Key) i;
            keyExist[k] = true;
            switch (k)
            {
            case Key.backspace, Key.tab, Key.esc, Key.enter:
                // these are directly typeable
                keyCodes["" ~ i] = KeyCode(k, Modifiers.none);
                break;
            default:
                // these are generally represented as a control sequence
                keyCodes["" ~ i] = KeyCode(k, Modifiers.ctrl);
                break;
            }
        }

    }

    void addKeys()
    {
        addKey(Key.backspace, caps.keyBackspace);
        addKey(Key.f1, caps.keyF1);
        addKey(Key.f2, caps.keyF2);
        addKey(Key.f3, caps.keyF3);
        addKey(Key.f4, caps.keyF4);
        addKey(Key.f5, caps.keyF5);
        addKey(Key.f6, caps.keyF6);
        addKey(Key.f7, caps.keyF7);
        addKey(Key.f8, caps.keyF8);
        addKey(Key.f9, caps.keyF9);
        addKey(Key.f10, caps.keyF10);
        addKey(Key.f11, caps.keyF11);
        addKey(Key.f12, caps.keyF12);
        addKey(Key.f13, caps.keyF13);
        addKey(Key.f14, caps.keyF14);
        addKey(Key.f15, caps.keyF15);
        addKey(Key.f16, caps.keyF16);
        addKey(Key.f17, caps.keyF17);
        addKey(Key.f18, caps.keyF18);
        addKey(Key.f19, caps.keyF19);
        addKey(Key.f20, caps.keyF20);
        addKey(Key.f21, caps.keyF21);
        addKey(Key.f22, caps.keyF22);
        addKey(Key.f23, caps.keyF23);
        addKey(Key.f24, caps.keyF24);
        addKey(Key.f25, caps.keyF25);
        addKey(Key.f26, caps.keyF26);
        addKey(Key.f27, caps.keyF27);
        addKey(Key.f28, caps.keyF28);
        addKey(Key.f29, caps.keyF29);
        addKey(Key.f30, caps.keyF30);
        addKey(Key.f31, caps.keyF31);
        addKey(Key.f32, caps.keyF32);
        addKey(Key.f33, caps.keyF33);
        addKey(Key.f34, caps.keyF34);
        addKey(Key.f35, caps.keyF35);
        addKey(Key.f36, caps.keyF36);
        addKey(Key.f37, caps.keyF37);
        addKey(Key.f38, caps.keyF38);
        addKey(Key.f39, caps.keyF39);
        addKey(Key.f40, caps.keyF40);
        addKey(Key.f41, caps.keyF41);
        addKey(Key.f42, caps.keyF42);
        addKey(Key.f43, caps.keyF43);
        addKey(Key.f44, caps.keyF44);
        addKey(Key.f45, caps.keyF45);
        addKey(Key.f46, caps.keyF46);
        addKey(Key.f47, caps.keyF47);
        addKey(Key.f48, caps.keyF48);
        addKey(Key.f49, caps.keyF49);
        addKey(Key.f50, caps.keyF50);
        addKey(Key.f51, caps.keyF51);
        addKey(Key.f52, caps.keyF52);
        addKey(Key.f53, caps.keyF53);
        addKey(Key.f54, caps.keyF54);
        addKey(Key.f55, caps.keyF55);
        addKey(Key.f56, caps.keyF56);
        addKey(Key.f57, caps.keyF57);
        addKey(Key.f58, caps.keyF58);
        addKey(Key.f59, caps.keyF59);
        addKey(Key.f60, caps.keyF60);
        addKey(Key.f61, caps.keyF61);
        addKey(Key.f62, caps.keyF62);
        addKey(Key.f63, caps.keyF63);
        addKey(Key.f64, caps.keyF64);
        addKey(Key.insert, caps.keyInsert);
        addKey(Key.del, caps.keyDelete);
        addKey(Key.home, caps.keyHome);
        addKey(Key.end, caps.keyEnd);
        addKey(Key.up, caps.keyUp);
        addKey(Key.down, caps.keyDown);
        addKey(Key.left, caps.keyLeft);
        addKey(Key.right, caps.keyRight);
        addKey(Key.pgUp, caps.keyPgUp);
        addKey(Key.pgDn, caps.keyPgDn);
        addKey(Key.help, caps.keyHelp);
        addKey(Key.print, caps.keyPrint);
        addKey(Key.cancel, caps.keyCancel);
        addKey(Key.exit, caps.keyExit);
        addKey(Key.backtab, caps.keyBacktab);

        addKey(Key.right, caps.keyShfRight, Modifiers.shift);
        addKey(Key.left, caps.keyShfLeft, Modifiers.shift);
        addKey(Key.up, caps.keyShfUp, Modifiers.shift);
        addKey(Key.down, caps.keyShfDown, Modifiers.shift);
        addKey(Key.home, caps.keyShfHome, Modifiers.shift);
        addKey(Key.end, caps.keyShfEnd, Modifiers.shift);
        addKey(Key.pgUp, caps.keyShfPgUp, Modifiers.shift);
        addKey(Key.pgDn, caps.keyShfPgDn, Modifiers.shift);

        addKey(Key.right, caps.keyCtrlRight, Modifiers.ctrl);
        addKey(Key.left, caps.keyCtrlLeft, Modifiers.ctrl);
        addKey(Key.up, caps.keyCtrlUp, Modifiers.ctrl);
        addKey(Key.down, caps.keyCtrlDown, Modifiers.ctrl);
        addKey(Key.home, caps.keyCtrlHome, Modifiers.ctrl);
        addKey(Key.end, caps.keyCtrlEnd, Modifiers.ctrl);

        // Sadly, xterm handling of keycodes is somewhat erratic.  In
        // particular, different codes are sent depending on application
        // mode is in use or not, and the entries for many of these are
        // simply absent from terminfo on many systems.  So we insert
        // a number of escape sequences if they are not already used, in
        // order to have the widest correct usage.  Note that prepareKey
        // will not inject codes if the escape sequence is already known.
        // We also only do this for terminals that have the application
        // mode present.

        if (caps.enterKeypad != "")
        {
            addKey(Key.up, "\x1b[A");
            addKey(Key.down, "\x1b[B");
            addKey(Key.right, "\x1b[C");
            addKey(Key.left, "\x1b[D");
            addKey(Key.end, "\x1b[F");
            addKey(Key.home, "\x1b[H");
            addKey(Key.del, "\x1b[3~");
            addKey(Key.home, "\x1b[1~");
            addKey(Key.end, "\x1b[4~");
            addKey(Key.pgUp, "\x1b[5~");
            addKey(Key.pgDn, "\x1b[6~");

            // Application mode
            addKey(Key.up, "\x1bOA");
            addKey(Key.down, "\x1bOB");
            addKey(Key.right, "\x1bOC");
            addKey(Key.left, "\x1bOD");
            addKey(Key.home, "\x1bOH");
        }

        addXTermKeys();

        addKey(Key.pasteStart, caps.pasteStart);
        addKey(Key.pasteEnd, caps.pasteEnd);

        addCtrlKeys(); // do this one last
    }

    Event newKeyEvent(Key k, dchar dch = 0, Modifiers mod = Modifiers.none)
    {
        Event ev = {
            type: EventType.key, when: MonoTime.currTime, key: {
                key: k, ch: dch, mod: mod
            }
        };
        return ev;
    }

    bool parseRune()
    {
        if (buf.length == 0)
        {
            return false;
        }
        dchar dc;
        Modifiers mod = Modifiers.none;
        if (buf[0] >= ' ' && buf[0] <= 0x7F)
        {
            dc = buf[0];
            buf = buf[1 .. $];
            // printable ascii, easy to deal with
            if (escaped)
            {
                escaped = false;
                mod = Modifiers.alt;
            }
            evs ~= newKeyEvent(Key.rune, dc, mod);
            return true;
        }
        if (buf[0] < 0x80) // control character, not a rune
            return false;
        // unicode bits...
        size_t index = 0;
        auto temp = cast(string) buf;
        try
        {
            dc = temp.decode(index);
        }
        catch (UTFException e)
        {
            return false;
        }
        evs ~= newKeyEvent(Key.rune, dc, mod);
        buf = buf[index .. $];
        return true;
    }

    bool parseFnKey()
    {
        auto mod = Modifiers.none;
        if (buf.length == 0)
        {
            return false;
        }
        foreach (seq, kc; keyCodes)
        {
            if (seq.length == 1 && seq[0] == '\x1b')
            {
                continue;
            }
            if (startsWith(buf, seq))
            {
                auto mod = kc.mod;
                if (escaped)
                {
                    escaped = false;
                    mod = Modifiers.alt;
                }
                switch (kc.key)
                {
                case Key.pasteStart:
                    // newEventPaste...(true);
                    break;
                case Key.pasteEnd:
                    // newEventPaste(false);
                    break;
                default:
                    evs ~= newKeyEvent(kc.key, seq.length == 1 ? seq[0] : 0, mod);
                    break;
                }
                buf = buf[seq.length .. $];
                return true;
            }
            if (startsWith(seq, buf))
            {
                partial = true;
            }
        }
        return false;
    }
}

unittest
{
    import core.thread;

    // taken from xterm, but pared down
    static immutable Termcap term = {
        name: "test-term",
        enterKeypad: "\x1b[?1h\x1b=",
        exitKeypad: "\x1b[?1l\x1b>",
        cursorBack1: "\x08",
        cursorUp1: "\x1b[A",
        keyBackspace: "\x08",
        keyF1: "\x1bOP",
        keyF2: "\x1bOQ",
        keyF3: "\x1bOR",
        keyInsert: "\x1b[2~",
        keyDelete: "\x1b[3~",
        keyHome: "\x1bOH",
        keyEnd: "\x1bOF",
        keyPgUp: "\x1b[5~",
        keyPgDn: "\x1b[6~",
        keyUp: "\x1bOA",
        keyDown: "\x1bOB",
        keyLeft: "\x1bOD",
        keyRight: "\x1bOC",
        keyBacktab: "\x1b[Z",
        mouse: "\x1b[M",
    };

    shared Parser p = new shared Parser(&term);
    assert(p.empty());
    assert(p.parse(cast(byte[])"\x1bOC"));
    auto ev = p.events();
    import std.stdio;
    writeln("EVENT LENGTH", ev.length);
    assert(ev.length == 1);
    assert(ev[0].type == EventType.key);
    assert(ev[0].key.key == Key.right);

    // this tests that the timed pase parsing works -
    // escape sequences are kept partially until we
    // have a match or we have waited long enough.
    assert(p.parse(['\x1b', 'O']) == false);
    ev = p.events();
    assert(ev.length == 0);
    Thread.sleep(msecs(100));
    assert(p.parse([]) == true);
    ev = p.events;
    assert(ev.length == 1);
    assert(ev[0].type == EventType.key);
    assert(ev[0].key.key == Key.rune);
    assert(ev[0].key.mod == Modifiers.alt);
}
