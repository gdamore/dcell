// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.xfce;

import dcell.database;

// xfce
static immutable Termcap term0 = {
    name: "xfce",
    lines: 24,
    colors: 8,
    enterKeypad: "\x1b[?1h\x1b=",
    exitKeypad: "\x1b[?1l\x1b>",
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[39;49m",
    altChars: "``aaffggiijjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x0e",
    exitACS: "\x0f",
    enableACS: "\x1b)0",
};

static this()
{
    Database.put(&term0);
}
