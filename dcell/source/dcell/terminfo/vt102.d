// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt102;

import dcell.database;

// vt102
static immutable Termcap term0 = {
    name: "vt102",
    lines: 24,
    bell: "\x07",
    clear: "\x1b[H\x1b[J$<50>",
    attrOff: "\x1b[m\x0f$<2>",
    underline: "\x1b[4m$<2>",
    bold: "\x1b[1m$<2>",
    blink: "\x1b[5m$<2>",
    reverse: "\x1b[7m$<2>",
    enterKeypad: "\x1b[?1h\x1b=",
    exitKeypad: "\x1b[?1l\x1b>",
    setCursor: "\x1b[%i%p1%d;%p2%dH$<5>",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A$<2>",
    padChar: "\x00",
    keyBackspace: "\x08",
    keyF1: "\x1bOP",
    keyF2: "\x1bOQ",
    keyF3: "\x1bOR",
    keyF4: "\x1bOS",
    keyF5: "\x1bOt",
    keyF6: "\x1bOu",
    keyF7: "\x1bOv",
    keyF8: "\x1bOl",
    keyF9: "\x1bOw",
    keyF10: "\x1bOx",
    keyUp: "\x1bOA",
    keyDown: "\x1bOB",
    keyLeft: "\x1bOD",
    keyRight: "\x1bOC",
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
