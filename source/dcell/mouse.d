// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.mouse;

import core.time;
public import dcell.key : Modifiers;

/** 
 * The buttons that may be clicked, etc. on a mouse.  These can be cmobined
 * together as a binary value to represent chording.  Scroll wheels are
 * included.
 */
enum Buttons : short
{
    none = 0, /// No button or wheel events.
    button1 = 1 << 0, /// Usually the left or primary mouse button.
    button2 = 1 << 1, /// Usually the right or secondary mouse button.
    button3 = 1 << 2, /// Usually the middle mouse button.
    button4 = 1 << 3, /// Often a side button (thumb/prev).
    button5 = 1 << 4,
    button6 = 1 << 5,
    button7 = 1 << 6,
    button8 = 1 << 7,
    wheelUp = 1 << 8, /// Wheel motion up, away from user.
    wheelDown = 1 << 9, /// Wheel motion down, towards user.
    wheelLeft = 1 << 10, /// Wheel motion to left.
    wheelRight = 1 << 11, /// Wheel motion to right.

    primary = button1,
    secondary = button2,
    middle = button3,
}

/**
 * MouseEvent represents a single pressed key, possibly with modifiers.
 */
struct MouseEvent
{
    Buttons btn; /// Buttons involved.
    Modifiers mod; /// Keyboard modifiers pressed during event.
    int x; /// Column of event.
    int y; /// Row of event.
    MonoTime when; /// When the event fired.
}
