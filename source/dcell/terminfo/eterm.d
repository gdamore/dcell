// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.eterm;

import dcell.database;

// eterm
static immutable Termcap term0 = {
    name: "eterm",
    lines: 24,
    bell: "\x07",
    clear: "\x1b[H\x1b[J",
    enterCA: "\x1b7\x1b[?47h",
    exitCA: "\x1b[2J\x1b[?47l\x1b8",
    attrOff: "\x1b[m",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    reverse: "\x1b[7m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    padChar: "\x00",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
