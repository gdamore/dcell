// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

/**
 * Hello World (Dcell)
 */
module hello;

import std.stdio;
import std.string;
import std.concurrency;

import dcell;

void emitStr(Screen s, int x, int y, Style style, string str)
{
	// NB: this naively assumes only ASCII
	while (str != "") 
	{
		s[x, y] = Cell(str[0..1], style, 1);
		str = str[1..$];
		x += 1;
	}
}

void displayHelloWorld(Screen s)
{
	auto size = s.size();
	Style def;
	def.bg = Color.silver;
	def.fg = Color.black;
	s.setStyle(def);
	s.clear();
	Style style = {fg: Color.red, bg: Color.papayaWhip};
	emitStr(s, size.x / 2 - 9, size.y / 2 - 1, style, " Hello, World! ");
	emitStr(s, size.x / 2 - 11, size.y / 2 + 1, def, " Press ESC to exit. ");

	// this demonstrates a different method.
	// it places a red X in the center of the screen.
	s[$/2, $/2].text = "X";
	s[$/2, $/2].style.fg = Color.white;
	s[$/2, $/2].style.bg = Color.red;
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

	ts.start(thisTid());
	displayHelloWorld(ts);
	for (;;)
	{
		receive(
			(Event ev) { handleEvent(ts, ev); }
		);
	}
}
