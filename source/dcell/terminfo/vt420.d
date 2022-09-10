// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt420;

import dcell.database;

// vt420
static immutable Termcap term0 = {
    name: "vt420",
    lines: 24,
    bell: "\x07",
    clear: "\x1b[H\x1b[2J$<50>",
    attrOff: "\x1b[m$<2>",
    underline: "\x1b[4m",
    bold: "\x1b[1m$<2>",
    blink: "\x1b[5m$<2>",
    reverse: "\x1b[7m$<2>",
    enterKeypad: "\x1b=",
    exitKeypad: "\x1b>",
    setCursor: "\x1b[%i%p1%d;%p2%dH$<10>",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    padChar: "\x00",
    keyBackspace: "\x08",
    keyF1: "\x1bOP",
    keyF2: "\x1bOQ",
    keyF3: "\x1bOR",
    keyF4: "\x1bOS",
    keyF5: "\x1b[17~",
    keyF6: "\x1b[18~",
    keyF7: "\x1b[19~",
    keyF8: "\x1b[20~",
    keyF9: "\x1b[21~",
    keyF10: "\x1b[29~",
    keyInsert: "\x1b[2~",
    keyDelete: "\x1b[3~",
    keyPgUp: "\x1b[5~",
    keyPgDn: "\x1b[6~",
    keyUp: "\x1b[A",
    keyDown: "\x1b[B",
    keyLeft: "\x1b[D",
    keyRight: "\x1b[C",
    altChars: "``aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x1b(0$<2>",
    exitACS: "\x1b(B$<4>",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
