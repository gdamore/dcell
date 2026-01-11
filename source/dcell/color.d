/**
 * Color module for dcell.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.color;

import std.format;
import std.typecons;

/**
 * Color is a what you think, almost.
 * However, the upper bits of the color are used to indicate special behaviors.
 * If the value upper 24-bits are clear, then the value is an index into a
 * palette (typically it should be less than 256).  If the isRGB bit is
 * set, then the lower 24 bits are a 24-bit direct color (RGB).
 */
enum Color : uint
{
    invalid = 1 << 24, /// not a color (also means do not change color)
    reset = invalid + 1, /// reset color to terminal defaults
    isRGB = 1 << 31, /// indicates that the low 24-bits are red, green blue
    black = 0,
    maroon = 1,
    green = 2,
    olive = 3,
    navy = 4,
    purple = 5,
    teal = 6,
    silver = 7,
    gray = 8,
    red = 9,
    lime = 10,
    yellow = 11,
    blue = 12,
    fuchsia = 13,
    aqua = 14,
    white = 15,
    // following colors are web named colors
    aliceBlue = isRGB | 0xF0F8FF,
    antiqueWhite = isRGB | 0xFAEBD7,
    aquamarine = isRGB | 0x7FFFD4,
    azure = isRGB | 0xF0FFFF,
    beige = isRGB | 0xF5F5DC,
    bisque = isRGB | 0xFFE4C4,
    blanchedAlmond = isRGB | 0xFFEBCD,
    blueViolet = isRGB | 0x8A2BE2,
    brown = isRGB | 0xA52A2A,
    burlyWood = isRGB | 0xDEB887,
    cadetBlue = isRGB | 0x5F9EA0,
    chartreuse = isRGB | 0x7FFF00,
    chocolate = isRGB | 0xD2691E,
    coral = isRGB | 0xFF7F50,
    cornflowerBlue = isRGB | 0x6495ED,
    cornsilk = isRGB | 0xFFF8DC,
    crimson = isRGB | 0xDC143C,
    darkBlue = isRGB | 0x00008B,
    darkCyan = isRGB | 0x008B8B,
    darkGoldenrod = isRGB | 0xB8860B,
    darkGray = isRGB | 0xA9A9A9,
    darkGreen = isRGB | 0x006400,
    darkKhaki = isRGB | 0xBDB76B,
    darkMagenta = isRGB | 0x8B008B,
    darkOliveGreen = isRGB | 0x556B2F,
    darkOrange = isRGB | 0xFF8C00,
    darkOrchid = isRGB | 0x9932CC,
    darkRed = isRGB | 0x8B0000,
    darkSalmon = isRGB | 0xE9967A,
    darkSeaGreen = isRGB | 0x8FBC8F,
    darkSlateBlue = isRGB | 0x483D8B,
    darkSlateGray = isRGB | 0x2F4F4F,
    darkTurquoise = isRGB | 0x00CED1,
    darkViolet = isRGB | 0x9400D3,
    deepPink = isRGB | 0xFF1493,
    deepSkyBlue = isRGB | 0x00BFFF,
    dimGray = isRGB | 0x696969,
    dodgerBlue = isRGB | 0x1E90FF,
    fireBrick = isRGB | 0xB22222,
    floralWhite = isRGB | 0xFFFAF0,
    forestGreen = isRGB | 0x228B22,
    gainsboro = isRGB | 0xDCDCDC,
    ghostWhite = isRGB | 0xF8F8FF,
    gold = isRGB | 0xFFD700,
    goldenrod = isRGB | 0xDAA520,
    greenYellow = isRGB | 0xADFF2F,
    honeydew = isRGB | 0xF0FFF0,
    hotPink = isRGB | 0xFF69B4,
    indianRed = isRGB | 0xCD5C5C,
    indigo = isRGB | 0x4B0082,
    ivory = isRGB | 0xFFFFF0,
    khaki = isRGB | 0xF0E68C,
    lavender = isRGB | 0xE6E6FA,
    lavenderBlush = isRGB | 0xFFF0F5,
    lawnGreen = isRGB | 0x7CFC00,
    lemonChiffon = isRGB | 0xFFFACD,
    lightBlue = isRGB | 0xADD8E6,
    lightCoral = isRGB | 0xF08080,
    lightCyan = isRGB | 0xE0FFFF,
    lightGoldenrodYellow = isRGB | 0xFAFAD2,
    lightGray = isRGB | 0xD3D3D3,
    lightGreen = isRGB | 0x90EE90,
    lightPink = isRGB | 0xFFB6C1,
    lightSalmon = isRGB | 0xFFA07A,
    lightSeaGreen = isRGB | 0x20B2AA,
    lightSkyBlue = isRGB | 0x87CEFA,
    lightSlateGray = isRGB | 0x778899,
    lightSteelBlue = isRGB | 0xB0C4DE,
    lightYellow = isRGB | 0xFFFFE0,
    limeGreen = isRGB | 0x32CD32,
    linen = isRGB | 0xFAF0E6,
    mediumAquamarine = isRGB | 0x66CDAA,
    mediumBlue = isRGB | 0x0000CD,
    mediumOrchid = isRGB | 0xBA55D3,
    mediumPurple = isRGB | 0x9370DB,
    mediumSeaGreen = isRGB | 0x3CB371,
    mediumSlateBlue = isRGB | 0x7B68EE,
    mediumSpringGreen = isRGB | 0x00FA9A,
    mediumTurquoise = isRGB | 0x48D1CC,
    mediumVioletRed = isRGB | 0xC71585,
    midnightBlue = isRGB | 0x191970,
    mintCream = isRGB | 0xF5FFFA,
    mistyRose = isRGB | 0xFFE4E1,
    moccasin = isRGB | 0xFFE4B5,
    navajoWhite = isRGB | 0xFFDEAD,
    oldLace = isRGB | 0xFDF5E6,
    oliveDrab = isRGB | 0x6B8E23,
    orange = isRGB | 0xFFA500,
    orangeRed = isRGB | 0xFF4500,
    orchid = isRGB | 0xDA70D6,
    paleGoldenrod = isRGB | 0xEEE8AA,
    paleGreen = isRGB | 0x98FB98,
    paleTurquoise = isRGB | 0xAFEEEE,
    paleVioletRed = isRGB | 0xDB7093,
    papayaWhip = isRGB | 0xFFEFD5,
    peachPuff = isRGB | 0xFFDAB9,
    peru = isRGB | 0xCD853F,
    pink = isRGB | 0xFFC0CB,
    plum = isRGB | 0xDDA0DD,
    powderBlue = isRGB | 0xB0E0E6,
    rebeccaPurple = isRGB | 0x663399,
    rosyBrown = isRGB | 0xBC8F8F,
    royalBlue = isRGB | 0x4169E1,
    saddleBrown = isRGB | 0x8B4513,
    salmon = isRGB | 0xFA8072,
    sandyBrown = isRGB | 0xF4A460,
    seaGreen = isRGB | 0x2E8B57,
    seashell = isRGB | 0xFFF5EE,
    sienna = isRGB | 0xA0522D,
    skyBlue = isRGB | 0x87CEEB,
    slateBlue = isRGB | 0x6A5ACD,
    slateGray = isRGB | 0x708090,
    snow = isRGB | 0xFFFAFA,
    springGreen = isRGB | 0x00FF7F,
    steelBlue = isRGB | 0x4682B4,
    tan = isRGB | 0xD2B48C,
    thistle = isRGB | 0xD8BFD8,
    tomato = isRGB | 0xFF6347,
    turquoise = isRGB | 0x40E0D0,
    violet = isRGB | 0xEE82EE,
    wheat = isRGB | 0xF5DEB3,
    whiteSmoke = isRGB | 0xF5F5F5,
    yellowGreen = isRGB | 0x9ACD32,
    init = invalid,
}

