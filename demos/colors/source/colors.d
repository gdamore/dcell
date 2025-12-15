/**
 * Color demo for dcell.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module color;

import core.time;
import std.stdio;
import std.string;
import std.random;
import std.range;
import dcell;

class ColorBoxes
{
    import std.random;

    int r;
    int g;
    int b;
    int ri;
    int gi;
    int bi;
    Random rng;
    enum inc = 8;
    int cnt;
    bool done;
    Screen s;

    bool flip() @safe
    {
        return (rng.uniform!ubyte() & 0x1) != 0;
    }

    this(Screen scr)
    {
        rng = rndGen();
        r = rng.uniform!ubyte();
        g = rng.uniform!ubyte();
        b = rng.uniform!ubyte();
        ri = inc;
        gi = inc / 4; // humans are very sensitive to green
        bi = inc;
        s = scr;
    }

    void makeBox() @safe
    {
        Coord wsz = s.size();
        dchar dc = ' ';
        Style style;
        cnt++;

        if (s.colors() == 0)
        {
            dchar[] glyphs = ['@', '#', '&', '*', '=', '%', 'Z', 'A'];
            dc = choice(glyphs, rng);
            if (flip())
                style.attr |= Attr.reverse;
            else
                style.attr &= ~Attr.reverse;
        }
        else
        {
            r += ri;
            g += gi;
            b += bi;
            if (r >= 256 || r < 0)
            {
                ri = -ri;
                r += ri;
            }
            if (g >= 256 || g < 0)
            {
                gi = -gi;
                g += gi;
            }
            if (b >= 256 || b < 0)
            {
                bi = -bi;
                b += bi;
            }
            if (cnt % (256 / inc) == 0)
            {
                if (flip())
                {
                    ri = -ri;
                }

                if (flip())
                {
                    gi = -gi;
                }

                if (flip())
                {
                    bi = -bi;
                }
            }
            style.bg = fromHex(
                int(r) << 16 | int(g) << 8 | int(b));
        }

        // half the width and half the height
        Coord c1 = Coord(wsz.x / 4, wsz.y / 4);
        Coord c2 = Coord(c1.x + wsz.x / 2, c1.y + wsz.y / 2);
        Coord pos = c1;
        Cell cell = Cell(dc, style);
        for (pos.y = c1.y; pos.y <= c2.y; pos.y++)
        {
            for (pos.x = c1.x; pos.x <= c2.x; pos.x++)
            {
                s[pos] = cell;
            }
        }
        s.show();
    }

    void handleEvent(Event ev) @safe
    {
        switch (ev.type)
        {
        case EventType.key:
            switch (ev.key.key)
            {
            case Key.esc, Key.enter:
                done = true;
                break;
            case Key.graph:
                // Ctrl-L (without other modifiers) used to force a redraw.
                if (ev.key.ch == 'l' && ev.key.mod == Modifiers.ctrl)
                {
                    s.resize();
                    s.sync();
                }
                break;
            default:

            }
            break;
        case EventType.resize:
            s.resize();
            break;
        case EventType.closed:
            done = true;
            break;
        case EventType.error:
            assert(0, "error received");
        default:
        }
    }

    void run() @safe
    {
        s.start();
        scope (exit)
        {
            s.stop();
        }
        done = false;
        makeBox();
        while (!done)
        {
            loop: foreach (ev; s.events())
            {
                switch (ev.type)
                {
                case EventType.key:
                    switch (ev.key.key)
                    {
                    case Key.esc, Key.enter:
                        done = true;
                        break loop;
                    case Key.graph:
                        // Ctrl-L (without other modifiers) used to force a redraw.
                        if (ev.key.ch == 'l' && ev.key.mod == Modifiers.ctrl)
                        {
                            s.resize();
                            s.sync();
                        }
                        break;
                    default:
                    }
                    break;
                case EventType.resize:
                    s.resize();
                    break;
                case EventType.closed:
                    done = true;
                    break loop;
                case EventType.error:
                    assert(0, "error received");
                default:
                }
            }
            makeBox();
            s.position = Coord(1, 1);
            s.waitForEvent(msecs(50));
        }
    }
}

void main()
{
    import std.stdio;
    import core.time;
    import core.stdc.stdlib;

    ColorBoxes cb = new ColorBoxes(newScreen());

    auto now = MonoTime.currTime();
    cb.run();
    auto end = MonoTime.currTime();
    writefln("Drew %d boxes in %s.", cb.cnt, end - now);
    writefln("Average per box %s.", (end - now) / cb.cnt);
}
