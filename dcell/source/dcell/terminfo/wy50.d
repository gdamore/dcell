// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.wy50;

import dcell.database;

// wy50
static immutable Termcap term0 = {
    name: "wy50",
    aliases: ["wyse50"],
    lines: 24,
    bell: "\x07",
    clear: "\x1b+$<20>",
    showCursor: "\x1b`1",
    hideCursor: "\x1b`0",
    attrOff: "\x1b(\x1bH\x03",
    reverse: "\x1b`6\x1b)",
    dim: "\x1b`7\x1b)",
    setCursor: "\x1b=%p1%\' \'%+%c%p2%\' \'%+%c",
    cursorBack1: "\x08",
    cursorUp1: "\x0b",
    padChar: "\x00",
    keyBackspace: "\x08",
    keyF1: "\x01@\r",
    keyF2: "\x01A\r",
    keyF3: "\x01B\r",
    keyF4: "\x01C\r",
    keyF5: "\x01D\r",
    keyF6: "\x01E\r",
    keyF7: "\x01F\r",
    keyF8: "\x01G\r",
    keyF9: "\x01H\r",
    keyF10: "\x01I\r",
    keyF11: "\x01J\r",
    keyF12: "\x01K\r",
    keyF13: "\x01L\r",
    keyF14: "\x01M\r",
    keyF15: "\x01N\r",
    keyF16: "\x01O\r",
    keyInsert: "\x1bQ",
    keyDelete: "\x1bW",
    keyHome: "\x1e",
    keyPgUp: "\x1bJ",
    keyPgDn: "\x1bK",
    keyUp: "\x0b",
    keyDown: "\n",
    keyLeft: "\x08",
    keyRight: "\x0c",
    keyBacktab: "\x1bI",
    keyPrint: "\x1bP",
    altChars: "0wa_h[jukslrmqnxqzttuyv]wpxv",
    enterACS: "\x1bH\x02",
    exitACS: "\x1bH\x03",
    keyShfHome: "\x1b{",
    automargin: true,
};

static this()
{
    Database.put(&term0);
}