private static immutable uint[Color] rgbValues;
private static immutable Color[uint] palValues;

shared static this() @trusted
{
    rgbValues[Color.black] = 0x000000;
    rgbValues[Color.maroon] = 0x800000;
    rgbValues[Color.green] = 0x008000;
    rgbValues[Color.olive] = 0x808000;
    rgbValues[Color.navy] = 0x000080;
    rgbValues[Color.purple] = 0x800080;
    rgbValues[Color.teal] = 0x008080;
    rgbValues[Color.silver] = 0xC0C0C0;
    rgbValues[Color.gray] = 0x808080;
    rgbValues[Color.red] = 0xFF0000;
    rgbValues[Color.lime] = 0x00FF00;
    rgbValues[Color.yellow] = 0xFFFF00;
    rgbValues[Color.blue] = 0x0000FF;
    rgbValues[Color.fuchsia] = 0xFF00FF;
    rgbValues[Color.aqua] = 0x00FFFF;
    rgbValues[Color.white] = 0xFFFFFF;
    // 256 color extended palette
    rgbValues[cast(Color) 16] = 0x000000; // black
    rgbValues[cast(Color) 17] = 0x00005F;
    rgbValues[cast(Color) 18] = 0x000087;
    rgbValues[cast(Color) 19] = 0x0000AF;
    rgbValues[cast(Color) 20] = 0x0000D7;
    rgbValues[cast(Color) 21] = 0x0000FF; // blue
    rgbValues[cast(Color) 22] = 0x005F00;
    rgbValues[cast(Color) 23] = 0x005F5F;
    rgbValues[cast(Color) 24] = 0x005F87;
    rgbValues[cast(Color) 25] = 0x005FAF;
    rgbValues[cast(Color) 26] = 0x005FD7;
    rgbValues[cast(Color) 27] = 0x005FFF;
    rgbValues[cast(Color) 28] = 0x008700;
    rgbValues[cast(Color) 29] = 0x00875F;
    rgbValues[cast(Color) 30] = 0x008787;
    rgbValues[cast(Color) 31] = 0x0087Af;
    rgbValues[cast(Color) 32] = 0x0087D7;
    rgbValues[cast(Color) 33] = 0x0087FF;
    rgbValues[cast(Color) 34] = 0x00AF00;
    rgbValues[cast(Color) 35] = 0x00AF5F;
    rgbValues[cast(Color) 36] = 0x00AF87;
    rgbValues[cast(Color) 37] = 0x00AFAF;
    rgbValues[cast(Color) 38] = 0x00AFD7;
    rgbValues[cast(Color) 39] = 0x00AFFF;
    rgbValues[cast(Color) 40] = 0x00D700;
    rgbValues[cast(Color) 41] = 0x00D75F;
    rgbValues[cast(Color) 42] = 0x00D787;
    rgbValues[cast(Color) 43] = 0x00D7AF;
    rgbValues[cast(Color) 44] = 0x00D7D7;
    rgbValues[cast(Color) 45] = 0x00D7FF;
    rgbValues[cast(Color) 46] = 0x00FF00; // lime
    rgbValues[cast(Color) 47] = 0x00FF5F;
    rgbValues[cast(Color) 48] = 0x00FF87;
    rgbValues[cast(Color) 49] = 0x00FFAF;
    rgbValues[cast(Color) 50] = 0x00FFd7;
    rgbValues[cast(Color) 51] = 0x00FFFF; // aqua
    rgbValues[cast(Color) 52] = 0x5F0000;
    rgbValues[cast(Color) 53] = 0x5F005F;
    rgbValues[cast(Color) 54] = 0x5F0087;
    rgbValues[cast(Color) 55] = 0x5F00AF;
    rgbValues[cast(Color) 56] = 0x5F00D7;
    rgbValues[cast(Color) 57] = 0x5F00FF;
    rgbValues[cast(Color) 58] = 0x5F5F00;
    rgbValues[cast(Color) 59] = 0x5F5F5F;
    rgbValues[cast(Color) 60] = 0x5F5F87;
    rgbValues[cast(Color) 61] = 0x5F5FAF;
    rgbValues[cast(Color) 62] = 0x5F5FD7;
    rgbValues[cast(Color) 63] = 0x5F5FFF;
    rgbValues[cast(Color) 64] = 0x5F8700;
    rgbValues[cast(Color) 65] = 0x5F875F;
    rgbValues[cast(Color) 66] = 0x5F8787;
    rgbValues[cast(Color) 67] = 0x5F87AF;
    rgbValues[cast(Color) 68] = 0x5F87D7;
    rgbValues[cast(Color) 69] = 0x5F87FF;
    rgbValues[cast(Color) 70] = 0x5FAF00;
    rgbValues[cast(Color) 71] = 0x5FAF5F;
    rgbValues[cast(Color) 72] = 0x5FAF87;
    rgbValues[cast(Color) 73] = 0x5FAFAF;
    rgbValues[cast(Color) 74] = 0x5FAFD7;
    rgbValues[cast(Color) 75] = 0x5FAFFF;
    rgbValues[cast(Color) 76] = 0x5FD700;
    rgbValues[cast(Color) 77] = 0x5FD75F;
    rgbValues[cast(Color) 78] = 0x5FD787;
    rgbValues[cast(Color) 79] = 0x5FD7AF;
    rgbValues[cast(Color) 80] = 0x5FD7D7;
    rgbValues[cast(Color) 81] = 0x5FD7FF;
    rgbValues[cast(Color) 82] = 0x5FFF00;
    rgbValues[cast(Color) 83] = 0x5FFF5F;
    rgbValues[cast(Color) 84] = 0x5FFF87;
    rgbValues[cast(Color) 85] = 0x5FFFAF;
    rgbValues[cast(Color) 86] = 0x5FFFD7;
    rgbValues[cast(Color) 87] = 0x5FFFFF;
    rgbValues[cast(Color) 88] = 0x870000;
    rgbValues[cast(Color) 89] = 0x87005F;
    rgbValues[cast(Color) 90] = 0x870087;
    rgbValues[cast(Color) 91] = 0x8700AF;
    rgbValues[cast(Color) 92] = 0x8700D7;
    rgbValues[cast(Color) 93] = 0x8700FF;
    rgbValues[cast(Color) 94] = 0x875F00;
    rgbValues[cast(Color) 95] = 0x875F5F;
    rgbValues[cast(Color) 96] = 0x875F87;
    rgbValues[cast(Color) 97] = 0x875FAF;
    rgbValues[cast(Color) 98] = 0x875FD7;
    rgbValues[cast(Color) 99] = 0x875FFF;
    rgbValues[cast(Color) 100] = 0x878700;
    rgbValues[cast(Color) 101] = 0x87875F;
    rgbValues[cast(Color) 102] = 0x878787;
    rgbValues[cast(Color) 103] = 0x8787AF;
    rgbValues[cast(Color) 104] = 0x8787D7;
    rgbValues[cast(Color) 105] = 0x8787FF;
    rgbValues[cast(Color) 106] = 0x87AF00;
    rgbValues[cast(Color) 107] = 0x87AF5F;
    rgbValues[cast(Color) 108] = 0x87AF87;
    rgbValues[cast(Color) 109] = 0x87AFAF;
    rgbValues[cast(Color) 110] = 0x87AFD7;
    rgbValues[cast(Color) 111] = 0x87AFFF;
    rgbValues[cast(Color) 112] = 0x87D700;
    rgbValues[cast(Color) 113] = 0x87D75F;
    rgbValues[cast(Color) 114] = 0x87D787;
    rgbValues[cast(Color) 115] = 0x87D7AF;
    rgbValues[cast(Color) 116] = 0x87D7D7;
    rgbValues[cast(Color) 117] = 0x87D7FF;
    rgbValues[cast(Color) 118] = 0x87FF00;
    rgbValues[cast(Color) 119] = 0x87FF5F;
    rgbValues[cast(Color) 120] = 0x87FF87;
    rgbValues[cast(Color) 121] = 0x87FFAF;
    rgbValues[cast(Color) 122] = 0x87FFD7;
    rgbValues[cast(Color) 123] = 0x87FFFF;
    rgbValues[cast(Color) 124] = 0xAF0000;
    rgbValues[cast(Color) 125] = 0xAF005F;
    rgbValues[cast(Color) 126] = 0xAF0087;
    rgbValues[cast(Color) 127] = 0xAF00AF;
    rgbValues[cast(Color) 128] = 0xAF00D7;
    rgbValues[cast(Color) 129] = 0xAF00FF;
    rgbValues[cast(Color) 130] = 0xAF5F00;
    rgbValues[cast(Color) 131] = 0xAF5F5F;
    rgbValues[cast(Color) 132] = 0xAF5F87;
    rgbValues[cast(Color) 133] = 0xAF5FAF;
    rgbValues[cast(Color) 134] = 0xAF5FD7;
    rgbValues[cast(Color) 135] = 0xAF5FFF;
    rgbValues[cast(Color) 136] = 0xAF8700;
    rgbValues[cast(Color) 137] = 0xAF875F;
    rgbValues[cast(Color) 138] = 0xAF8787;
    rgbValues[cast(Color) 139] = 0xAF87AF;
    rgbValues[cast(Color) 140] = 0xAF87D7;
    rgbValues[cast(Color) 141] = 0xAF87FF;
    rgbValues[cast(Color) 142] = 0xAFAF00;
    rgbValues[cast(Color) 143] = 0xAFAF5F;
    rgbValues[cast(Color) 144] = 0xAFAF87;
    rgbValues[cast(Color) 145] = 0xAFAFAF;
    rgbValues[cast(Color) 146] = 0xAFAFD7;
    rgbValues[cast(Color) 147] = 0xAFAFFF;
    rgbValues[cast(Color) 148] = 0xAFD700;
    rgbValues[cast(Color) 149] = 0xAFD75F;
    rgbValues[cast(Color) 150] = 0xAFD787;
    rgbValues[cast(Color) 151] = 0xAFD7AF;
    rgbValues[cast(Color) 152] = 0xAFD7D7;
    rgbValues[cast(Color) 153] = 0xAFD7FF;
    rgbValues[cast(Color) 154] = 0xAFFF00;
    rgbValues[cast(Color) 155] = 0xAFFF5F;
    rgbValues[cast(Color) 156] = 0xAFFF87;
    rgbValues[cast(Color) 157] = 0xAFFFAF;
    rgbValues[cast(Color) 158] = 0xAFFFD7;
    rgbValues[cast(Color) 159] = 0xAFFFFF;
    rgbValues[cast(Color) 160] = 0xD70000;
    rgbValues[cast(Color) 161] = 0xD7005F;
    rgbValues[cast(Color) 162] = 0xD70087;
    rgbValues[cast(Color) 163] = 0xD700AF;
    rgbValues[cast(Color) 164] = 0xD700D7;
    rgbValues[cast(Color) 165] = 0xD700FF;
    rgbValues[cast(Color) 166] = 0xD75F00;
    rgbValues[cast(Color) 167] = 0xD75F5F;
    rgbValues[cast(Color) 168] = 0xD75F87;
    rgbValues[cast(Color) 169] = 0xD75FAF;
    rgbValues[cast(Color) 170] = 0xD75FD7;
    rgbValues[cast(Color) 171] = 0xD75FFF;
    rgbValues[cast(Color) 172] = 0xD78700;
    rgbValues[cast(Color) 173] = 0xD7875F;
    rgbValues[cast(Color) 174] = 0xD78787;
    rgbValues[cast(Color) 175] = 0xD787AF;
    rgbValues[cast(Color) 176] = 0xD787D7;
    rgbValues[cast(Color) 177] = 0xD787FF;
    rgbValues[cast(Color) 178] = 0xD7AF00;
    rgbValues[cast(Color) 179] = 0xD7AF5F;
    rgbValues[cast(Color) 180] = 0xD7AF87;
    rgbValues[cast(Color) 181] = 0xD7AFAF;
    rgbValues[cast(Color) 182] = 0xD7AFD7;
    rgbValues[cast(Color) 183] = 0xD7AFFF;
    rgbValues[cast(Color) 184] = 0xD7D700;
    rgbValues[cast(Color) 185] = 0xD7D75F;
    rgbValues[cast(Color) 186] = 0xD7D787;
    rgbValues[cast(Color) 187] = 0xD7D7AF;
    rgbValues[cast(Color) 188] = 0xD7D7D7;
    rgbValues[cast(Color) 189] = 0xD7D7FF;
    rgbValues[cast(Color) 190] = 0xD7FF00;
    rgbValues[cast(Color) 191] = 0xD7FF5F;
    rgbValues[cast(Color) 192] = 0xD7FF87;
    rgbValues[cast(Color) 193] = 0xD7FFAF;
    rgbValues[cast(Color) 194] = 0xD7FFD7;
    rgbValues[cast(Color) 195] = 0xD7FFFF;
    rgbValues[cast(Color) 196] = 0xFF0000; // red
    rgbValues[cast(Color) 197] = 0xFF005F;
    rgbValues[cast(Color) 198] = 0xFF0087;
    rgbValues[cast(Color) 199] = 0xFF00AF;
    rgbValues[cast(Color) 200] = 0xFF00D7;
    rgbValues[cast(Color) 201] = 0xFF00FF; // fuchsia
    rgbValues[cast(Color) 202] = 0xFF5F00;
    rgbValues[cast(Color) 203] = 0xFF5F5F;
    rgbValues[cast(Color) 204] = 0xFF5F87;
    rgbValues[cast(Color) 205] = 0xFF5FAF;
    rgbValues[cast(Color) 206] = 0xFF5FD7;
    rgbValues[cast(Color) 207] = 0xFF5FFF;
    rgbValues[cast(Color) 208] = 0xFF8700;
    rgbValues[cast(Color) 209] = 0xFF875F;
    rgbValues[cast(Color) 210] = 0xFF8787;
    rgbValues[cast(Color) 211] = 0xFF87AF;
    rgbValues[cast(Color) 212] = 0xFF87D7;
    rgbValues[cast(Color) 213] = 0xFF87FF;
    rgbValues[cast(Color) 214] = 0xFFAF00;
    rgbValues[cast(Color) 215] = 0xFFAF5F;
    rgbValues[cast(Color) 216] = 0xFFAF87;
    rgbValues[cast(Color) 217] = 0xFFAFAF;
    rgbValues[cast(Color) 218] = 0xFFAFD7;
    rgbValues[cast(Color) 219] = 0xFFAFFF;
    rgbValues[cast(Color) 220] = 0xFFD700;
    rgbValues[cast(Color) 221] = 0xFFD75F;
    rgbValues[cast(Color) 222] = 0xFFD787;
    rgbValues[cast(Color) 223] = 0xFFD7AF;
    rgbValues[cast(Color) 224] = 0xFFD7D7;
    rgbValues[cast(Color) 225] = 0xFFD7FF;
    rgbValues[cast(Color) 226] = 0xFFFF00; // yellow
    rgbValues[cast(Color) 227] = 0xFFFF5F;
    rgbValues[cast(Color) 228] = 0xFFFF87;
    rgbValues[cast(Color) 229] = 0xFFFFAF;
    rgbValues[cast(Color) 230] = 0xFFFFD7;
    rgbValues[cast(Color) 231] = 0xFFFFFF; // white
    rgbValues[cast(Color) 232] = 0x080808;
    rgbValues[cast(Color) 233] = 0x121212;
    rgbValues[cast(Color) 234] = 0x1C1C1C;
    rgbValues[cast(Color) 235] = 0x262626;
    rgbValues[cast(Color) 236] = 0x303030;
    rgbValues[cast(Color) 237] = 0x3A3A3A;
    rgbValues[cast(Color) 238] = 0x444444;
    rgbValues[cast(Color) 239] = 0x4E4E4E;
    rgbValues[cast(Color) 240] = 0x585858;
    rgbValues[cast(Color) 241] = 0x626262;
    rgbValues[cast(Color) 242] = 0x6C6C6C;
    rgbValues[cast(Color) 243] = 0x767676;
    rgbValues[cast(Color) 244] = 0x808080; // grey
    rgbValues[cast(Color) 245] = 0x8A8A8A;
    rgbValues[cast(Color) 246] = 0x949494;
    rgbValues[cast(Color) 247] = 0x9E9E9E;
    rgbValues[cast(Color) 248] = 0xA8A8A8;
    rgbValues[cast(Color) 249] = 0xB2B2B2;
    rgbValues[cast(Color) 250] = 0xBCBCBC;
    rgbValues[cast(Color) 251] = 0xC6C6C6;
    rgbValues[cast(Color) 252] = 0xD0D0D0;
    rgbValues[cast(Color) 253] = 0xDADADA;
    rgbValues[cast(Color) 254] = 0xE4E4E4;
    rgbValues[cast(Color) 255] = 0xEEEEEE;

    palValues[0x000000] = Color.black;
    palValues[0x800000] = Color.maroon;
    palValues[0x008000] = Color.green;
    palValues[0x808000] = Color.olive;
    palValues[0x000080] = Color.navy;
    palValues[0x800080] = Color.purple;
    palValues[0x008080] = Color.teal;
    palValues[0xC0C0C0] = Color.silver;
    palValues[0x808080] = Color.gray;
    palValues[0xFF0000] = Color.red;
    palValues[0x00FF00] = Color.lime;
    palValues[0xFFFF00] = Color.yellow;
    palValues[0x0000FF] = Color.blue;
    palValues[0xFF00FF] = Color.fuchsia;
    palValues[0x00FFFF] = Color.aqua;
    palValues[0xFFFFFF] = Color.white;
    // palValues[0x000000] = cast(Color) 16; // black
    palValues[0x00005F] = cast(Color) 17;
    palValues[0x000087] = cast(Color) 18;
    palValues[0x0000AF] = cast(Color) 19;
    palValues[0x0000D7] = cast(Color) 20;
    // palValues[0x0000FF] = cast(Color) 21; // blue
    palValues[0x005F00] = cast(Color) 22;
    palValues[0x005F5F] = cast(Color) 23;
    palValues[0x005F87] = cast(Color) 24;
    palValues[0x005FAF] = cast(Color) 25;
    palValues[0x005FD7] = cast(Color) 26;
    palValues[0x005FFF] = cast(Color) 27;
    palValues[0x008700] = cast(Color) 28;
    palValues[0x00875F] = cast(Color) 29;
    palValues[0x008787] = cast(Color) 30;
    palValues[0x0087Af] = cast(Color) 31;
    palValues[0x0087D7] = cast(Color) 32;
    palValues[0x0087FF] = cast(Color) 33;
    palValues[0x00AF00] = cast(Color) 34;
    palValues[0x00AF5F] = cast(Color) 35;
    palValues[0x00AF87] = cast(Color) 36;
    palValues[0x00AFAF] = cast(Color) 37;
    palValues[0x00AFD7] = cast(Color) 38;
    palValues[0x00AFFF] = cast(Color) 39;
    palValues[0x00D700] = cast(Color) 40;
    palValues[0x00D75F] = cast(Color) 41;
    palValues[0x00D787] = cast(Color) 42;
    palValues[0x00D7AF] = cast(Color) 43;
    palValues[0x00D7D7] = cast(Color) 44;
    palValues[0x00D7FF] = cast(Color) 45;
    // palValues[0x00FF00] = cast(Color) 46; // lime
    palValues[0x00FF5F] = cast(Color) 47;
    palValues[0x00FF87] = cast(Color) 48;
    palValues[0x00FFAF] = cast(Color) 49;
    palValues[0x00FFd7] = cast(Color) 50;
    // palValues[0x00FFFF] = cast(Color) 51; // aqua
    palValues[0x5F0000] = cast(Color) 52;
    palValues[0x5F005F] = cast(Color) 53;
    palValues[0x5F0087] = cast(Color) 54;
    palValues[0x5F00AF] = cast(Color) 55;
    palValues[0x5F00D7] = cast(Color) 56;
    palValues[0x5F00FF] = cast(Color) 57;
    palValues[0x5F5F00] = cast(Color) 58;
    palValues[0x5F5F5F] = cast(Color) 59;
    palValues[0x5F5F87] = cast(Color) 60;
    palValues[0x5F5FAF] = cast(Color) 61;
    palValues[0x5F5FD7] = cast(Color) 62;
    palValues[0x5F5FFF] = cast(Color) 63;
    palValues[0x5F8700] = cast(Color) 64;
    palValues[0x5F875F] = cast(Color) 65;
    palValues[0x5F8787] = cast(Color) 66;
    palValues[0x5F87AF] = cast(Color) 67;
    palValues[0x5F87D7] = cast(Color) 68;
    palValues[0x5F87FF] = cast(Color) 69;
    palValues[0x5FAF00] = cast(Color) 70;
    palValues[0x5FAF5F] = cast(Color) 71;
    palValues[0x5FAF87] = cast(Color) 72;
    palValues[0x5FAFAF] = cast(Color) 73;
    palValues[0x5FAFD7] = cast(Color) 74;
    palValues[0x5FAFFF] = cast(Color) 75;
    palValues[0x5FD700] = cast(Color) 76;
    palValues[0x5FD75F] = cast(Color) 77;
    palValues[0x5FD787] = cast(Color) 78;
    palValues[0x5FD7AF] = cast(Color) 79;
    palValues[0x5FD7D7] = cast(Color) 80;
    palValues[0x5FD7FF] = cast(Color) 81;
    palValues[0x5FFF00] = cast(Color) 82;
    palValues[0x5FFF5F] = cast(Color) 83;
    palValues[0x5FFF87] = cast(Color) 84;
    palValues[0x5FFFAF] = cast(Color) 85;
    palValues[0x5FFFD7] = cast(Color) 86;
    palValues[0x5FFFFF] = cast(Color) 87;
    palValues[0x870000] = cast(Color) 88;
    palValues[0x87005F] = cast(Color) 89;
    palValues[0x870087] = cast(Color) 90;
    palValues[0x8700AF] = cast(Color) 91;
    palValues[0x8700D7] = cast(Color) 92;
    palValues[0x8700FF] = cast(Color) 93;
    palValues[0x875F00] = cast(Color) 94;
    palValues[0x875F5F] = cast(Color) 95;
    palValues[0x875F87] = cast(Color) 96;
    palValues[0x875FAF] = cast(Color) 97;
    palValues[0x875FD7] = cast(Color) 98;
    palValues[0x875FFF] = cast(Color) 99;
    palValues[0x878700] = cast(Color) 100;
    palValues[0x87875F] = cast(Color) 101;
    palValues[0x878787] = cast(Color) 102;
    palValues[0x8787AF] = cast(Color) 103;
    palValues[0x8787D7] = cast(Color) 104;
    palValues[0x8787FF] = cast(Color) 105;
    palValues[0x87AF00] = cast(Color) 106;
    palValues[0x87AF5F] = cast(Color) 107;
    palValues[0x87AF87] = cast(Color) 108;
    palValues[0x87AFAF] = cast(Color) 109;
    palValues[0x87AFD7] = cast(Color) 110;
    palValues[0x87AFFF] = cast(Color) 111;
    palValues[0x87D700] = cast(Color) 112;
    palValues[0x87D75F] = cast(Color) 113;
    palValues[0x87D787] = cast(Color) 114;
    palValues[0x87D7AF] = cast(Color) 115;
    palValues[0x87D7D7] = cast(Color) 116;
    palValues[0x87D7FF] = cast(Color) 117;
    palValues[0x87FF00] = cast(Color) 118;
    palValues[0x87FF5F] = cast(Color) 119;
    palValues[0x87FF87] = cast(Color) 120;
    palValues[0x87FFAF] = cast(Color) 121;
    palValues[0x87FFD7] = cast(Color) 122;
    palValues[0x87FFFF] = cast(Color) 123;
    palValues[0xAF0000] = cast(Color) 124;
    palValues[0xAF005F] = cast(Color) 125;
    palValues[0xAF0087] = cast(Color) 126;
    palValues[0xAF00AF] = cast(Color) 127;
    palValues[0xAF00D7] = cast(Color) 128;
    palValues[0xAF00FF] = cast(Color) 129;
    palValues[0xAF5F00] = cast(Color) 130;
    palValues[0xAF5F5F] = cast(Color) 131;
    palValues[0xAF5F87] = cast(Color) 132;
    palValues[0xAF5FAF] = cast(Color) 133;
    palValues[0xAF5FD7] = cast(Color) 134;
    palValues[0xAF5FFF] = cast(Color) 135;
    palValues[0xAF8700] = cast(Color) 136;
    palValues[0xAF875F] = cast(Color) 137;
    palValues[0xAF8787] = cast(Color) 138;
    palValues[0xAF87AF] = cast(Color) 139;
    palValues[0xAF87D7] = cast(Color) 140;
    palValues[0xAF87FF] = cast(Color) 141;
    palValues[0xAFAF00] = cast(Color) 142;
    palValues[0xAFAF5F] = cast(Color) 143;
    palValues[0xAFAF87] = cast(Color) 144;
    palValues[0xAFAFAF] = cast(Color) 145;
    palValues[0xAFAFD7] = cast(Color) 146;
    palValues[0xAFAFFF] = cast(Color) 147;
    palValues[0xAFD700] = cast(Color) 148;
    palValues[0xAFD75F] = cast(Color) 149;
    palValues[0xAFD787] = cast(Color) 150;
    palValues[0xAFD7AF] = cast(Color) 151;
    palValues[0xAFD7D7] = cast(Color) 152;
    palValues[0xAFD7FF] = cast(Color) 153;
    palValues[0xAFFF00] = cast(Color) 154;
    palValues[0xAFFF5F] = cast(Color) 155;
    palValues[0xAFFF87] = cast(Color) 156;
    palValues[0xAFFFAF] = cast(Color) 157;
    palValues[0xAFFFD7] = cast(Color) 158;
    palValues[0xAFFFFF] = cast(Color) 159;
    palValues[0xD70000] = cast(Color) 160;
    palValues[0xD7005F] = cast(Color) 161;
    palValues[0xD70087] = cast(Color) 162;
    palValues[0xD700AF] = cast(Color) 163;
    palValues[0xD700D7] = cast(Color) 164;
    palValues[0xD700FF] = cast(Color) 165;
    palValues[0xD75F00] = cast(Color) 166;
    palValues[0xD75F5F] = cast(Color) 167;
    palValues[0xD75F87] = cast(Color) 168;
    palValues[0xD75FAF] = cast(Color) 169;
    palValues[0xD75FD7] = cast(Color) 170;
    palValues[0xD75FFF] = cast(Color) 171;
    palValues[0xD78700] = cast(Color) 172;
    palValues[0xD7875F] = cast(Color) 173;
    palValues[0xD78787] = cast(Color) 174;
    palValues[0xD787AF] = cast(Color) 175;
    palValues[0xD787D7] = cast(Color) 176;
    palValues[0xD787FF] = cast(Color) 177;
    palValues[0xD7AF00] = cast(Color) 178;
    palValues[0xD7AF5F] = cast(Color) 179;
    palValues[0xD7AF87] = cast(Color) 180;
    palValues[0xD7AFAF] = cast(Color) 181;
    palValues[0xD7AFD7] = cast(Color) 182;
    palValues[0xD7AFFF] = cast(Color) 183;
    palValues[0xD7D700] = cast(Color) 184;
    palValues[0xD7D75F] = cast(Color) 185;
    palValues[0xD7D787] = cast(Color) 186;
    palValues[0xD7D7AF] = cast(Color) 187;
    palValues[0xD7D7D7] = cast(Color) 188;
    palValues[0xD7D7FF] = cast(Color) 189;
    palValues[0xD7FF00] = cast(Color) 190;
    palValues[0xD7FF5F] = cast(Color) 191;
    palValues[0xD7FF87] = cast(Color) 192;
    palValues[0xD7FFAF] = cast(Color) 193;
    palValues[0xD7FFD7] = cast(Color) 194;
    palValues[0xD7FFFF] = cast(Color) 195;
    // palValues[0xFF0000] = cast(Color) 196; // red
    palValues[0xFF005F] = cast(Color) 197;
    palValues[0xFF0087] = cast(Color) 198;
    palValues[0xFF00AF] = cast(Color) 199;
    palValues[0xFF00D7] = cast(Color) 200;
    // palValues[0xFF00FF] = cast(Color) 201; // fuchsia
    palValues[0xFF5F00] = cast(Color) 202;
    palValues[0xFF5F5F] = cast(Color) 203;
    palValues[0xFF5F87] = cast(Color) 204;
    palValues[0xFF5FAF] = cast(Color) 205;
    palValues[0xFF5FD7] = cast(Color) 206;
    palValues[0xFF5FFF] = cast(Color) 207;
    palValues[0xFF8700] = cast(Color) 208;
    palValues[0xFF875F] = cast(Color) 209;
    palValues[0xFF8787] = cast(Color) 210;
    palValues[0xFF87AF] = cast(Color) 211;
    palValues[0xFF87D7] = cast(Color) 212;
    palValues[0xFF87FF] = cast(Color) 213;
    palValues[0xFFAF00] = cast(Color) 214;
    palValues[0xFFAF5F] = cast(Color) 215;
    palValues[0xFFAF87] = cast(Color) 216;
    palValues[0xFFAFAF] = cast(Color) 217;
    palValues[0xFFAFD7] = cast(Color) 218;
    palValues[0xFFAFFF] = cast(Color) 219;
    palValues[0xFFD700] = cast(Color) 220;
    palValues[0xFFD75F] = cast(Color) 221;
    palValues[0xFFD787] = cast(Color) 222;
    palValues[0xFFD7AF] = cast(Color) 223;
    palValues[0xFFD7D7] = cast(Color) 224;
    palValues[0xFFD7FF] = cast(Color) 225;
    // palValues[0xFFFF00] = cast(Color) 226; // yellow
    palValues[0xFFFF5F] = cast(Color) 227;
    palValues[0xFFFF87] = cast(Color) 228;
    palValues[0xFFFFAF] = cast(Color) 229;
    palValues[0xFFFFD7] = cast(Color) 230;
    // palValues[0xFFFFFF] = cast(Color) 231; // white
    palValues[0x080808] = cast(Color) 232;
    palValues[0x121212] = cast(Color) 233;
    palValues[0x1C1C1C] = cast(Color) 234;
    palValues[0x262626] = cast(Color) 235;
    palValues[0x303030] = cast(Color) 236;
    palValues[0x3A3A3A] = cast(Color) 237;
    palValues[0x444444] = cast(Color) 238;
    palValues[0x4E4E4E] = cast(Color) 239;
    palValues[0x585858] = cast(Color) 240;
    palValues[0x626262] = cast(Color) 241;
    palValues[0x6C6C6C] = cast(Color) 242;
    palValues[0x767676] = cast(Color) 243;
    // palValues[0x808080] = cast(Color) 244; // grey
    palValues[0x8A8A8A] = cast(Color) 245;
    palValues[0x949494] = cast(Color) 246;
    palValues[0x9E9E9E] = cast(Color) 247;
    palValues[0xA8A8A8] = cast(Color) 248;
    palValues[0xB2B2B2] = cast(Color) 249;
    palValues[0xBCBCBC] = cast(Color) 250;
    palValues[0xC6C6C6] = cast(Color) 251;
    palValues[0xD0D0D0] = cast(Color) 252;
    palValues[0xDADADA] = cast(Color) 253;
    palValues[0xE4E4E4] = cast(Color) 254;
    palValues[0xEEEEEE] = cast(Color) 255;
}

