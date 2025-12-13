/**
 * Style module for dcell, containing definitions associaeted with text styling.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.style;

public import dcell.attr;
public import dcell.color;

/**
 * Text styling, which is an aggregate of attributes like bold or reverse,
 * coloring (both foreground and background) and other attributes such as
 * being clickable (to open a URL for example).
 */
struct Style
{
    Color fg; /// foreground color
    Color bg; /// background color
    string url; /// clickable URL, or none if empty
    Attr attr; /// text attributes
}
