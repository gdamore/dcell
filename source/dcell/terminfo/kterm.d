// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.kterm;

import dcell.database;

// kterm
static immutable Termcap term0 = {
    name: "kterm",
    lines: 24,
    colors: 8,
    bell: "\x07",
    clear: "\x1b[H\x1b[2J",
    enterCA: "\x1b7\x1b[?47h",
    exitCA: "\x1b[2J\x1b[?47l\x1b8",
    attrOff: "\x1b[m\x1b(B",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    reverse: "\x1b[7m",
    enterKeypad: "\x1b[?1h\x1b=",
    exitKeypad: "\x1b[?1l\x1b>",
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[39;49m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    padChar: "\x00",
    keyBackspace: "\x08",
    keyF1: "\x1b[11~",
    keyF2: "\x1b[12~",
    keyF3: "\x1b[13~",
    keyF4: "\x1b[14~",
    keyF5: "\x1b[15~",
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
    keyPgUp: "\x1b[5~",
    keyPgDn: "\x1b[6~",
    keyUp: "\x1bOA",
    keyDown: "\x1bOB",
    keyLeft: "\x1bOD",
    keyRight: "\x1bOC",
    mouse: "\x1b[M",
    altChars: "``aajjkkllmmnnooppqqrrssttuuvvwwxx~~",
    enterACS: "\x1b(0",
    exitACS: "\x1b(B",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
