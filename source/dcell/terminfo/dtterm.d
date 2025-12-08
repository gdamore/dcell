// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.dtterm;

import dcell.database;

// dtterm
static immutable Termcap term0 = {
    name: "dtterm",
    lines: 24,
    colors: 8,
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[39;49m",
    altChars: "``aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x0e",
    exitACS: "\x0f",
    enableACS: "\x1b(B\x1b)0",
};

static this()
{
    Database.put(&term0);
}
