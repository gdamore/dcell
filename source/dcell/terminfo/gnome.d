// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.gnome;

import dcell.database;

// gnome
static immutable Termcap term0 = {
    name: "gnome",
    lines: 24,
    colors: 8,
    enterKeypad: "\x1b[?1h\x1b=",
    exitKeypad: "\x1b[?1l\x1b>",
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[39;49m",
};

// gnome-256color
static immutable Termcap term1 = {
    name: "gnome-256color",
    lines: 24,
    colors: 256,
    enterKeypad: "\x1b[?1h\x1b=",
    exitKeypad: "\x1b[?1l\x1b>",
    setFg: "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m",
    setBg: "\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m",
    resetColors: "\x1b[39;49m",
};

static this()
{
    Database.put(&term0);
    Database.put(&term1);
}
