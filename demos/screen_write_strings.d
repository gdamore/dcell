/+ dub.sdl:
    name "screen_write_strings"
    description "Demo showcasing Screen string/style write helpers"
    dependency "dcell" path=".."
    targetType "executable"
 +/

// SPDX-License-Identifier: BSL-1.0

/**
 * Demo: Screen string and style writing helpers.
 *
 * This tiny demo showcases the convenience helpers added to `Screen`:
 *  - Single-cell string assignment via index operators: `screen[x, y] = "A"` and `screen[Coord(x,y)] = "Z"`.
 *  - Style assignment via index operators: `screen[x, y] = someStyle;` (preserves existing text).
 *  - Multi-cell string write with truncation: `screen.write(x, y, s);`
 *  - Multi-cell string write with wrapping: `screen.writeWrap(x, y, s);`
 *  - Styled variants that apply a uniform style across written cells.
 *
 * Press ESC (or F1) to exit. Resizing the terminal will redraw the content.
 */
module screen_write_strings;

import std.concurrency : thisTid, receive;
import dcell; // public imports provide Screen, Style, Color, Key, Event, etc.

private void draw(Screen s)
{
    auto sz = s.size();

    // Set a pleasant default background for readability.
    Style def; def.bg = Color.silver; def.fg = Color.black;
    s.setStyle(def);
    s.clear();

    // Title centered using opDollar ($) and Coord overloads later below.
    Style title; title.fg = Color.white; title.bg = Color.darkBlue; title.attr = Attr.bold;
    string titleText = "Screen.write* demo";
    // Use truncate write for the title (it will naturally truncate if terminal is very small).
    int titleX = (sz.x - cast(int) titleText.length) / 2;
    if (titleX < 0) titleX = 0;
    s.write(cast(size_t) titleX, 0, titleText, title);

    // 1) Single-cell string assignment via index operators.
    s[2, 2] = "A";                 // string write (preserves style)
    s[3, 2] = "角";                // non-ASCII example
    s[4, 2] = "\n";               // control normalized to space
    s[Coord(5, 2)] = "Z";          // Coord overload

    s.write(1, 4, "Дејан Лекић"); // Serbian cyrillic
    s.write(1, 5, "Dejan Lekić"); // Serbian latin

    // 2) Style assignment via index operators, preserving text.
    // Seed a cell's text then apply style only.
    s[8, 2] = "S";
    Style emph; emph.fg = Color.yellow; emph.bg = Color.maroon; emph.attr = Attr.bold | Attr.underline;
    s[8, 2] = emph;                 // apply style, text stays "S"

    // 3) Multi-cell string write (truncate at end of row).
    string truncMsg = "This will truncate at row end";
    size_t tx = cast(size_t) (sz.x > 24 ? sz.x - 24 : 0);
    s.write(tx, 4, truncMsg);       // preserves existing styles

    // 4) Multi-cell string write with wrapping.
    string wrapMsg = "Wrapping across rows using writeWrap(...)";
    size_t wx = (sz.x > 6) ? cast(size_t) (sz.x - 6) : 0; // start near the right edge
    s.writeWrap(wx, 6, wrapMsg);

    // 5) Styled variants: apply a uniform style while writing.
    Style banner; banner.fg = Color.black; banner.bg = Color.papayaWhip; banner.attr = Attr.reverse;
    s.write(2, 8, "Styled truncate", banner);
    s.writeWrap(2, 10, "Styled wrapping continues to next line if needed", banner);

    // 6) Coord overloads for write helpers and use of $ for center marker.
    s.write(Coord(2, 12), "Coord overload works →" );
    s[$/2, $/2] = "+";            // center marker

    s.show();
}

private void handleEvent(Screen s, Event ev)
{
    import core.stdc.stdlib : exit;
    switch (ev.type)
    {
    case EventType.key:
        if (ev.key.key == Key.esc || ev.key.key == Key.f1)
        {
            s.stop();
            exit(0);
        }
        break;
    case EventType.resize:
        s.resize();
        draw(s);
        s.sync();
        break;
    default:
        break;
    }
}

void main()
{
    auto screen = newScreen();
    assert(screen !is null);

    screen.start(thisTid());
    draw(screen);
    for (;;)
    {
        receive((Event ev) { handleEvent(screen, ev); });
    }
}
