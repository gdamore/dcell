// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt220;

import dcell.database;

// vt220
static immutable Termcap term0 = {name: "vt220",
aliases: ["vt200"],
lines: 24,};

static this()
{
    Database.put(&term0);
}
