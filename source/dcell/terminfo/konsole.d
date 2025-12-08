// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.konsole;

import dcell.database;

// konsole
static immutable Termcap term0 = {
    name: "konsole",
    lines: 24,
    colors: 8,
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[39;49m",
};

// konsole-16color
static immutable Termcap term1 = {
    name: "konsole-16color",
    lines: 24,
    colors: 16,
    setFg: "\x1b[%?%p1%{8}%<%t%p1%{30}%+%e%p1%\'R\'%+%;%dm",
    setBg: "\x1b[%?%p1%{8}%<%t%p1%\'(\'%+%e%p1%{92}%+%;%dm",
};

// konsole-256color
static immutable Termcap term2 = {
    name: "konsole-256color",
    lines: 24,
    colors: 256,
    setFg: "\x1b[%?%p1%{8}%<%t3%p1%d%e%p1%{16}%<%t9%p1%{8}%-%d%e38;5;%p1%d%;m",
    setBg: "\x1b[%?%p1%{8}%<%t4%p1%d%e%p1%{16}%<%t10%p1%{8}%-%d%e48;5;%p1%d%;m",
    resetColors: "\x1b[39;49m",
};

static this()
{
    Database.put(&term0);
    Database.put(&term1);
    Database.put(&term2);
}