/**
 * Obtain the numeric value of the RGB for the color.
 *
 * Params:
 *  c = a Color
 * Returns: Numeric RGB value for color, or -1 if it cannot be represented.
 */
int toHex(Color c) pure @safe
{
    if ((c & Color.isRGB) != 0)
    {
        return (c & 0xffffff);
    }
    if (c in rgbValues)
    {
        return rgbValues[c];
    }
    return (-1);
}

/**
 * Create a color from RGB values.
 *
 * Params:
 *   rgb = hex value, red << 16 | green << 8 | blue
 * Returns: The associated Color, or Color.invalid if a bad value for rgb was supplied.
 */
Color fromHex(int rgb) pure @safe
{
    if (rgb < 1 << 24)
    {
        return cast(Color) rgb | Color.isRGB;
    }
    return Color.invalid;
}

/**
 * Convert a color to RGB form.  This is useful to convert
 * palette based colors to their full RGB values, which will provide
 * fidelity when the terminal supports it, but consequently does not
 * honor terminal preferences for color palettes.
 *
 * Params:
 *   c = a valid Color
 * Returns: An RGB format Color, Color.invalid if it cannot be determined.
 */
Color toRGB(Color c) pure @safe
{
    if ((c & Color.isRGB) != 0)
    {
        return c;
    }
    if (c in rgbValues)
    {
        return cast(Color) rgbValues[c] | Color.isRGB;
    }
    return Color.invalid;
}

