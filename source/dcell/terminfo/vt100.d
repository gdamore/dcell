// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt100;

import dcell.database;

// vt100
static immutable Termcap term0 = {
    name: "vt100",
    aliases: ["vt100-am"],
    lines: 24,
    bell: "\x07",
    clear: "\x1b[H\x1b[J",
    attrOff: "\x1b[m\x0f",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    blink: "\x1b[5m",
    reverse: "\x1b[7m",
    enterKeypad: "\x1b[?1h\x1b=",
    exitKeypad: "\x1b[?1l\x1b>",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    altChars: "``aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x0e",
    exitACS: "\x0f",
    enableACS: "\x1b(B\x1b)0",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
