// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt420;

import dcell.database;

// vt420
static immutable Termcap term0 = {
    name: "vt420",
    lines: 24,
    enterKeypad: "\x1b=",
    exitKeypad: "\x1b>",
    altChars: "``aaffggjjkkllmmnnooppqqrrssttuuvvwwxxyyzz{{||}}~~",
    enterACS: "\x1b(0",
    exitACS: "\x1b(B",
};

static this()
{
    Database.put(&term0);
}
