/**
 * Styles world demo for Dcell.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module styles;

import std.stdio;
import std.string;

import dcell;

void centerStr(Screen s, int y, Style style, string str)
{
    s.style = style;
    s.position = Coord((s.size.x - cast(int)(str.length)) / 2, y);
    s.write(str);
}

void displayStyles(Screen s)
{

    s.style.attr = Attr.bold;
    s.style.fg = Color.black;
    s.style.bg = Color.white;

    s.clear();

    s.style.fg = Color.blue;
    s.style.bg = Color.silver;

    int row = 2;
    s.position = Coord(2, row);
    s.write("Press ESC to Exit");
    row += 2;

    s.style.fg = Color.black;
    s.style.bg = Color.white;

    s.position = Coord(2, row);
    s.style.attr = Attr.none;
    s.write("Note: Style support is dependent on your terminal.");
    row += 2;

    s.style.attr = Attr.none;
    s.position = Coord(2, row++);
    s.write("Plain");

    s.style.attr = Attr.blink;
    s.position = Coord(2, row++);
    s.write("Blink");

    s.style.attr = Attr.reverse;
    s.position = Coord(2, row++);
    s.write("Reverse");

    s.style.attr = Attr.dim;
    s.position = Coord(2, row++);
    s.write("Dim");

    s.style.attr = Attr.underline;
    s.position = Coord(2, row++);
    s.write("Underline");

    s.style.attr = Attr.italic;
    s.position = Coord(2, row++);
    s.write("Italic");

    s.style.attr = Attr.bold;
    s.position = Coord(2, row++);
    s.write("Bold");

    s.style.attr = Attr.bold | Attr.italic;
    s.position = Coord(2, row++);
    s.write("Bold Italic");

    s.style.attr = Attr.bold | Attr.italic | Attr.underline;
    s.position = Coord(2, row++);
    s.write("Bold Italic Underline");

    s.style.attr = Attr.strikethrough;
    s.position = Coord(2, row++);
    s.write("Strikethrough");

    s.style.attr = Attr.doubleUnderline;
    s.position = Coord(2, row++);
    s.write("Double Underline");

    s.style.attr = Attr.curlyUnderline;
    s.position = Coord(2, row++);
    s.write("Curly Underline");

    s.style.attr = Attr.dottedUnderline;
    s.position = Coord(2, row++);
    s.write("Dotted Underline");

    s.style.attr = Attr.dashedUnderline;
    s.position = Coord(2, row++);
    s.write("Dashed Underline");

    s.style.attr = Attr.underline;
    s.style.ul = Color.blue;
    s.position = Coord(2, row++);
    s.write("Blue Underline");

    s.style.attr = Attr.curlyUnderline;
    s.style.ul = fromHex(0xc58af9);
    s.position = Coord(2, row++);
    s.write("Lavender Curly Underline");

    s.style.attr = Attr.none;
    s.style.ul = Color.invalid;
    s.position = Coord(2, row++);
    s.style.url = "https://github.com/gdamore/dcell";
    s.write("Hyperlink");
    s.style.url = "";

    s.style.attr = Attr.none;
    s.style.fg = Color.red;
    s.position = Coord(2, row++);
    s.write("Red Foreground");

    s.style.attr = Attr.none;
    s.style.bg = Color.red;
    s.style.fg = Color.black;
    s.position = Coord(2, row++);
    s.write("Red Background");

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
        displayStyles(ts);
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

    displayStyles(ts);
    for (;;)
    {
        Event ev = ts.waitEvent();
        handleEvent(ts, ev);
    }
}
