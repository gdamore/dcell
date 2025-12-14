/**
 * Attributes module for dcell.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
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
enum Attr
{
    none = 0, /// normal, plain text
    bold = 1 << 0,
    blink = 1 << 1,
    reverse = 1 << 2, /// foreground and background colors reversed
    dim = 1 << 3,
    italic = 1 << 4,
    strikethrough = 1 << 5,

    /// Underlines are a bit field, because they can be styled.  Use a ^= underlineMask; a |= plainUnderline.
    /// If you only use simple underlines you can just set underline as a bool.
    underline = 1 << 6,
    plainUnderline = underline | 0 << 7,
    doubleUnderline = underline | 1 << 7,
    curlyUnderline = underline | 2 << 7, // underline styles take bits 7-9
    dottedUnderline = underline | 3 << 7,
    dashedUnderline = underline | 4 << 7,
    underlineMask = underline | 7 << 7, // all bits set for underline

    invalid = 1 << 15, // invalid attribute
    init = invalid,
}
