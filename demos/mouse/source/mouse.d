/**
 * Mouse demo for dcell.  This demonstrates various forms of input handling.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module mouse;

import std.stdio;
import std.string;
import core.stdc.stdlib;

import dcell;

void emitStr(Screen s, Coord pos, Style style, dstring str)
{
    while (str != "")
    {
        s[pos] = Cell(str[0], style);
        str = str[1 .. $];
        pos.x++;
    }
}

void order(ref int i1, ref int i2)
{
    if (i2 < i1)
    {
        int v = i1;
        i1 = i2;
        i2 = v;
    }
}

void order(ref Coord c1, ref Coord c2)
{
    order(c1.x, c2.x);
    order(c1.y, c2.y);
}

void drawBox(Screen s, Coord c1, Coord c2, Style style, dchar fill = ' ')
{
    order(c1, c2);
    Coord pos;
    for (pos.x = c1.x; pos.x <= c2.x; pos.x++)
    {
        s[Coord(pos.x, c1.y)] = Cell(Glyph.horizLine, style);
        s[Coord(pos.x, c2.y)] = Cell(Glyph.horizLine, style);
    }
    for (pos.y = c1.y + 1; pos.y < c2.y; pos.y++)
    {
        s[Coord(c1.x, pos.y)] = Cell(Glyph.vertLine, style);
        s[Coord(c2.x, pos.y)] = Cell(Glyph.vertLine, style);
    }
    if (c1.y != c2.y && c1.x != c2.x)
    {
        s[Coord(c1.x, c1.y)] = Cell(Glyph.upperLeftCorner, style);
        s[Coord(c2.x, c1.y)] = Cell(Glyph.upperRightCorner, style);
        s[Coord(c1.x, c2.y)] = Cell(Glyph.lowerLeftCorner, style);
        s[Coord(c2.x, c2.y)] = Cell(Glyph.lowerRightCorner, style);
    }
    for (pos.y = c1.y + 1; pos.y < c2.y; pos.y++)
    {
        for (pos.x = c1.x + 1; pos.x < c2.x; pos.x++)
        {
            s[pos] = Cell(fill, style);
        }
    }
}

void drawSelect(Screen s, Coord c1, Coord c2, bool sel)
{
    order(c1, c2);
    Coord pos;
    for (pos.y = c1.y; pos.y <= c2.y; pos.y++)
    {
        for (pos.x = c1.x; pos.x <= c2.x; pos.x++)
        {
            if (sel)
                s[pos].style.attr |= Attr.reverse;
            else
                s[pos].style.attr &= ~Attr.reverse;
        }
    }
}

void main()
{
    import std.stdio;

    auto s = newScreen();
    assert(s !is null);

    dstring posFmt = "Mouse: %d, %d";
    dstring btnFmt = "Buttons: %s";
    dstring keyFmt = "Keys: %s";
    dstring pasteFmt = "Paste: [%d] %s";
    dstring focusFmt = "Focus: %s";
    dstring bStr = "";
    dstring kStr = "";
    dstring pStr = "";

    s.start();
    s.showCursor(Cursor.hidden);
    s.enableMouse(MouseEnable.all);
    s.enablePaste(true);
    s.enableFocus(true);
    Style white;
    white.fg = Color.midnightBlue;
    white.bg = Color.lightCoral;
    Coord mousePos = Coord(-1, -1);
    Coord oldTop = Coord(-1, -1);
    Coord oldBot = Coord(-1, -1);
    int esc = 0;
    dchar lb;
    bool focused = true;

    for (;;)
    {
        auto ps = pStr;
        if (ps.length > 25)
            ps = "..." ~ ps[$ - 23 .. $];
        drawBox(s, Coord(1, 1), Coord(42, 8), white);
        Coord pos = Coord(3, 2);
        emitStr(s, pos, white, "Press ESC twice to exit, C to clear.");
        pos.y++;
        emitStr(s, pos, white, format(posFmt, mousePos.x, mousePos.y));
        pos.y++;
        emitStr(s, pos, white, format(btnFmt, bStr));
        pos.y++;
        emitStr(s, pos, white, format(keyFmt, kStr));
        pos.y++;
        emitStr(s, pos, white, format(focusFmt, focused));
        pos.y++;
        emitStr(s, pos, white, format(pasteFmt, pStr.length, ps));
        s.show();
        Event ev = s.waitEvent();
        Style st;
        st.bg = Color.red;
        Style up;
        up.bg = Color.blue;
        up.fg = Color.black;
        // clear previous selection
        if (oldTop.x >= 0 && oldTop.y >= 0 && oldBot.x >= 0)
        {
            drawSelect(s, oldTop, oldBot, false);
        }
        pos = s.size();
        pos.x--;
        pos.y--;

        switch (ev.type)
        {
        case EventType.resize:
            s.resize();
            s.sync();
            break;
        case EventType.paste:
            pStr = ev.paste.content;
            break;
        case EventType.key:
            pStr = "";
            s[pos] = Cell('K', st);
            switch (ev.key.key)
            {
            case Key.esc:
                esc++;
                if (esc > 1)
                {
                    s.stop();
                    exit(0);
                }
                break;
            case Key.graph:
                if (ev.key.ch == 'C' || ev.key.ch == 'c')
                {
                    s.clear();
                }
                // Ctrl-L (without other modifiers) is used to redraw (UNIX convention)
                else if (ev.key.ch == 'l' && ev.key.mod == Modifiers.ctrl)
                {
                    s.sync();
                }
                esc = 0;
                s[pos] = Cell('R', st);
                break;
            default:
                break;
            }
            kStr = ev.key.toString();
            break;
        case EventType.mouse:
            bStr = "";

            if (ev.mouse.mod & Modifiers.shift)
                bStr ~= " S";
            if (ev.mouse.mod & Modifiers.ctrl)
                bStr ~= " C";
            if (ev.mouse.mod & Modifiers.alt)
                bStr ~= " A";
            if (ev.mouse.mod & Modifiers.meta)
                bStr ~= " M";
            if (ev.mouse.mod & Modifiers.hyper)
                bStr ~= " H";
            if (ev.mouse.btn & Buttons.wheelUp)
                bStr ~= " WU";
            if (ev.mouse.btn & Buttons.wheelDown)
                bStr ~= " WD";
            if (ev.mouse.btn & Buttons.wheelLeft)
                bStr ~= " WL";
            if (ev.mouse.btn & Buttons.wheelRight)
                bStr ~= " WR";
            // we only want buttons, not wheel events
            auto button = ev.mouse.btn;
            button &= 0xff;

            if ((button != Buttons.none) && (oldTop.x < 0))
            {
                oldTop = ev.mouse.pos;
            }

            // NB: this does is the unmasked value!
            // It also does not support chording mouse buttons
            switch (ev.mouse.btn)
            {
            case Buttons.none:
                if (oldTop.x >= 0)
                {
                    Style ns = up;
                    ns.bg = (cast(Color)(lb - '0'));
                    drawBox(s, oldTop, ev.mouse.pos, ns, lb);
                    oldTop = Coord(-1, -1);
                    oldBot = Coord(-1, -1);
                }
                break;
            case Buttons.button1:
                lb = '1';
                bStr ~= " B1";
                break;
            case Buttons.button2:
                lb = '2';
                bStr ~= " B2";
                break;
            case Buttons.button3:
                lb = '3';
                bStr ~= " B3";
                break;
            case Buttons.button4:
                lb = '4';
                bStr ~= " B4";
                break;
            case Buttons.button5:
                lb = '5';
                bStr ~= " B5";
                break;
            case Buttons.button6:
                lb = '6';
                bStr ~= " B6";
                break;
            case Buttons.button7:
                lb = '7';
                bStr ~= " B7";
                break;
            case Buttons.button8:
                lb = '8';
                bStr ~= " B8";
                break;
            default:
                lb = '?';
                break;
            }
            // mousePos = ev.mouse.pos;
            if (button != Buttons.none)
                oldBot = ev.mouse.pos;

            mousePos = ev.mouse.pos;
            s[pos] = Cell('M', st);
            break;
        case EventType.focus:
            focused = ev.focus.focused;
            break;
        default:
            s[pos] = Cell('X', st);
            break;
        }
        if (oldTop.x >= 0 && oldBot.x >= 0)
        {
            drawSelect(s, oldTop, oldBot, true);
        }
    }
}
