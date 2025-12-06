// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.alacritty;

import dcell.database;

// alacritty
static immutable Termcap term0 = {
    name: "alacritty",
    lines: 24,
    colors: 256,
    bell: "\x07",
    clear: "\x1b[H\x1b[2J",
    enterCA: "\x1b[?1049h\x1b[22;0;0t",
    exitCA: "\x1b[?1049l\x1b[23;0;0t",
    showCursor: "\x1b[?12l\x1b[?25h",
    hideCursor: "\x1b[?25l",
    attrOff: "\x1b(B\x1b[m",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    reverse: "\x1b[7m",
    dim: "\x1b[2m",
    italic: "\x1b[3m",
    enterKeypad: "\x1b[?1h\x1b=",
    exitKeypad: "\x1b[?1l\x1b>",
    setFg: "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m",
    setBg: "\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m",
    resetColors: "\x1b[39;49m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    mouse: "\x1b[M",
    altChars: "``aaffggiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x1b(0",
    exitACS: "\x1b(B",
    automargin: true,
};

// alacritty-direct
static immutable Termcap term1 = {
    name: "alacritty-direct",
    lines: 24,
    bell: "\x07",
    clear: "\x1b[H\x1b[2J",
    enterCA: "\x1b[?1049h\x1b[22;0;0t",
    exitCA: "\x1b[?1049l\x1b[23;0;0t",
    showCursor: "\x1b[?12l\x1b[?25h",
    hideCursor: "\x1b[?25l",
    attrOff: "\x1b(B\x1b[m",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    reverse: "\x1b[7m",
    dim: "\x1b[2m",
    italic: "\x1b[3m",
    enterKeypad: "\x1b[?1h\x1b=",
    exitKeypad: "\x1b[?1l\x1b>",
    setFg: "\x1b[%?%p1%{8}%<%t3%p1%d%e38:2::%p1%{65536}%/%d:%p1%{256}%/%{255}%&%d:%p1%{255}%&%d%;m",
    setBg: "\x1b[%?%p1%{8}%<%t4%p1%d%e48:2::%p1%{65536}%/%d:%p1%{256}%/%{255}%&%d:%p1%{255}%&%d%;m",
    resetColors: "\x1b[39;49m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    mouse: "\x1b[M",
    altChars: "``aaffggiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x1b(0",
    exitACS: "\x1b(B",
    automargin: true,
};

static this()
{
    Database.put(&term0);
    Database.put(&term1);
}
