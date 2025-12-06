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
    padChar: "\x00",
    keyBackspace: "\x08",
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
    keyF17: "\x1b[31~",
    keyF18: "\x1b[32~",
    keyF19: "\x1b[33~",
    keyF20: "\x1b[34~",
    keyInsert: "\x1b[2~",
    keyHelp: "\x1b[28~",
    keyPgUp: "\x1b[5~",
    keyPgDn: "\x1b[6~",
    keyUp: "\x1b[A",
    keyDown: "\x1b[B",
    keyLeft: "\x1b[D",
    keyRight: "\x1b[C",
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