/**
 * Is the color in RGB format? RGB format colors will try to be accurate
 * on the terminal, and will not honor user preferences.
 * Params:
 *   c = a valid color
 * Returns: true if the color is an RGB format color
 */
bool isRGB(Color c) pure @safe
{
    return (c & Color.isRGB) != 0;
}

/// Return true if the color is valid.
bool isValid(Color c) pure @safe
{
    return (c != Color.invalid);
}

/**
 * Given a color, try to find an associated palette entry for it.
 * This will try to find the lowest numbered palette entry.
 * The palette entry might be a higher numbered color than the
 * terminal can support, if it does not support a 256 color palette.
 *
 * Params:
 *   c = a valid Color
 *   numColors = the size of the palette
 *
 * Returns: the palette Color closest matching c
 */
Color toPalette(Color c, int numColors) @safe
{
    import std.functional;

    switch (c)
    {
    case Color.reset, Color.invalid:
        return c;
    default:
        return memoize!bestColor(c, numColors);
    }
}

/// Return true if c1 is darker than c2.
bool darker(Color c1, Color c2) @safe
{
    import std.functional;

    auto d1 = memoize!redMean(c1, Color.black);
    auto d2 = memoize!redMean(c2, Color.black);
    return (d1 < d2);
}

/**
 * decompose a color into red, green, and blue values.
 */
