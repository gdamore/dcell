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
import std.format : format;
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

    string toString() const
    {
        final switch (type)
        {
            case EventType.none:
                return "Event[none]";
            case EventType.closed:
                return "Event[closed]";
            case EventType.error:
                return "Event[error]";
            case EventType.key:
                return format("Event[key: %s]", key.toString());
            case EventType.mouse:
                return format("Event[mouse: %s]", mouse.toString());
            case EventType.paste:
                return format("Event[paste: %s]", paste.toString());
            case EventType.resize:
                return format("Event[resize: %s]", resize.toString());
            case EventType.focus:
                return format("Event[focus: %s]", focus.toString());
        }
    }
}

/**
 * Resize is fired when a window resize event has occurred.
 * It is something the application should use to determine
 * when it needs to update layouts, etc.
 */
struct ResizeEvent
{
    string toString() const pure
    {
        return "Resize";
    }
}

/**
 * Paste start or stop. Only one of the content or binary fields will have data.
 */
struct PasteEvent
{
    string content; /// string content for normal paste
    ubyte[] binary; /// binary data via OSC 52 or similar

    string toString() const pure
    {
        if (content.length > 0)
            return format("Paste[%d chars]", content.length);
        else if (binary.length > 0)
            return format("Paste[%d bytes binary]", binary.length);
        else
            return "Paste[empty]";
    }
}

/// Focus event.
struct FocusEvent
{
    bool focused;

    string toString() const pure
    {
        return focused ? "Focus[gained]" : "Focus[lost]";
    }
}

/**
 * EventQ is both an input and output range of Events that behaves as a FIFO.
 * When adding to the output range it will wake up any reader using the
 * delegate that was passed to it at construction.
 */
class EventQ
{

    void put(Event ev) @safe nothrow
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
