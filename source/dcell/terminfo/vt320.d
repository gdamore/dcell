// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt320;

import dcell.database;

// vt320
static immutable Termcap term0 = {
    name: "vt320",
    aliases: ["vt300"],
    lines: 24,
    enterKeypad: "\x1b[?1h\x1b=",
    exitKeypad: "\x1b[?1l\x1b>",
};

static this()
{
    Database.put(&term0);
}
