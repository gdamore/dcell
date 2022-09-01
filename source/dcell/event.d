// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.event;

import core.time;

import dcell.key;
import dcell.mouse;

enum EventType
{
    none = 0,
    error,
    key,
    mouse,
    paste,
    resize,
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
