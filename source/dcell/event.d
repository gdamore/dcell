/**
 * Events module for dcell.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.event;

import core.time;
import std.range;

import dcell.key;
import dcell.mouse;

enum EventType
{
    none = 0,
    closed, /// input queue is closed (no more events will be received)
    error, /// an error condition
    key, /// a keyboard press
    mouse, /// a mouse event
    paste, /// a paste event
    resize, /// window was resized
    focus, /// focus changed
}

/**
 * Event is the abstract from of an event.  We use structs because
 * these will be sent by value over the message box.  Other event
 * types should "derive" from this by using it as their first member
 * and using alias this.
 */
struct Event
{
    EventType type;
    MonoTime when;
    union
    {
        MouseEvent mouse;
        KeyEvent key;
        ResizeEvent resize;
        PasteEvent paste;
        FocusEvent focus;
    }
}

/**
 * Resize is fired when a window resize event has occurred.
 * It is something the application should use to determine
 * when it needs to update layouts, etc.
 */
struct ResizeEvent
{
}

/**
 * Paste start or stop.
 */
struct PasteEvent
{
    dstring content;
}

/// Focus event.
struct FocusEvent
{
    bool focused;
}

/**
 * EventQ is an input and output range of Events that behaves as a FIFO.
 * When adding to the output range it will wake up any reader using the
 * delegate that was passed to it at construction.
 */
class EventQ
{

    void put(Event ev)
    {
        events ~= ev;
    }

    final Event front() const nothrow pure @property @nogc @safe
    {
        return events.front;
    }

    final bool empty() const nothrow pure @property @nogc @safe
    {
        return events.empty;
    }

    final void popFront() nothrow pure @nogc @safe
    {
        events.popFront();
    }

private:
    Event[] events;
}
