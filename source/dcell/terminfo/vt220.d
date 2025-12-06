// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt220;

import dcell.database;

// vt220
static immutable Termcap term0 = {
    name: "vt220",
    aliases: ["vt200"],
    lines: 24,
    bell: "\x07",
    clear: "\x1b[H\x1b[J",
    attrOff: "\x1b[m\x1b(B",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    blink: "\x1b[5m",
    reverse: "\x1b[7m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    altChars: "``aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x1b(0",
    exitACS: "\x1b(B",
    enableACS: "\x1b)0",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