auto decompose(Color c) pure @safe
{
    c = toRGB(c);
    return Tuple!(int, int, int)((c & 0xff0000) >> 16, ((c & 0xff00) >> 8), (c & 0xff));
}

/**
 * decompose a color into red, green, and blue values.
 */
void decompose(Color c, ref int r, ref int g, ref int b) pure @safe
{
    c = toRGB(c);
    r = int(c & 0xff0000) >> 16;
    g = int(c & 0xff00) >> 8;
    b = int(c & 0xff);
}

/**
 * Name returns W3C name or an empty string if no arguments
 * if passed true as an argument it will falls back to
 * the CSS hex string if no W3C name found '#ABCDEF'
 */
string name(Color c, bool css = false) pure @safe
{
    foreach (name, color; colorsByName)
    {
        if (c == color)
        {
            return name;
        }
    }
    if (css)
    {
        return c.css();
    }
    return "";
}

string css(Color c) pure @safe
{
    if (!c.isValid)
    {
        return "";
    }
    return format("#%06X", c.toHex());
}

unittest
{
    assert(toPalette(Color.red, 16) == Color.red);
    assert(toPalette(cast(Color) 0x00FF00 | Color.isRGB, 16) == Color.lime);
    assert(toHex(Color.invalid) == -1);
    assert(toRGB(cast(Color) 512) == Color.invalid);
    assert(toRGB(Color.reset) == Color.invalid);
    assert(fromHex(cast(int) Color.reset) == Color.invalid);
    for (int i = 0; i < 256; i++)
    {
        auto r = toHex(cast(Color) i);
        assert(r >= 0);
        auto c = fromHex(r);
        assert(toRGB(c) == c);
        assert(c != Color.invalid);
        auto p = toPalette(c, 256);
        assert(p != Color.invalid);
        if (i < 16)
        {
            assert(p == i);
        }
        else
        {
            assert(p < 256);
            if (p > 15) // sometimes we map to a lower palette color
            {
                assert(p == i);
            }
        }
    }
    for (Color c = Color.black; c <= Color.white; c++)
    {
        assert(toPalette(toRGB(c), 256) == c);
    }
    assert(decompose(Color.yellowGreen)[0] == 0x9a);
    assert(decompose(Color.yellowGreen)[1] == 0xcd);
    assert(decompose(Color.yellowGreen)[2] == 0x32);
    assert(decompose(Color.red)[0] == 0xff);
    assert(decompose(Color.red)[1] == 0);
    assert(decompose(Color.red)[2] == 0);

    assert(Color.red.name == "red");
    assert(Color.darkKhaki.name == "darkkhaki");
    assert(Color.red.css == "#FF0000");
    assert(Color.red.toRGB.name(true) == "#FF0000");
}

