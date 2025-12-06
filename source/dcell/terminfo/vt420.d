// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt420;

import dcell.database;

// vt420
static immutable Termcap term0 = {
    name: "vt420",
    lines: 24,
    bell: "\x07",
    clear: "\x1b[H\x1b[2J",
    attrOff: "\x1b[m",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    blink: "\x1b[5m",
    reverse: "\x1b[7m",
    enterKeypad: "\x1b=",
    exitKeypad: "\x1b>",
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
