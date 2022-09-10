// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.cursor;

import core.time;

/** 
 * The cursor shape - the implementation may not support all of these,
 * but hopefully at least reset and hidden are supported.
 */
enum Cursor
{
    current = 0, // don't change cursor shape or visbility
    reset, // reset to terminal default
    hidden,
    block,
    underline,
    bar,
    blinkingBlock,
    blinkingUnderline,
    blinkingBar,
}