private long redMean(Color c1, Color c2) pure @safe
{
    int r1, r2, g1, g2, b1, b2;
    decompose(c1, r1, g1, b1);
    decompose(c2, r2, g2, b2);
    long ar = (r1 + r2) / 2;
    long dr = (r1 - r2);
    long dg = (g1 - g2);
    long db = (b1 - b2);

    long dist;

    // see https://en.wikipedia.org/wiki/Color_difference
    dist = ((2 + ar / 256) * dr * dr) + (4 * dg * dg) + ((2 + ((255 - ar) / 256)) * db * db);

    // not bothering with the square root, since we are just comparing values
    return dist;
}

private Color bestColor(Color c, int numColors) pure @safe
{
    // this is an expensive operation, so you really want
    // to memoize it.
    long abs(long a) pure
    {
        return a >= 0 ? a : -a;
    }

    c = toRGB(c);
    if (c == Color.invalid)
    {
        return c;
    }

    // look for a perfect fit first before we start doing hard math
    auto hex = toHex(c);
    if ((hex in palValues) && (palValues[hex] <= numColors))
    {
        return (palValues[hex]);
    }

    if (numColors == 0)
    {
        auto d1 = redMean(c, Color.black);
        auto d2 = redMean(c, Color.white);
        return abs(d1) < abs(d2) ? Color.black : Color.white;
    }
    if (numColors > 256)
    {
        numColors = 256;
    }
    auto bestDist = long.max;
    auto bestColor = Color.invalid;
    for (Color pal = Color.black; pal < numColors; pal++)
    {
        auto d = redMean(c, toRGB(pal));
        if (d < bestDist)
        {
            bestDist = d;
            bestColor = pal;
        }
    }

    return (bestColor);
}

