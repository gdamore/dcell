// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

/**
 * Mouse demo (demonstrates input handling)
 */
module mouse;

import std.stdio;
import std.string;
import std.concurrency;
import core.stdc.stdlib;

import dcell;

void emitStr(Screen s, Coord pos, Style style, dstring str)
{
	while (str != "")
	{
		s[pos] = Cell(str[0], style, 1);
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
	for (pos.y = c1.y; pos.y < c2.y; pos.y++)
	{
		for (pos.x = c1.x; pos.x < c2.x; pos.x++)
		{
			Cell c = s[pos];
			if (sel)
				c.style.attr |= Attr.reverse;
			else
				c.style.attr &= ~Attr.reverse;
			s[pos] = c;
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
	dstring bStr = "";
	dstring kStr = "";
	dstring pStr = "";
	bool pasting = false;

	s.start();
	s.showCursor(Cursor.hidden);
	s.enableMouse(MouseEnable.all);
	s.enablePaste(true);
	Style white;
	white.fg = Color.midnightBlue;
	white.bg = Color.lightCoral;
	Coord mousePos = Coord(-1, -1);
	Coord oldTop = Coord(-1, -1);
	Coord oldBot = Coord(-1, -1);
	Coord bPos;
	int esc = 0;
	dchar lb;

	for (;;)
	{
		auto ps = pStr;
		if (ps.length > 25)
			ps = "..." ~ ps[$ - 23 .. $];
		drawBox(s, Coord(1, 1), Coord(42, 7), white);
		Coord pos = Coord(3, 2);
		emitStr(s, pos, white, "Press ESC twice to exit, C to clear.");
		pos.y++;
		emitStr(s, pos, white, format(posFmt, mousePos.x, mousePos.y));
		pos.y++;
		emitStr(s, pos, white, format(btnFmt, bStr));
		pos.y++;
		emitStr(s, pos, white, format(keyFmt, kStr));
		pos.y++;
		emitStr(s, pos, white, format(pasteFmt, pStr.length, ps));
		s.show();
		bStr = "";
		Event ev;
		receive(
			(Event ee) { ev = ee; }
		);
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
			case Key.ctrlL:
				s.sync();
				esc = 0;
				break;
			case Key.rune:
				if (ev.key.ch == 'C' || ev.key.ch == 'c')
				{
					s.clear();
				}
				kStr = [ev.key.ch];
				esc = 0;
				s[pos] = Cell('R', st);
				break;
			default:
				kStr = "Undecoded";
				break;
			}
			break;
		case EventType.mouse:
			if (ev.mouse.mod & Modifiers.shift)
				bStr ~= " S";
			if (ev.mouse.mod & Modifiers.ctrl)
				bStr ~= " C";
			if (ev.mouse.mod & Modifiers.alt)
				bStr ~= " A";
			if (ev.mouse.mod & Modifiers.meta)
				bStr ~= " M";
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
			button &= ~Buttons.wheelUp;
			button &= ~Buttons.wheelDown;
			button &= ~Buttons.wheelLeft;
			button &= ~Buttons.wheelRight;
			if (button == Buttons.none)
			{
				if (oldTop.x >= 0)
				{
					Style ns = up;
					ns.bg = (cast(Color)(lb - '0'));
					drawBox(s, oldTop, ev.mouse.pos, ns, lb);
					oldTop = Coord(-1, -1);
					oldBot = Coord(-1, -1);
				}
			}
			else if (oldTop.x < 0)
			{
				oldTop = ev.mouse.pos;
			}
			if (button & Buttons.button1)
				bStr ~= " B1";
			if (button & Buttons.button2)
				bStr ~= " B2";
			if (button & Buttons.button3)
				bStr ~= " B3";
			if (button & Buttons.button4)
				bStr ~= " B4";
			if (button & Buttons.button5)
				bStr ~= " B5";
			if (button & Buttons.button6)
				bStr ~= " B6";
			if (button & Buttons.button7)
				bStr ~= " B7";
			if (button & Buttons.button8)
				bStr ~= " B8";
			if (bStr.length > 0)
				lb = bStr[$ - 1];
			mousePos = ev.mouse.pos;
			if (button != Buttons.none)
				oldBot = ev.mouse.pos;

			s[pos] = Cell('M', st);
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
