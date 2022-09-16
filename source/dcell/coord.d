/**
 * Coordinates module for dcell.
 *
 * Copyright: Copyright 2022 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.coord;

/** 
 * Coordinates are X, Y values.
 */
struct Coord
{
    int x; // aka column
    int y; // aka row
}
