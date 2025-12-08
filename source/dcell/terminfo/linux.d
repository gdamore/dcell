// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.linux;

import dcell.database;

// linux
static immutable Termcap term0 = {
    name: "linux",
    colors: 8,
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[39;49m",
};

static this()
{
    Database.put(&term0);
}
