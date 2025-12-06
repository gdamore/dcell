// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt320;

import dcell.database;

// vt320
static immutable Termcap term0 = {
    name: "vt320",
    aliases: ["vt300"],
    lines: 24,
    bell: "\x07",
    clear: "\x1b[H\x1b[2J",
    showCursor: "\x1b[?25h",
    hideCursor: "\x1b[?25l",
    attrOff: "\x1b[m\x1b(B",
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
    enterACS: "\x1b(0",
    exitACS: "\x1b(B",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
