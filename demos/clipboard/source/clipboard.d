/**
 * Clipboard demo for Dcell.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module clipboard;

import std.stdio;
import std.string;
import std.conv;
import std.utf;

import dcell;

class Demo
{
    string content;
    Screen s;
    bool done = false;

    this(Screen scr) @safe
    {
        s = scr;
    }

    void centerStr(int y, Style style, string str) @safe
    {
        s.style = style;
        s.position = Coord((s.size.x - cast(int)(str.length)) / 2, y);
        s.write(str);
    }

    void display() @safe
    {
        auto size = s.size();
        Style def;
        def.bg = Color.black;
        def.fg = Color.white;
        s.clear();
        Style style = {fg: Color.cadetBlue, bg: Color.black};
        s.style = style;
        centerStr(size.y / 2 - 1, style, "Press 1 to set the clipboard");
        centerStr(size.y / 2 + 1, style, "Press 2 to get the clipboard");

        auto msg = "No clipboard data";
        if (!content.empty)
        {
            auto len = content.length;
            if (content.length >= 40)
            {
                msg = format("Clipboard (length %d): %s ...", len, content[0 .. 36]);
            }
            else
            {
                msg = format("Clipboard (length %d): %s", len, content);
            }
        }
        s.style = def;
        centerStr(size.y / 2 + 3, def, msg);
        centerStr(size.y / 2 + 5, def, "Press ESC to Exit.");

        s.show();
    }

    void handleEvent(Event ev)
    {
        switch (ev.type)
        {
        case EventType.key:
            if (ev.key.key == Key.esc || ev.key.key == Key.f1)
            {
                done = true;
            }
            else if (ev.key.key == Key.graph && ev.key.mod == Modifiers.none)
            {
                switch (ev.key.ch)
                {
                case '1':
                    s.setClipboard("Enjoy your new clipboard content!".representation);
                    break;
                case '2':
                    s.getClipboard();
                    break;
                default:
                }
            }

            break;
        case EventType.paste:
            if (ev.paste.content.length > 0)
            {
                content = ev.paste.content;
            }
            else if (ev.paste.binary.length > 0)
            {
                try
                {
                    auto chars = cast(char[])(ev.paste.binary);
                    validate(chars);
                    content = cast(string)(chars.idup);
                }
                catch (UTFException)
                {
                    content = "Invalid UTF-8";
                }
            }
            break;
        case EventType.resize:
            s.resize();
            display();
            s.sync();
            break;
        default:
            break;
        }
    }

    void run()
    {
        s.start();
        scope (exit)
        {
            s.stop();
        }

        display();
        s.enablePaste(true);
        while (!done)
        {
            s.waitForEvent();
            foreach (ev; s.events())
            {
                handleEvent(ev);
            }
            display();
        }

    }
}

void main()
{
    auto app = new Demo(newScreen());
    app.run();
}
