// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt100;

import dcell.database;

// vt100
static immutable Termcap term0 = {
    name: "vt100",
    aliases: ["vt100-am"],
    lines: 24,
};

static this()
{
    Database.put(&term0);
}
