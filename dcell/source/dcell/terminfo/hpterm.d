// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.hpterm;

import dcell.database;

// hpterm
static immutable Termcap term0 = {
    name: "hpterm",
    aliases: ["X-hpterm"],
    lines: 24,
    bell: "\x07",
    clear: "\x1b&a0y0C\x1bJ",
    attrOff: "\x1b&d@",
    underline: "\x1b&dD",
    bold: "\x1b&dB",
    reverse: "\x1b&dB",
    dim: "\x1b&dH",
    enterKeypad: "\x1b&s1A",
    exitKeypad: "\x1b&s0A",
    setCursor: "\x1b&a%p1%dy%p2%dC",
    cursorBack1: "\x08",
    cursorUp1: "\x1bA",
    padChar: "\x00",
    keyBackspace: "\x08",
    keyF1: "\x1bp",
    keyF2: "\x1bq",
    keyF3: "\x1br",
    keyF4: "\x1bs",
    keyF5: "\x1bt",
    keyF6: "\x1bu",
    keyF7: "\x1bv",
    keyF8: "\x1bw",
    keyInsert: "\x1bQ",
    keyDelete: "\x1bP",
    keyHome: "\x1bh",
    keyPgUp: "\x1bV",
    keyPgDn: "\x1bU",
    keyUp: "\x1bA",
    keyDown: "\x1bB",
    keyLeft: "\x1bD",
    keyRight: "\x1bC",
    keyClear: "\x1bJ",
    enterACS: "\x0e",
    exitACS: "\x0f",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
