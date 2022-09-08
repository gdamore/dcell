// Generated automatically.  DO NOT HAND-EDIT.

module dcell.terminfo.aixterm;

import dcell.database;

// aixterm
static immutable Termcap term0 = {
    name: "aixterm",
    lines: 25,
    colors: 8,
    bell: "\x07",
    clear: "\x1b[H\x1b[J",
    attrOff: "\x1b[0;10m\x1b(B",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    reverse: "\x1b[7m",
    setFg: "\x1b[3%p1%dm",
    setBg: "\x1b[4%p1%dm",
    resetColors: "\x1b[32m\x1b[40m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    padChar: "\x00",
    keyBackspace: "\x08",
    keyF1: "\x1b[001q",
    keyF2: "\x1b[002q",
    keyF3: "\x1b[003q",
    keyF4: "\x1b[004q",
    keyF5: "\x1b[005q",
    keyF6: "\x1b[006q",
    keyF7: "\x1b[007q",
    keyF8: "\x1b[008q",
    keyF9: "\x1b[009q",
    keyF10: "\x1b[010q",
    keyF11: "\x1b[011q",
    keyF12: "\x1b[012q",
    keyF13: "\x1b[013q",
    keyF14: "\x1b[014q",
    keyF15: "\x1b[015q",
    keyF16: "\x1b[016q",
    keyF17: "\x1b[017q",
    keyF18: "\x1b[018q",
    keyF19: "\x1b[019q",
    keyF20: "\x1b[020q",
    keyF21: "\x1b[021q",
    keyF22: "\x1b[022q",
    keyF23: "\x1b[023q",
    keyF24: "\x1b[024q",
    keyF25: "\x1b[025q",
    keyF26: "\x1b[026q",
    keyF27: "\x1b[027q",
    keyF28: "\x1b[028q",
    keyF29: "\x1b[029q",
    keyF30: "\x1b[030q",
    keyF31: "\x1b[031q",
    keyF32: "\x1b[032q",
    keyF33: "\x1b[033q",
    keyF34: "\x1b[034q",
    keyF35: "\x1b[035q",
    keyF36: "\x1b[036q",
    keyInsert: "\x1b[139q",
    keyDelete: "\x1b[P",
    keyHome: "\x1b[H",
    keyEnd: "\x1b[146q",
    keyPgUp: "\x1b[150q",
    keyPgDn: "\x1b[154q",
    keyUp: "\x1b[A",
    keyDown: "\x1b[B",
    keyLeft: "\x1b[D",
    keyRight: "\x1b[C",
    keyBacktab: "\x1b[Z",
    keyClear: "\x1b[144q",
    altChars: "jjkkllmmnnqqttuuvvwwxx",
    automargin: true,
};

// aixterm-16color
static immutable Termcap term1 = {
    name: "aixterm-16color",
    lines: 25,
    colors: 16,
    bell: "\x07",
    clear: "\x1b[H\x1b[J",
    attrOff: "\x1b[0;10m\x1b(B",
    underline: "\x1b[4m",
    bold: "\x1b[1m",
    reverse: "\x1b[7m",
    setFg: "\x1b[%?%p1%{8}%<%t%p1%{30}%+%e%p1%\'R\'%+%;%dm",
    setBg: "\x1b[%?%p1%{8}%<%t%p1%\'(\'%+%e%p1%{92}%+%;%dm",
    resetColors: "\x1b[32m\x1b[40m",
    setCursor: "\x1b[%i%p1%d;%p2%dH",
    cursorBack1: "\x08",
    cursorUp1: "\x1b[A",
    padChar: "\x00",
    keyBackspace: "\x08",
    keyF1: "\x1b[001q",
    keyF2: "\x1b[002q",
    keyF3: "\x1b[003q",
    keyF4: "\x1b[004q",
    keyF5: "\x1b[005q",
    keyF6: "\x1b[006q",
    keyF7: "\x1b[007q",
    keyF8: "\x1b[008q",
    keyF9: "\x1b[009q",
    keyF10: "\x1b[010q",
    keyF11: "\x1b[011q",
    keyF12: "\x1b[012q",
    keyF13: "\x1b[013q",
    keyF14: "\x1b[014q",
    keyF15: "\x1b[015q",
    keyF16: "\x1b[016q",
    keyF17: "\x1b[017q",
    keyF18: "\x1b[018q",
    keyF19: "\x1b[019q",
    keyF20: "\x1b[020q",
    keyF21: "\x1b[021q",
    keyF22: "\x1b[022q",
    keyF23: "\x1b[023q",
    keyF24: "\x1b[024q",
    keyF25: "\x1b[025q",
    keyF26: "\x1b[026q",
    keyF27: "\x1b[027q",
    keyF28: "\x1b[028q",
    keyF29: "\x1b[029q",
    keyF30: "\x1b[030q",
    keyF31: "\x1b[031q",
    keyF32: "\x1b[032q",
    keyF33: "\x1b[033q",
    keyF34: "\x1b[034q",
    keyF35: "\x1b[035q",
    keyF36: "\x1b[036q",
    keyInsert: "\x1b[139q",
    keyDelete: "\x1b[P",
    keyHome: "\x1b[H",
    keyEnd: "\x1b[146q",
    keyPgUp: "\x1b[150q",
    keyPgDn: "\x1b[154q",
    keyUp: "\x1b[A",
    keyDown: "\x1b[B",
    keyLeft: "\x1b[D",
    keyRight: "\x1b[C",
    keyBacktab: "\x1b[Z",
    keyClear: "\x1b[144q",
    altChars: "jjkkllmmnnqqttuuvvwwxx",
    automargin: true,
};

static this()
{
    Database.put(&term0);
    Database.put(&term1);
}
