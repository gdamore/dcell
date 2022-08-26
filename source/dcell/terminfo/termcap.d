/// Copyright: 2022 Garrett D'Amore
/// License: MIT
module dcell.terminfo.termcap;

import core.thread;
import std.algorithm;
import std.conv;
import std.process : environment;
import std.stdio;
import std.string;

/** 
 * Represents the actual capabilities - this is an entry in a terminfo
 * database.
 */
struct Termcap
{
    string name; /// primary name for terminal, e.g. "xterm"
    string[] aliases; /// alternate names for terminal
    int columns; /// `cols`, the number of columns present
    int lines; /// `lines`, the number lines (rows) present
    int colors; // `colors`, the number of colors supported
    string bell; /// `bell`, the sequence to ring a bell
    string clear; /// `clear`, the sequence to clear the screen
    string enterCA; /// `smcup`, sequence to enter cursor addressing mode
    string exitCA; /// `rmcup`, sequence to exit cursor addressing mode
    string showCursor; /// `cnorm`, should display the normal cursor
    string hideCursor; /// `civis`, mark the cursor invisible
    string attrOff; /// `sgr0`, turn off all text attributes and colors
    string underline; /// `smul`, starts underlining
    string bold; /// `bold`, starts bold (maybe intense or double-strike)
    string blink; /// `blink`, starts blinking text
    string reverse; /// `rev`, inverts the foreground and background colors
    string dim; /// `dim`, reduces the intensity of text
    string italic; /// `sitm`, starts italics mode (not widely supported)
    string enterKeypad; /// `smkx`, enables keypad mode
    string exitKeypad; /// `rmkx`, leaves keypad mode
    string setFg; /// `setaf`, sets foreground text color (indexed)
    string setBg; /// `setab`, sets background text color (indexed)
    string resetColors; /// `op`, sets foreground and background to default
    string setCursor; /// `cup`, sets cursor location to row and column
    string cursorBack1; /// `cub1`, move cursor backwards one
    string cursorUp1; /// `cuu1`, mover cursor up one line
    string padChar; /// `pad`, padding character, if non-empty enables padding delays
    string insertChar; /// `ich1`, insert a character, used for inserting at bottom right for automargin terminals
    string keyBackspace; /// `kbs`, backspace key
    string keyF1; // kf1
    string keyF2; // kf2
    string keyF3; // kf3
    string keyF4; // kf4
    string keyF5; // kf5
    string keyF6; // kf6
    string keyF7; // kf7
    string keyF8; // kf8
    string keyF9; // kf9
    string keyF10; // kf10
    string keyF11; // kf11
    string keyF12; // kf12
    string keyF13; // kf13
    string keyF14; // kf14
    string keyF15; // kf15
    string keyF16; // kf16
    string keyF17; // kf17
    string keyF18; // kf18
    string keyF19; // kf19
    string keyF20; // kf20
    string keyF21; // kf21
    string keyF22; // kf22
    string keyF23; // kf23
    string keyF24; // kf24
    string keyF25; // kf25
    string keyF26; // kf26
    string keyF27; // kf27
    string keyF28; // kf28
    string keyF29; // kf29
    string keyF30; // kf30
    string keyF31; // kf31
    string keyF32; // kf32
    string keyF33; // kf33
    string keyF34; // kf34
    string keyF35; // kf35
    string keyF36; // kf36
    string keyF37; // kf37
    string keyF38; // kf38
    string keyF39; // kf39
    string keyF40; // kf40
    string keyF41; // kf41
    string keyF42; // kf42
    string keyF43; // kf43
    string keyF44; // kf44
    string keyF45; // kf45
    string keyF46; // kf46
    string keyF47; // kf47
    string keyF48; // kf48
    string keyF49; // kf49
    string keyF50; // kf50
    string keyF51; // kf51
    string keyF52; // kf52
    string keyF53; // kf53
    string keyF54; // kf54
    string keyF55; // kf55
    string keyF56; // kf56
    string keyF57; // kf57
    string keyF58; // kf58
    string keyF59; // kf59
    string keyF60; // kf60
    string keyF61; // kf61
    string keyF62; // kf62
    string keyF63; // kf63
    string keyF64; // kf64
    string keyInsert; // kich1
    string keyDelete; // kdch1
    string keyHome; // khome
    string keyEnd; // kend
    string keyHelp; // khlp
    string keyPgUp; // kpp
    string keyPgDn; // knp
    string keyUp; // kcuu1
    string keyDown; // kcud1
    string keyLeft; // kcub1
    string keyRight; // kcuf1
    string keyBacktab; // kcbt
    string keyExit; // kext
    string keyClear; // kclr
    string keyPrint; // kprt
    string keyCancel; // kcan
    string mouse; /// `kmouse`, indicates support for mouse mode - XTerm style sequences are assumed
    string altChars; /// `acsc`, alternate characters, used for non-ASCII characters with certain legacy terminals
    string enterACS; /// `smacs`, sequence to switch to alternate character set
    string exitACS; /// `rmacs`, sequence to return to normal character set
    string enableACS; /// `enacs`, sequence to enable alternate character set support
    string keyShfRight; // kRIT
    string keyShfLeft; // kLFT
    string keyShfHome; // kHOM
    string keyShfEnd; // kEND
    string keyShfInsert; // kIC
    string keyShfDelete; // kDC
    bool automargin; /// `am`, if true cursor wraps and advances to next row after last column

