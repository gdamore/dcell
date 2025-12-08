// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.xfce;

import dcell.database;

// xfce
static immutable Termcap term0 = {
    name: "xfce",
    lines: 24,
    colors: 8,
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[39;49m",
};

static this()
{
    Database.put(&term0);
}
