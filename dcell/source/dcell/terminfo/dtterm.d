// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.dtterm;

import dcell.database;

// dtterm
static immutable Termcap term0 = {
    name: "dtterm",
    lines: 24,
    colors: 8,
    bell: "\x07",
    clear: "\x1b[H\x1b[J",
    showCursor: "\x1b[?25h",
    hideCursor: "\x1b[?25l",
    attrOff: "\x1b[m\x0f",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    blink: "\x1b[5m",
    reverse: "\x1b[7m",
    dim: "\x1b[2m",
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
    keyHelp: "\x1b[28~",
    keyPgUp: "\x1b[5~",
    keyPgDn: "\x1b[6~",
    keyUp: "\x1b[A",
    keyDown: "\x1b[B",
    keyLeft: "\x1b[D",
    keyRight: "\x1b[C",
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
