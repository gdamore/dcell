/**
 * Key module for dcell containing definitiosn for various key strokes.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.key;

import std.string;
import std.algorithm;

/**
 * Key represents a single, unmodified key stroke.  Modifier keys are
 * not considered as Keys.
 */
enum Key
{
    none = 0,

    // NB: the low keys are empty because they are used for control
    // encodings.  But we translate them to rune with a payload char.
    // and ctrl modifier.

    rune = 256, // start of defined keys, numbered high to avoid conflicts
    up,
    down,
    right,
    left,
    upLeft,
    upRight,
    downLeft,
    downRight,
    center,
    pgUp,
    pgDn,
    home,
    end,
    insert,
    del2, // secondary delete button, apart from DEL
    help,
    exit,
    clear,
    cancel,
    print,
    pause,
    backtab,
    f1,
    f2,
    f3,
    f4,
    f5,
    f6,
    f7,
    f8,
    f9,
    f10,
    f11,
    f12,
    f13,
    f14,
    f15,
    f16,
    f17,
    f18,
    f19,
    f20,
    f21,
    f22,
    f23,
    f24,
    f25,
    f26,
    f27,
    f28,
    f29,
    f30,
    f31,
    f32,
    f33,
    f34,
    f35,
    f36,
    f37,
    f38,
    f39,
    f40,
    f41,
    f42,
    f43,
    f44,
    f45,
    f46,
    f47,
    f48,
    f49,
    f50,
    f51,
    f52,
    f53,
    f54,
    f55,
    f56,
    f57,
    f58,
    f59,
    f60,
    f61,
    f62,
    f63,
    f64,

    // convenience aliases
    backspace = 0x08,
    tab = 0x09,
    esc = 0x1B,
    enter = 0x0A,
    del = 0x7F, // Note del2 has a different value
}

static immutable dstring[Key] keyNames;
shared static this()
{
    keyNames[Key.enter] = "Enter";
    keyNames[Key.backspace] = "Backspace";
    keyNames[Key.tab] = "Tab";
    keyNames[Key.backtab] = "Backtab";
    keyNames[Key.esc] = "Esc";
    keyNames[Key.del2] = "Delete2";
    keyNames[Key.del] = "Delete";
    keyNames[Key.insert] = "Insert";
    keyNames[Key.up] = "Up";
    keyNames[Key.down] = "Down";
    keyNames[Key.left] = "Left";
    keyNames[Key.right] = "Right";
    keyNames[Key.home] = "Home";
    keyNames[Key.end] = "End";
    keyNames[Key.upLeft] = "UpLeft";
    keyNames[Key.upRight] = "UpRight";
    keyNames[Key.downLeft] = "DownLeft";
    keyNames[Key.downRight] = "DownRight";
    keyNames[Key.center] = "Center";
    keyNames[Key.pgDn] = "PgDn";
    keyNames[Key.pgUp] = "PgUp";
    keyNames[Key.clear] = "Clear";
    keyNames[Key.exit] = "Exit";
    keyNames[Key.cancel] = "Cancel";
    keyNames[Key.pause] = "Pause";
    keyNames[Key.print] = "Print";
    keyNames[Key.f1] = "F1";
    keyNames[Key.f2] = "F2";
    keyNames[Key.f3] = "F3";
    keyNames[Key.f4] = "F4";
    keyNames[Key.f5] = "F5";
    keyNames[Key.f6] = "F6";
    keyNames[Key.f7] = "F7";
    keyNames[Key.f8] = "F8";
    keyNames[Key.f9] = "F9";
    keyNames[Key.f10] = "F10";
    keyNames[Key.f11] = "F11";
    keyNames[Key.f12] = "F12";
    keyNames[Key.f13] = "F13";
    keyNames[Key.f14] = "F14";
    keyNames[Key.f15] = "F15";
    keyNames[Key.f16] = "F16";
    keyNames[Key.f17] = "F17";
    keyNames[Key.f18] = "F18";
    keyNames[Key.f19] = "F19";
    keyNames[Key.f20] = "F20";
    keyNames[Key.f21] = "F21";
    keyNames[Key.f22] = "F22";
    keyNames[Key.f23] = "F23";
    keyNames[Key.f24] = "F24";
    keyNames[Key.f25] = "F25";
    keyNames[Key.f26] = "F26";
    keyNames[Key.f27] = "F27";
    keyNames[Key.f28] = "F28";
    keyNames[Key.f29] = "F29";
    keyNames[Key.f30] = "F30";
    keyNames[Key.f31] = "F31";
    keyNames[Key.f32] = "F32";
    keyNames[Key.f33] = "F33";
    keyNames[Key.f34] = "F34";
    keyNames[Key.f35] = "F35";
    keyNames[Key.f36] = "F36";
    keyNames[Key.f37] = "F37";
    keyNames[Key.f38] = "F38";
    keyNames[Key.f39] = "F39";
    keyNames[Key.f40] = "F40";
    keyNames[Key.f41] = "F41";
    keyNames[Key.f42] = "F42";
    keyNames[Key.f43] = "F43";
    keyNames[Key.f44] = "F44";
    keyNames[Key.f45] = "F45";
    keyNames[Key.f46] = "F46";
    keyNames[Key.f47] = "F47";
    keyNames[Key.f48] = "F48";
    keyNames[Key.f49] = "F49";
    keyNames[Key.f50] = "F50";
    keyNames[Key.f51] = "F51";
    keyNames[Key.f52] = "F52";
    keyNames[Key.f53] = "F53";
    keyNames[Key.f54] = "F54";
    keyNames[Key.f55] = "F55";
    keyNames[Key.f56] = "F56";
    keyNames[Key.f57] = "F57";
    keyNames[Key.f58] = "F58";
    keyNames[Key.f59] = "F59";
    keyNames[Key.f60] = "F60";
    keyNames[Key.f61] = "F61";
    keyNames[Key.f62] = "F62";
    keyNames[Key.f63] = "F63";
    keyNames[Key.f64] = "F64";
}

/**
 * Modifiers are special keys that when combined with other keys
 * change their meaning.
 */
enum Modifiers
{
    none = 0,
    shift = 1 << 0,
    ctrl = 1 << 1,
    alt = 1 << 2,
    meta = 1 << 3,
    hyper = 1 << 4,
}

/**
 * KeyEvent represents a single pressed key, possibly with modifiers.
 */
struct KeyEvent
{
    Key key; /// Key pressed.
    dchar ch; /// Set if key == rune.
    Modifiers mod; /// Any modifiers pressed together.

    dstring toString() const pure
    {
        dstring s = "";
        if (mod & Modifiers.ctrl)
        {
            s ~= "Ctrl-";
        }
        if (mod & Modifiers.shift)
        {
            s ~= "Shift-";
        }
        if (mod & Modifiers.meta)
        {
            s ~= "Meta-";
        }
        if (mod & Modifiers.alt)
        {
            s ~= "Alt-";
        }
        if (mod & Modifiers.hyper)
        {
            s ~= "Hyper-";
        }
        dstring kn = "";
        if (key in keyNames)
        {
            kn = keyNames[key];
        }
        else if (key == Key.rune)
        {
            if (mod == Modifiers.none)
            {
                kn = [ch];
            }
            else if (ch == ' ')
            {
                kn = "Space";
            }
            else
            {
                kn = [ch.toUpper];
            }
        }
        else
        {
            kn = format("Key[%02X]"d, key);
        }

        return s ~ kn;
    }
}
