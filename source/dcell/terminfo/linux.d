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
    altChars: "+\x10,\x11-\x18.\x190Û`\x04a±føgñh°iÎjÙk¿lÚmÀnÅo~pÄqÄrÄs_tÃu´vÁwÂx³yózò{ã|Ø}~þ",
    enterACS: "\x1b[11m",
    exitACS: "\x1b[10m",
};

static this()
{
    Database.put(&term0);
}
