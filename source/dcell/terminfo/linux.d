// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.linux;

import dcell.database;

// linux
static immutable Termcap term0 = {
    name: "linux",
    colors: 8,
    bell: "\x07",
    clear: "\x1b[H\x1b[J",
    showCursor: "\x1b[?25h\x1b[?0c",
    hideCursor: "\x1b[?25l\x1b[?1c",
    attrOff: "\x1b[0;10m",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    blink: "\x1b[5m",
    reverse: "\x1b[7m",
    dim: "\x1b[2m",
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[39;49m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    mouse: "\x1b[M",
    altChars: "+\x10,\x11-\x18.\x190Û`\x04a±føgñh°iÎjÙk¿lÚmÀnÅo~pÄqÄrÄs_tÃu´vÁwÂx³yózò{ã|Ø}~þ",
    enterACS: "\x1b[11m",
    exitACS: "\x1b[10m",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
