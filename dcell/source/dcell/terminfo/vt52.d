// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.vt52;

import dcell.database;

// vt52
static immutable Termcap term0 = {
    name: "vt52",
    lines: 24,
    bell: "\x07",
    clear: "\x1bH\x1bJ",
    setCursor: "\x1bY%p1%\' \'%+%c%p2%\' \'%+%c",
    cursorBack1: "\x1bD",
    cursorUp1: "\x1bA",
    padChar: "\x00",
    keyBackspace: "\x08",
    keyUp: "\x1bA",
    keyDown: "\x1bB",
    keyLeft: "\x1bD",
    keyRight: "\x1bC",
    altChars: ".kffgghhompoqqss",
    enterACS: "\x1bF",
    exitACS: "\x1bG",
};

static this()
{
    Database.put(&term0);
}
