/**
 * Attributes module for dcell.
 *
 * Copyright: Copyright 2022 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.attr;

/** 
 * Text attributes that do not include color.
 */
enum Attr : int
{
    none = 0, /// normal, plain text
    bold = 1 << 0,
    blink = 1 << 1,
    reverse = 1 << 2, /// foreground and background colors reversed
    underline = 1 << 3,
    dim = 1 << 4,
    italic = 1 << 5,
    strikethrough = 1 << 6,
    invalid = -1, // invalid attribute
}
