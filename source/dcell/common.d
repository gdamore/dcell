/**
 * Common module for dcell, it contains some package wide definitions.
 *
 * Copyright: Copyright 2025 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.common;

import dcell.screen;
import dcell.vt;

/**
 * Obtain a new screen. On POSIX this is connected to /dev/tty
 * using the $TERM environment variable.
 */
Screen newScreen()
{
    return new VtScreen();
}
