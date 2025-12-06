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
