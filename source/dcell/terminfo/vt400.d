// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt400;

import dcell.database;

// vt400
static immutable Termcap term0 = {
    name: "vt400",
    aliases: ["vt400-24", "dec-vt400"],
    lines: 24,
    clear: "\x1b[H\x1b[J$<10/>",
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
    padChar: "\x00",
    insertChar: "\x1b[@",
    keyBackspace: "\x08",
    keyF1: "\x1bOP",
    keyF2: "\x1bOQ",
    keyF3: "\x1bOR",
    keyF4: "\x1bOS",
    keyF6: "\x1b[17~",
    keyF7: "\x1b[18~",
    keyF8: "\x1b[19~",
    keyF9: "\x1b[20~",
    keyUp: "\x1bOA",
    keyDown: "\x1bOB",
    keyLeft: "\x1bOD",
    keyRight: "\x1bOC",
    altChars: "``aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x1b(0",
    exitACS: "\x1b(B",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
