// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt102;

import dcell.database;

// vt102
static immutable Termcap term0 = {
    name: "vt102",
    lines: 24,
    enterKeypad: "\x1b[?1h\x1b=",
    exitKeypad: "\x1b[?1l\x1b>",
};

static this()
{
    Database.put(&term0);
}
