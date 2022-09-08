// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.pcansi;

import dcell.database;

// pcansi
static immutable Termcap term0 = {
    name: "pcansi",
    lines: 24,
    colors: 8,
    bell: "\x07",
    clear: "\x1b[H\x1b[J",
    attrOff: "\x1b[0;10m",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    blink: "\x1b[5m",
    reverse: "\x1b[7m",
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[37;40m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x1b[D",
    cursorUp1: "\x1b[A",
    padChar: "\x00",
    keyBackspace: "\x08",
    keyHome: "\x1b[H",
    keyUp: "\x1b[A",
    keyDown: "\x1b[B",
    keyLeft: "\x1b[D",
    keyRight: "\x1b[C",
    altChars: "+\x10,\x11-\x18.\x190Û`\x04a±føgñh°jÙk¿lÚmÀnÅo~pÄqÄrÄs_tÃu´vÁwÂx³yózò{ã|Ø}~þ",
    enterACS: "\x1b[12m",
    exitACS: "\x1b[10m",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
