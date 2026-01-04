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

public import dcell.coord;
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
    wheels = wheelUp | wheelDown | wheelLeft | wheelRight,
}

/**
 * MouseEnable are the different modes that can be enabled for
 * mouse tracking.  The flagse can be OR'd together (except disable
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
}
