// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.aixterm;

import dcell.database;

// aixterm
static immutable Termcap term0 = {
    name: "aixterm",
    lines: 25,
    colors: 8,
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[32m\x1b[40m",
};

// aixterm-16color
static immutable Termcap term1 = {
    name: "aixterm-16color",
    lines: 25,
    colors: 16,
    setFg: "\x1b[%?%p1%{8}%<%t%p1%{30}%+%e%p1%\'R\'%+%;%dm",
    setBg: "\x1b[%?%p1%{8}%<%t%p1%\'(\'%+%e%p1%{92}%+%;%dm",
    resetColors: "\x1b[32m\x1b[40m",
};

static this()
{
    Database.put(&term0);
    Database.put(&term1);
}
