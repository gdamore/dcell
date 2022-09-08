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
    padChar: "\x00",
    keyBackspace: "",
    keyF1: "\x1bOP",
    keyF2: "\x1bOQ",
    keyF3: "\x1bOR",
    keyF4: "\x1bOS",
    keyF6: "\x1b[17~",
    keyF7: "\x1b[18~",
    keyF8: "\x1b[19~",
    keyF9: "\x1b[20~",
    keyF10: "\x1b[21~",
    keyF11: "\x1b[23~",
    keyF12: "\x1b[24~",
    keyF13: "\x1b[25~",
    keyF14: "\x1b[26~",
    keyF15: "\x1b[28~",
    keyF16: "\x1b[29~",
    keyF17: "\x1b[31~",
    keyF18: "\x1b[32~",
    keyF19: "\x1b[33~",
    keyF20: "\x1b[34~",
    keyInsert: "\x1b[2~",
    keyDelete: "\x1b[3~",
    keyHome: "\x1b[1~",
    keyPgUp: "\x1b[5~",
    keyPgDn: "\x1b[6~",
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
