// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

/**
 * Hello World (Dcell)
 */
module mkinfo;

import std.stdio;
import std.string;
import std.concurrency;

import dcell;

void emitStr(Screen s, int x, int y, Style style, string str)
{
	while (str != "") 
	{
		s[Coord(x, y)] = Cell(str[0..1], style, 1);
		str = str[1..$];
		x += 1;
	}
}

void displayHelloWorld(Screen s)
{
	auto size = s.size();
	s.clear();
	Style style = {fg: Color.teal, bg: Color.red};
	emitStr(s, size.x / 2 - 7, size.y / 2, style, "Hello, World!");
	emitStr(s, size.x / 2 - 9, size.y / 2 + 1, Style(), "Press ESC to exit.");
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
	import dcell.terminfo.xterm256color;

	auto ts = newScreen();
	assert(ts !is null);

	ts.start();
	displayHelloWorld(ts);
	for (;;)
	{
		receive(
			(Event ev) { handleEvent(ts, ev); }
		);
	}
}
