/**
 * Mouse module for dcell contains definitions related to mice (pointing devices not rodents).
 *
 * Copyright: Copyright 2022 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.mouse;

import std.array : Appender;
import std.format : format;

public import dcell.coord;
public import dcell.key : Modifiers;

/**
 * The buttons that may be clicked, etc. on a mouse.  These can be combined
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
    wheels = wheelUp | wheelDown | wheelLeft | wheelRight,
}

/**
 * toString returns a string representation of the buttons, with
 * multiple buttons separated by '+'.
 */
string toString(Buttons btn) pure
{
    string[] buttons;
    if (btn & Buttons.button1)
        buttons ~= "Button1";
    if (btn & Buttons.button2)
        buttons ~= "Button2";
    if (btn & Buttons.button3)
        buttons ~= "Button3";
    if (btn & Buttons.button4)
        buttons ~= "Button4";
    if (btn & Buttons.button5)
        buttons ~= "Button5";
    if (btn & Buttons.button6)
        buttons ~= "Button6";
    if (btn & Buttons.button7)
        buttons ~= "Button7";
    if (btn & Buttons.button8)
        buttons ~= "Button8";
    if (btn & Buttons.wheelUp)
        buttons ~= "WheelUp";
    if (btn & Buttons.wheelDown)
        buttons ~= "WheelDown";
    if (btn & Buttons.wheelLeft)
        buttons ~= "WheelLeft";
    if (btn & Buttons.wheelRight)
        buttons ~= "WheelRight";

    if (buttons.length == 0)
        return "None";

    import std.array : join;
    return buttons.join("+");
}

/**
 * MouseEnable are the different modes that can be enabled for
 * mouse tracking.  The flags can be OR'd together (except disable
 * which should be used alone).
 */
enum MouseEnable
{
    disable = 0, /// no mouse reporting at all
    buttons = 1 << 0, /// report on button press events only
    drag = 1 << 2, /// report click-drag events (moving while button depressed)
    motion = 1 << 3, /// report all motion events
    all = buttons | drag | motion, /// report everything
}

/**
 * MouseEvent represents a single pressed key, possibly with modifiers.
 * It is sent on either mouse up or mouse down events.  It is also sent on
 * mouse motion events - if the terminal supports it.
 *
 * We make every effort to ensure that mouse release events are delivered.
 * Hence, click drag can be identified by a motion event with the mouse down,
 * without any intervening button release.  On some terminals only the initiating
 * press and terminating release event will be delivered.
 *
 * Mouse wheel events, when reported, may appear on their own as individual
 * impulses; that is, there will normally not be a release event delivered
 * for mouse wheel movements.
 *
 * Most terminals cannot report the state of more than one button at a time --
 * and some cannot report motion events unless a button is pressed.
 *
 * Applications can inspect the time between events to resolve double or triple
 * clicks.
 */
struct MouseEvent
{
    Buttons btn; /// Buttons involved.
    Modifiers mod; /// Keyboard modifiers pressed during event.
    Coord pos; /// Coordinates of mouse.

    string toString() const pure
    {
        Appender!string s;

        // Add modifiers
        if (mod & Modifiers.ctrl)
            s.put("Ctrl+");
        if (mod & Modifiers.shift)
            s.put("Shift+");
        if (mod & Modifiers.meta)
            s.put("Meta+");
        if (mod & Modifiers.alt)
            s.put("Alt+");
        if (mod & Modifiers.hyper)
            s.put("Hyper+");

        s.put(dcell.mouse.toString(btn));

        s.put(format("@%s", pos.toString()));
        return s.data;
    }
}

unittest
{
    MouseEvent ev;
    ev.pos = Coord(10, 20);
    ev.btn = cast(Buttons)(Buttons.button1 | Buttons.button2);
    assert(ev.toString() == "Button1+Button2@(10, 20)");
    
    ev.mod = Modifiers.ctrl | Modifiers.shift;
    assert(ev.toString() == "Ctrl+Shift+Button1+Button2@(10, 20)");
    
    ev.btn = Buttons.wheelUp;
    assert(ev.toString() == "Ctrl+Shift+WheelUp@(10, 20)");
    
    ev.btn = Buttons.wheels;
    assert(ev.toString() == "Ctrl+Shift+WheelUp+WheelDown+WheelLeft+WheelRight@(10, 20)");
}
