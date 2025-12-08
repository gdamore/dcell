// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt100;

import dcell.database;

// vt100
static immutable Termcap term0 = {
    name: "vt100",
    aliases: ["vt100-am"],
    lines: 24,
    enterKeypad: "\x1b[?1h\x1b=",
    exitKeypad: "\x1b[?1l\x1b>",
};

static this()
{
    Database.put(&term0);
}
