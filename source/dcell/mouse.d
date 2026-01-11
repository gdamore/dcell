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
    if (btn == Buttons.none)
        return "None";

    string[] buttons;
    Buttons remaining = btn;

    if (remaining & Buttons.button1)
    {
        buttons ~= "Button1";
        remaining &= ~Buttons.button1;
    }
    if (remaining & Buttons.button2)
    {
        buttons ~= "Button2";
        remaining &= ~Buttons.button2;
    }
    if (remaining & Buttons.button3)
    {
        buttons ~= "Button3";
        remaining &= ~Buttons.button3;
    }
    if (remaining & Buttons.button4)
    {
        buttons ~= "Button4";
        remaining &= ~Buttons.button4;
    }
    if (remaining & Buttons.button5)
    {
        buttons ~= "Button5";
        remaining &= ~Buttons.button5;
    }
    if (remaining & Buttons.button6)
    {
        buttons ~= "Button6";
        remaining &= ~Buttons.button6;
    }
    if (remaining & Buttons.button7)
    {
        buttons ~= "Button7";
        remaining &= ~Buttons.button7;
    }
    if (remaining & Buttons.button8)
    {
        buttons ~= "Button8";
        remaining &= ~Buttons.button8;
    }

    if (remaining & Buttons.wheelUp)
    {
        buttons ~= "WheelUp";
        remaining &= ~Buttons.wheelUp;
    }
    if (remaining & Buttons.wheelDown)
    {
        buttons ~= "WheelDown";
        remaining &= ~Buttons.wheelDown;
    }
    if (remaining & Buttons.wheelLeft)
    {
        buttons ~= "WheelLeft";
        remaining &= ~Buttons.wheelLeft;
    }
    if (remaining & Buttons.wheelRight)
    {
        buttons ~= "WheelRight";
        remaining &= ~Buttons.wheelRight;
    }

    if (remaining != Buttons.none)
    {
        buttons ~= format("Buttons(%04X)", cast(ushort) remaining);
    }

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

    ev.btn = cast(Buttons)(Buttons.button1 | Buttons.wheels);
    assert(ev.toString() == "Ctrl+Shift+Button1+WheelUp+WheelDown+WheelLeft+WheelRight@(10, 20)");

    // Test toString explicitly
    assert(dcell.mouse.toString(cast(Buttons)(Buttons.button1 | Buttons.button2)) == "Button1+Button2");
    assert(dcell.mouse.toString(Buttons.wheels) == "WheelUp+WheelDown+WheelLeft+WheelRight");
    assert(dcell.mouse.toString(cast(Buttons) 0x8000) == "Buttons(8000)");
    assert(dcell.mouse.toString(cast(Buttons)(Buttons.button1 | 0x8000)) == "Button1+Buttons(8000)");
}