unittest
{
    import std.stdio;

    Color v;
    assert(v == Color.invalid);
    assert(bestColor(Color.red, 16) == Color.red);
    assert(bestColor(Color.red, 256) == Color.red);
    assert(bestColor(Color.paleGreen, 256) == cast(Color) 120);
    assert(bestColor(Color.darkSlateBlue, 256) == cast(Color) 60);
    assert(bestColor(fromHex(0xfe0000), 16) == Color.red);
}

unittest
{
    import std.stdio;

    assert(toPalette(Color.red, 16) == Color.red);
    assert(toPalette(Color.red, 256) == Color.red);
    assert(toPalette(Color.paleGreen, 256) == cast(Color) 120);
    assert(toPalette(Color.darkSlateBlue, 256) == cast(Color) 60);
    assert(toPalette(fromHex(0xfe0000), 16) == Color.red);
}

// ColorNames holds the written names of colors. Useful to present a list of
// recognized named colors.
static immutable Color[string] colorsByName;

shared static this() @safe
{
    colorsByName = [
        "black": Color.black,
        "maroon": Color.maroon,
        "green": Color.green,
        "olive": Color.olive,
        "navy": Color.navy,
        "purple": Color.purple,
        "teal": Color.teal,
        "silver": Color.silver,
        "gray": Color.gray,
        "red": Color.red,
        "lime": Color.lime,
        "yellow": Color.yellow,
        "blue": Color.blue,
        "fuchsia": Color.fuchsia,
        "aqua": Color.aqua,
        "white": Color.white,
        "aliceblue": Color.aliceBlue,
        "antiquewhite": Color.antiqueWhite,
        "aquamarine": Color.aquamarine,
        "azure": Color.azure,
        "beige": Color.beige,
        "bisque": Color.bisque,
        "blanchedalmond": Color.blanchedAlmond,
        "blueviolet": Color.blueViolet,
        "brown": Color.brown,
        "burlywood": Color.burlyWood,
        "cadetblue": Color.cadetBlue,
        "chartreuse": Color.chartreuse,
        "chocolate": Color.chocolate,
        "coral": Color.coral,
        "cornflowerblue": Color.cornflowerBlue,
        "cornsilk": Color.cornsilk,
        "crimson": Color.crimson,
        "darkblue": Color.darkBlue,
        "darkcyan": Color.darkCyan,
        "darkgoldenrod": Color.darkGoldenrod,
        "darkgray": Color.darkGray,
        "darkgreen": Color.darkGreen,
        "darkkhaki": Color.darkKhaki,
        "darkmagenta": Color.darkMagenta,
        "darkolivegreen": Color.darkOliveGreen,
        "darkorange": Color.darkOrange,
        "darkorchid": Color.darkOrchid,
        "darkred": Color.darkRed,
        "darksalmon": Color.darkSalmon,
        "darkseagreen": Color.darkSeaGreen,
        "darkslateblue": Color.darkSlateBlue,
        "darkslategray": Color.darkSlateGray,
        "darkturquoise": Color.darkTurquoise,
        "darkviolet": Color.darkViolet,
        "deeppink": Color.deepPink,
        "deepskyblue": Color.deepSkyBlue,
        "dimgray": Color.dimGray,
        "dodgerblue": Color.dodgerBlue,
        "firebrick": Color.fireBrick,
        "floralwhite": Color.floralWhite,
        "forestgreen": Color.forestGreen,
        "gainsboro": Color.gainsboro,
        "ghostwhite": Color.ghostWhite,
        "gold": Color.gold,
        "goldenrod": Color.goldenrod,
        "greenyellow": Color.greenYellow,
        "honeydew": Color.honeydew,
        "hotpink": Color.hotPink,
        "indianred": Color.indianRed,
        "indigo": Color.indigo,
        "ivory": Color.ivory,
        "khaki": Color.khaki,
        "lavender": Color.lavender,
        "lavenderblush": Color.lavenderBlush,
        "lawngreen": Color.lawnGreen,
        "lemonchiffon": Color.lemonChiffon,
        "lightblue": Color.lightBlue,
        "lightcoral": Color.lightCoral,
        "lightcyan": Color.lightCyan,
        "lightgoldenrodyellow": Color.lightGoldenrodYellow,
        "lightgray": Color.lightGray,
        "lightgreen": Color.lightGreen,
        "lightpink": Color.lightPink,
        "lightsalmon": Color.lightSalmon,
        "lightseagreen": Color.lightSeaGreen,
        "lightskyblue": Color.lightSkyBlue,
        "lightslategray": Color.lightSlateGray,
        "lightsteelblue": Color.lightSteelBlue,
        "lightyellow": Color.lightYellow,
        "limegreen": Color.limeGreen,
        "linen": Color.linen,
        "mediumaquamarine": Color.mediumAquamarine,
        "mediumblue": Color.mediumBlue,
        "mediumorchid": Color.mediumOrchid,
        "mediumpurple": Color.mediumPurple,
        "mediumseagreen": Color.mediumSeaGreen,
        "mediumslateblue": Color.mediumSlateBlue,
        "mediumspringgreen": Color.mediumSpringGreen,
        "mediumturquoise": Color.mediumTurquoise,
        "mediumvioletred": Color.mediumVioletRed,
        "midnightblue": Color.midnightBlue,
        "mintcream": Color.mintCream,
        "mistyrose": Color.mistyRose,
        "moccasin": Color.moccasin,
        "navajowhite": Color.navajoWhite,
        "oldlace": Color.oldLace,
        "olivedrab": Color.oliveDrab,
        "orange": Color.orange,
        "orangered": Color.orangeRed,
        "orchid": Color.orchid,
        "palegoldenrod": Color.paleGoldenrod,
        "palegreen": Color.paleGreen,
        "paleturquoise": Color.paleTurquoise,
        "palevioletred": Color.paleVioletRed,
        "papayawhip": Color.papayaWhip,
        "peachpuff": Color.peachPuff,
        "peru": Color.peru,
        "pink": Color.pink,
        "plum": Color.plum,
        "powderblue": Color.powderBlue,
        "rebeccapurple": Color.rebeccaPurple,
        "rosybrown": Color.rosyBrown,
        "royalblue": Color.royalBlue,
        "saddlebrown": Color.saddleBrown,
        "salmon": Color.salmon,
        "sandybrown": Color.sandyBrown,
        "seagreen": Color.seaGreen,
        "seashell": Color.seashell,
        "sienna": Color.sienna,
        "skyblue": Color.skyBlue,
        "slateblue": Color.slateBlue,
        "slategray": Color.slateGray,
        "snow": Color.snow,
        "springgreen": Color.springGreen,
        "steelblue": Color.steelBlue,
        "tan": Color.tan,
        "thistle": Color.thistle,
        "tomato": Color.tomato,
        "turquoise": Color.turquoise,
        "violet": Color.violet,
        "wheat": Color.wheat,
        "whitesmoke": Color.whiteSmoke,
        "yellowgreen": Color.yellowGreen,
        "grey": Color.gray,
        "dimgrey": Color.dimGray,
        "darkgrey": Color.darkGray,
        "darkslategrey": Color.darkSlateGray,
        "lightgrey": Color.lightGray,
        "lightslategrey": Color.lightSlateGray,
        "slategrey": Color.slateGray,

        "reset": Color.reset, // actually the terminal default
    ];
}
