/**
 * Hello world demo for Dcell.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module hello;

import std.stdio;
import std.string;

import dcell;

void centerStr(Screen s, int y, Style style, string str)
{
    s.style = style;
    s.position = Coord((s.size.x - cast(int)(str.length)) / 2, y);
    s.write(str);
}

void displayHelloWorld(Screen s)
{
    auto size = s.size();
    Style def;
    def.bg = Color.silver;
    def.fg = Color.black;
    s.clear();
    Style style = {fg: Color.navy, bg: Color.papayaWhip};
    centerStr(s, size.y / 2 - 1, style, " Hello There! ");
    centerStr(s, size.y / 2 + 1, def, " Press ESC to exit. ");

    // this demonstrates a different method.
    // it places a red X in the center of the screen.
    s[$ / 2, $ / 2].text = "X";
    s[$ / 2, $ / 2].style.fg = Color.white;
    s[$ / 2, $ / 2].style.bg = Color.red;
    s.show();
}

void handleEvent(Screen ts, Event ev)
{
    import core.stdc.stdlib : exit;

    switch (ev.type)
    {
    case EventType.key:
        if (ev.key.key == Key.esc || ev.key.key == Key.f1)
        {
            ts.stop();
            exit(0);
        }
        break;
    case EventType.resize:
        ts.resize();
        displayHelloWorld(ts);
        ts.sync();
        break;
    default:
        break;
    }
}

void main()
{
    import std.stdio;

    auto ts = newScreen();
    assert(ts !is null);
    scope (exit)
    {
        ts.stop();
    }

    ts.start();
    displayHelloWorld(ts);
    for (;;)
    {
        ts.waitForEvent();
        foreach (ev; ts.events())
        {
            handleEvent(ts, ev);
        }
    }
}
