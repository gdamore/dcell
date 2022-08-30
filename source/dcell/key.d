// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.key;

import core.time;

/**
 * Key represents a single, unmodified key stroke.  Modifier keys are
 * not considered as Keys.
 */
enum Key : short
{
    none = 0,

    ctrlSpace = 0,
    ctrlA,
    ctrlB,
    ctrlC,
    ctrlD,
    ctrlE,
    ctrlF,
    ctrlG,
    ctrlH,
    ctrlI,
    ctrlJ,
    ctrlK,
    ctrlL,
    ctrlM,
    ctrlN,
    ctrlO,
    ctrlP,
    ctrlQ,
    ctrlR,
    ctrlS,
    ctrlT,
    ctrlU,
    ctrlV,
    ctrlW,
    ctrlX,
    ctrlY,
    ctrlZ,
    ctrlLeftSq, // Escape
    ctrlBackslash,
    ctrlRightSq,
    ctrlCarat,
    ctrlUnderscore,

    rune = 256, // start of defined keys -- values less than this are identity mapped to their ASCII value
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
    ins,
    del,
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
    pasteStart = 16_384, // used internally only
    pasteEnd,

    // convenience aliases
    backspace = 8,
    tab = 9,
    esc = 27,
    enter = 13,
    delete_ = 127,
}

enum Modifiers : short
{
    none = 0,
    shift = 1 << 0,
    ctrl = 1 << 1,
    alt = 1 << 2,
    meta = 1 << 3,
}

/**
 * KeyEvent represents a single pressed key, possibly with modifiers.
 */
struct KeyEvent
{
    Key key; /// key press
    char ch; /// set if key == rune
    Modifiers mod; /// any modifiers?
    MonoTime when; /// when the event fired
}
