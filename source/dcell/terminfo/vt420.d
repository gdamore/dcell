// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt420;

import dcell.database;

// vt420
static immutable Termcap term0 = {
    name: "vt420",
    lines: 24,
    enterKeypad: "\x1b=",
    exitKeypad: "\x1b>",
};

static this()
{
    Database.put(&term0);
}
