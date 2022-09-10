// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.glyph;

/** 
 * Common symbols.
 */
class Glyph
{
    public enum
    {
        sterling = '£',
        downArrow = '↓',
        leftArrow = '←',
        rightArrow = '→',
        upArrow = '↑',
        bullet = '·',
        board = '░',
        checkerBoard = '▒',
        degree = '°',
        diamond = '◆',
        greaterThanEqual = '≥',
        pi = 'π',
        horizLine = '─',
        lantern = '§',
        plus = '┼',
        lessThanEqual = '≤',
        lowerLeftCorner = '└',
        lowerRightCorner = '┘',
        notEqual = '≠',
        plusMinus = '±',
        s1 = '⎺',
        s3 = '⎻',
        s7 = '⎼',
        s9 = '⎽',
        block = '█',
        topTee = '┬',
        rightTee = '┤',
        leftTee = '├',
        bottomTee = '┴',
        upperLeftCorner = '┌',
        upperRightCorner = '┐',
        vertLine = '│',
    }

    static immutable string[dchar] fallbacks;

    shared static this()
    {
        fallbacks[sterling] = "f";
        fallbacks[downArrow] = "v";
        fallbacks[leftArrow] = "<";
        fallbacks[rightArrow] = ">";
        fallbacks[upArrow] = "^";
        fallbacks[bullet] = "o";
        fallbacks[board] = "#";
        fallbacks[checkerBoard] = ":";
        fallbacks[degree] = "\\";
        fallbacks[diamond] = "+";
        fallbacks[greaterThanEqual] = ">";
        fallbacks[pi] = "*";
        fallbacks[horizLine] = "-";
        fallbacks[lantern] = "#";
        fallbacks[plus] = "+";
        fallbacks[lessThanEqual] = "<";
        fallbacks[lowerLeftCorner] = "+";
        fallbacks[lowerRightCorner] = "+";
        fallbacks[notEqual] = "!";
        fallbacks[plusMinus] = "#";
        fallbacks[s1] = "~";
        fallbacks[s3] = "-";
        fallbacks[s7] = "-";
        fallbacks[s9] = "_";
        fallbacks[block] = "#";
        fallbacks[topTee] = "+";
        fallbacks[rightTee] = "+";
        fallbacks[leftTee] = "+";
        fallbacks[bottomTee] = "+";
        fallbacks[upperLeftCorner] = "+";
        fallbacks[upperRightCorner] = "+";
        fallbacks[vertLine] = "|";
    }
}