    // Non-standard additions to terminfo.  YMMV.
    string strikethrough; // smxx
    string setFgBg; /// sequence to set both foreground and background together, using indexed colors
    string setFgBgRGB; /// sequence to set both foreground and background together, using RGB colors
    string setFgRGB; /// sequence to set foreground color to RGB value
    string setBgRGB; /// sequence to set background color RGB value
    string keyShfUp;
    string keyShfDown;
    string keyShfPgUp;
    string keyShfPgDn;
    string keyCtrlUp;
    string keyCtrlDown;
    string keyCtrlRight;
    string keyCtrlLeft;
    string keyMetaUp;
    string keyMetaDown;
    string keyMetaRight;
    string keyMetaLeft;
    string keyAltUp;
    string keyAltDown;
    string keyAltRight;
    string keyAltLeft;
    string keyCtrlHome;
    string keyCtrlEnd;
    string keyMetaHome;
    string keyMetaEnd;
    string keyAltHome;
    string keyAltEnd;
    string keyAltShfUp;
    string keyAltShfDown;
    string keyAltShfLeft;
    string keyAltShfRight;
    string keyMetaShfUp;
    string keyMetaShfDown;
    string keyMetaShfLeft;
    string keyMetaShfRight;
    string keyCtrlShfUp;
    string keyCtrlShfDown;
    string keyCtrlShfLeft;
    string keyCtrlShfRight;
    string keyCtrlShfHome;
    string keyCtrlShfEnd;
    string keyAltShfHome;
    string keyAltShfEnd;
    string keyMetaShfHome;
    string keyMetaShfEnd;
    string enablePaste; /// sequence to enable delimited paste mode
    string disablePaste; /// sequence to disable delimited paste mode
    string pasteStart; /// sequence sent by terminal to indicate start of a paste buffer
    string pasteEnd; /// sequence sent by terminal to indicated end of a paste buffer
    bool likeXTerm; /// true if this simulates XTerm, enables extra features
    bool truecolor; /// true if this terminal supports 24-bit (RGB) color
    string cursorDefault; /// sequence to reset the cursor shape to deafult
    string cursorBlinkingBlock; /// sequence to change the cursor to a blinking block
    string cursorSteadyBlock; /// sequence to change the cursor to a solid block
    string cursorBlinkingUnderline; /// sequence to change the cursor to a blinking underscore
    string cursorSteadyUnderline; /// sequence to change the cursor to a steady underscore
    string cursorBlinkingBar; /// sequence to change the cursor to a blinking vertical bar
    string cussorSteadyBar; /// sequence to change the cursor to a steady vertical bar
    string enterURL; /// sequence to start making text a clickable link
    string exitURL; /// sequence to stop making text clickable link
    string setWindowSize; /// sequence to resize the window (rarely supported)
}
