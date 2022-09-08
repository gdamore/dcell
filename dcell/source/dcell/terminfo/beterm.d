// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.beterm;

import dcell.database;

// beterm
static immutable Termcap term0 = {
    name: "beterm",
    lines: 25,
    colors: 8,
    bell: "\x07",
    clear: "\x1b[H\x1b[J",
    attrOff: "\x1b[0;10m",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    reverse: "\x1b[7m",
    enterKeypad: "\x1b[?4h",
    exitKeypad: "\x1b[?4l",
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    padChar: "\x00",
    insertChar: "\x1b[@",
    keyBackspace: "\x08",
    keyF1: "\x1b[11~",
    keyF2: "\x1b[12~",
    keyF3: "\x1b[13~",
    keyF4: "\x1b[14~",
    keyF5: "\x1b[15~",
    keyF6: "\x1b[16~",
    keyF7: "\x1b[17~",
    keyF8: "\x1b[18~",
    keyF9: "\x1b[19~",
    keyF10: "\x1b[20~",
    keyF11: "\x1b[21~",
    keyF12: "\x1b[22~",
    keyInsert: "\x1b[2~",
    keyDelete: "\x1b[3~",
    keyHome: "\x1b[1~",
    keyEnd: "\x1b[4~",
    keyPgUp: "\x1b[5~",
    keyPgDn: "\x1b[6~",
    keyUp: "\x1b[A",
    keyDown: "\x1b[B",
    keyLeft: "\x1b[D",
    keyRight: "\x1b[C",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
