// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.wy99ansi;

import dcell.database;

// wy99-ansi
static immutable Termcap term0 = {
    name: "wy99-ansi",
    lines: 25,
    bell: "\x07",
    clear: "\x1b[H\x1b[J$<200>",
    showCursor: "\x1b[34h\x1b[?25h",
    hideCursor: "\x1b[?25l",
    attrOff: "\x1b[m\x0f\x1b[\"q",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    blink: "\x1b[5m",
    reverse: "\x1b[7m",
    dim: "\x1b[2m",
    enterKeypad: "\x1b[?1h",
    exitKeypad: "\x1b[?1l",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08$<1>",
    cursorUp1: "\x1bM",
    padChar: "\x00",
    keyBackspace: "\x08",
    keyF1: "\x1bOP",
    keyF2: "\x1bOQ",
    keyF3: "\x1bOR",
    keyF4: "\x1bOS",
    keyF5: "\x1b[M",
    keyF6: "\x1b[17~",
    keyF7: "\x1b[18~",
    keyF8: "\x1b[19~",
    keyF9: "\x1b[20~",
    keyF10: "\x1b[21~",
    keyF11: "\x1b[23~",
    keyF12: "\x1b[24~",
    keyF17: "\x1b[K",
    keyF18: "\x1b[31~",
    keyF19: "\x1b[32~",
    keyF20: "\x1b[33~",
    keyF21: "\x1b[34~",
    keyF22: "\x1b[35~",
    keyF23: "\x1b[1~",
    keyF24: "\x1b[2~",
    keyUp: "\x1bOA",
    keyDown: "\x1bOB",
    keyLeft: "\x1bOD",
    keyRight: "\x1bOC",
    keyBacktab: "\x1b[z",
    altChars: "``aaffggjjkkllmmnnooqqssttuuvvwwxx{{||}}~~",
    enterACS: "\x0e",
    exitACS: "\x0f",
    enableACS: "\x1b)0",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
