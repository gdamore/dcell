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
    padChar: "\x00",
    insertChar: "\x1b[@",
    keyBackspace: "",
    keyF1: "\x1b[[A",
    keyF2: "\x1b[[B",
    keyF3: "\x1b[[C",
    keyF4: "\x1b[[D",
    keyF5: "\x1b[[E",
    keyF6: "\x1b[17~",
    keyF7: "\x1b[18~",
    keyF8: "\x1b[19~",
    keyF9: "\x1b[20~",
    keyF10: "\x1b[21~",
    keyF11: "\x1b[23~",
    keyF12: "\x1b[24~",
    keyF13: "\x1b[25~",
    keyF14: "\x1b[26~",
    keyF15: "\x1b[28~",
    keyF16: "\x1b[29~",
    keyF17: "\x1b[31~",
    keyF18: "\x1b[32~",
    keyF19: "\x1b[33~",
    keyF20: "\x1b[34~",
    keyInsert: "\x1b[2~",
    keyDelete: "\x1b[3~",
    keyHome: "\x1b[1~",
    keyEnd: "\x1b[4~",
    keyPgUp: "\x1b[5~",
    keyPgDn: "\x1b[6~",
    keyUp: "\x1b[A",
    keyDown: "\x1b[B",
    keyLeft: "\x1b[D",
    keyRight: "\x1b[C",
    keyBacktab: "\x1b[Z",
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
