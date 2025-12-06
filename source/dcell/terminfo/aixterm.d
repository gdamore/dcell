// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.aixterm;

import dcell.database;

// aixterm
static immutable Termcap term0 = {
    name: "aixterm",
    lines: 25,
    colors: 8,
    bell: "\x07",
    clear: "\x1b[H\x1b[J",
    attrOff: "\x1b[0;10m\x1b(B",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    reverse: "\x1b[7m",
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[32m\x1b[40m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    altChars: "jjkkllmmnnqqttuuvvwwxx",
    automargin: true,
};

// aixterm-16color
static immutable Termcap term1 = {
    name: "aixterm-16color",
    lines: 25,
    colors: 16,
    bell: "\x07",
    clear: "\x1b[H\x1b[J",
    attrOff: "\x1b[0;10m\x1b(B",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    reverse: "\x1b[7m",
    setFg: "\x1b[%?%p1%{8}%<%t%p1%{30}%+%e%p1%\'R\'%+%;%dm",
    setBg: "\x1b[%?%p1%{8}%<%t%p1%\'(\'%+%e%p1%{92}%+%;%dm",
    resetColors: "\x1b[32m\x1b[40m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    altChars: "jjkkllmmnnqqttuuvvwwxx",
    automargin: true,
};

static this()
{
    Database.put(&term0);
    Database.put(&term1);
}
