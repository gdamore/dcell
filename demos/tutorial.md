# _Dcell_ Tutorial

_Dcell_ provides a low-level, portable API for building terminal-based programs.
A [terminal emulator](https://en.wikipedia.org/wiki/Terminal_emulator)
(or a real terminal such as a DEC VT-220) is used to interact with such a program.

_Dcell_'s interface is fairly low-level.
While it provides a reasonably portable way of dealing with all the usual terminal
features, it may be easier to utilize a higher level framework.
A number of such frameworks are listed on the _Dcell_ main [README](README.md).

This tutorial provides the details of _Dcell_, and is appropriate for developers
wishing to create their own application frameworks or needing more direct access
to the terminal capabilities.

## Resize events

Applications receive an event of type `EventType.resize` when they are first initialized and each time the terminal is resized.

```d
switch (ev.type)
            {
case EventType.resize:
    s.resize();
    s.sync();
    info(i"Resized to $(ev.mouse.pos)");
    break;
}
```

## Key events

When a key is pressed, applications receive an event of type `EventType.Key`.
This event describes the modifier keys pressed (if any) and the pressed key or rune.

When a Esc key is pressed, an event with its `ev.key.key` set to `Key.esc` is dispatched.

When other key is pressed, it is available as the `Key.graph` of the event.

```d
switch (ev.key.key)
{
case Key.esc:
    {
    		info(i"Esc key was pressed");
        s.stop();
        exit(0);
    }
    break;
case Key.graph:
    {
        info(i"Key $(ev.key.ch) was pressed with Modifier $(ev.key.mod)");
    }
```

### Key event restrictions

Terminal-based programs have less visibility into keyboard activity than graphical applications.

When a key is pressed and held, additional key press events are sent by the terminal emulator.
The rate of these repeated events depends on the emulator's configuration.
Key release events are not available.

It is not possible to distinguish runes typed while holding shift and runes typed using caps lock.
Capital letters are reported without the Shift modifier.

## Mouse events

Applications receive an event of type `EventType.mouse` when the mouse moves, or a mouse button is pressed or released.
Mouse events are only delivered if
`enableMouse` has been called.

The mouse buttons being pressed (if any) are available as `ev.mouse.btn`, and the position of the mouse is available as `ev.mouse.pos`.

```d
switch (ev.type)
{
case EventType.mouse:
    auto pos = ev.mouse.pos;
    auto btn = ev.mouse.btn;
    info(i"EventMouse Buttons: $(btn) Position: $(pos)");
}
```

### Mouse buttons

Identifier | Alias           | Description
-----------|-----------------|-----------
Button1    | ButtonPrimary   | Left button
Button2    | ButtonSecondary | Right button
Button3    | ButtonMiddle    | Middle button
Button4    |                 | Side button (thumb/next)
Button5    |                 | Side button (thumb/prev)
WheelUp    |                 | Scroll wheel up
WheelDown  |                 | Scroll wheel down
WheelLeft  |                 | Horizontal wheel left
WheelRight |                 | Horizontal wheel right

## Usage

To create a _Dcell_ application, first initialize a screen to hold it.

```d
auto s = newScreen();
assert(s !is null);
scope (exit)
{
    s.stop();
}

// Set default text style
Style def;
def.bg = Color.silver;
def.fg = Color.black;
s.style = def;

// Clear screen
s.clear();
```

Text may be drawn on the screen using `put` or `write`.

```d
s.write(text);
```


To draw text more easily with wrapping, define a render function.

```d
void drawText(Screen s, Coord c1, Coord c2, Style style, string text)
{
    auto row = c1.y;
    auto col = c1.x;
    auto width = c2.x - c1.x;
    int printed = 0;
    while (printed < text.length)
    {
        if (width >= text[printed .. $].length)
        {
            s.style = style;
            s.position = Coord(col, row);
            s.write(text[printed .. $]);
            break;
        }
        else
        {
            s.style = style;
            s.position = Coord(col, row);
            s.write(text[printed .. printed + width]);
            printed += width;
            row++;
            col = c1.x;
            if (row > c2.y)
                break;
        }
    }
}
```

Lastly, define an event loop to handle user input and update application state.

```d
scope (exit)
{
    s.stop();
}
for (;;)
{
    // Update screen
    s.show();
    // Poll event (can be used in select statement as well)
    s.waitForEvent();

foreach (ev; s.events())
{
    switch (ev.type)
    {
    case EventType.key:
        // Process event
        switch (ev.key.key)
        {
        case Key.esc:
            {
                s.stop();
                exit(0);
            }
            break;
        default:
            break;
        }
        break;
    case EventType.resize:
        s.resize();
        s.sync();
        break;
    }
}
```

## Demo application

The following demonstrates how to initialize a screen, draw text/graphics and handle user input.

```d
import std.stdio;
import std.string;
import std.conv;

import dcell;

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

void drawText(Screen s, Coord c1, Coord c2, Style style, string text)
{
    auto row = c1.y;
    auto col = c1.x;
    auto width = c2.x - c1.x;
    int printed = 0;
    while (printed < text.length)
    {
        if (width >= text[printed .. $].length)
        {
            s.style = style;
            s.position = Coord(col, row);
            s.write(text[printed .. $]);
            break;
        }
        else
        {
            s.style = style;
            s.position = Coord(col, row);
            s.write(text[printed .. printed + width]);
            printed += width;
            row++;
            col = c1.x;
            if (row > c2.y)
                break;
        }
    }
}

void drawBox(Screen s, Coord c1, Coord c2, Style style, string text, dchar fill = ' ')
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

    auto newc1 = Coord(c1.x + 1, c1.y + 1);
    auto newc2 = Coord(c2.x - 1, c2.y - 1);
    drawText(s, newc1, newc2, style, text);
}

void main()
{
    import core.stdc.stdlib : exit;

    auto s = newScreen();
    assert(s !is null);
    scope (exit)
    {
        s.stop();
    }

    s.start();
    s.showCursor(Cursor.hidden);
    s.enableMouse(MouseEnable.all);
    s.enablePaste(true);
    s.setTitle("Dcell Event Demo");

    Style def;
    def.bg = Color.silver;
    def.fg = Color.black;
    s.style = def;
    Style boxStyle = {fg: Color.navy, bg: Color.papayaWhip};
    s.clear();

    drawBox(s, Coord(1, 1), Coord(42, 7), boxStyle, "Click and drag to draw a box");
    drawBox(s, Coord(5, 9), Coord(32, 14), boxStyle, "Press ESC to reset");

    auto oldPos = Coord(-1, -1);
    for (;;)
    {
        s.show();
        s.waitForEvent();
        foreach (ev; s.events())
        {
            switch (ev.type)
            {
            case EventType.key:
                switch (ev.key.key)
                {
                case Key.esc:
                    {
                        s.stop();
                        exit(0);
                    }
                    break;
                case Key.graph:
                    if (ev.key.ch == 'C' || ev.key.ch == 'c')
                    {
                        s.style = def;
                        s.clear();
                    }
                    else if ((ev.key.ch == 'C' || ev.key.ch == 'c') && ev.key.mod == Modifiers.ctrl)
                    {
                        s.stop();
                        exit(0);
                    }
                    // Ctrl-L (without other modifiers) is used to redraw (UNIX convention)
                    else if (ev.key.ch == 'l' && ev.key.mod == Modifiers.ctrl)
                    {
                        s.sync();
                    }
                    break;
                default:
                    break;
                }
                break;
            case EventType.resize:
                s.resize();
                s.sync();
                break;
            case EventType.mouse:
                auto curPos = ev.mouse.pos;
                switch (ev.mouse.btn)
                {
                case Buttons.none:
                    if (oldPos.x >= 0)
                    {
                        string label = i"$(oldPos) to $(curPos)".text;
                        drawBox(s, oldPos, curPos, boxStyle, label);
                        oldPos = Coord(-1, -1);
                    }
                    break;
                case Buttons.button1:
                    if (oldPos.x < 0)
                    {
                        oldPos = curPos;
                    }
                    break;
                default:
                    break;
                }
                break;
            default:
                break;
            }
        }
    }
}
```
