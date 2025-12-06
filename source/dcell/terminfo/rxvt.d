// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.rxvt;

import dcell.database;

// rxvt
static immutable Termcap term0 = {
    name: "rxvt",
    lines: 24,
    colors: 8,
    bell: "\x07",
    clear: "\x1b[H\x1b[2J",
    enterCA: "\x1b7\x1b[?47h",
    exitCA: "\x1b[2J\x1b[?47l\x1b8",
    showCursor: "\x1b[?25h",
    hideCursor: "\x1b[?25l",
    attrOff: "\x1b[m\x0f",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    blink: "\x1b[5m",
    reverse: "\x1b[7m",
    enterKeypad: "\x1b=",
    exitKeypad: "\x1b>",
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[39;49m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    insertChar: "\x1b[@",
    mouse: "\x1b[M",
    altChars: "``aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x0e",
    exitACS: "\x0f",
    enableACS: "\x1b(B\x1b)0",
    automargin: true,
};

// rxvt-16color
static immutable Termcap term1 = {
    name: "rxvt-16color",
    lines: 24,
    colors: 16,
    bell: "\x07",
    clear: "\x1b[H\x1b[2J",
    enterCA: "\x1b7\x1b[?47h",
    exitCA: "\x1b[2J\x1b[?47l\x1b8",
    showCursor: "\x1b[?25h",
    hideCursor: "\x1b[?25l",
    attrOff: "\x1b[m\x0f",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    blink: "\x1b[5m",
    reverse: "\x1b[7m",
    enterKeypad: "\x1b=",
    exitKeypad: "\x1b>",
    setFg: "\x1b[%?%p1%{8}%<%t%p1%{30}%+%e%p1%\'R\'%+%;%dm",
    setBg: "\x1b[%?%p1%{8}%<%t%p1%\'(\'%+%e%p1%{92}%+%;%dm",
    resetColors: "\x1b[39;49m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    insertChar: "\x1b[@",
    mouse: "\x1b[M",
    altChars: "``aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x0e",
    exitACS: "\x0f",
    enableACS: "\x1b(B\x1b)0",
};

// rxvt-88color
static immutable Termcap term2 = {
    name: "rxvt-88color",
    lines: 24,
    colors: 88,
    bell: "\x07",
    clear: "\x1b[H\x1b[2J",
    enterCA: "\x1b7\x1b[?47h",
    exitCA: "\x1b[2J\x1b[?47l\x1b8",
    showCursor: "\x1b[?25h",
    hideCursor: "\x1b[?25l",
    attrOff: "\x1b[m\x0f",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    blink: "\x1b[5m",
    reverse: "\x1b[7m",
    enterKeypad: "\x1b=",
    exitKeypad: "\x1b>",
    setFg: "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m",
    setBg: "\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m",
    resetColors: "\x1b[39;49m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    insertChar: "\x1b[@",
    mouse: "\x1b[M",
    altChars: "``aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x0e",
    exitACS: "\x0f",
    enableACS: "\x1b(B\x1b)0",
};

// rxvt-256color
static immutable Termcap term3 = {
    name: "rxvt-256color",
    lines: 24,
    colors: 256,
    bell: "\x07",
    clear: "\x1b[H\x1b[2J",
    enterCA: "\x1b7\x1b[?47h",
    exitCA: "\x1b[2J\x1b[?47l\x1b8",
    showCursor: "\x1b[?25h",
    hideCursor: "\x1b[?25l",
    attrOff: "\x1b[m\x0f",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    blink: "\x1b[5m",
    reverse: "\x1b[7m",
    enterKeypad: "\x1b=",
    exitKeypad: "\x1b>",
    setFg: "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m",
    setBg: "\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m",
    resetColors: "\x1b[39;49m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    insertChar: "\x1b[@",
    mouse: "\x1b[M",
    altChars: "``aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x0e",
    exitACS: "\x0f",
    enableACS: "\x1b(B\x1b)0",
};

static this()
{
    Database.put(&term0);
    Database.put(&term1);
    Database.put(&term2);
    Database.put(&term3);
}
