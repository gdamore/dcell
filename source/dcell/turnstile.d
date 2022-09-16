/**
 * Private turnstile implementation.
 *
 * Copyright: Copyright 2022 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module dcell.turnstile;

import core.sync.condition;

package:

/**
 * Turnstile implements a thread safe primitive -- applications can
 * set or wait for a condition.
 */
class Turnstile
{
    private Mutex m;
    private Condition c;
    private bool val;

    this()
    {
        m = new Mutex();
        c = new Condition(m);
    }

    void set(this T)(bool b) if ((is(T == Turnstile) || is(T == shared Turnstile)))
    {
        synchronized (m)
        {
            val = b;
            c.notifyAll();
        }
    }

    bool get(this T)() if ((is(T == Turnstile) || is(T == shared Turnstile)))
    {
        bool b;
        synchronized (m)
        {
            b = val;
        }
        return b;
    }

    void wait(this T)(bool b) if (is(T == Turnstile) || is(T == shared Turnstile))
    {
        synchronized (m)
        {
            while (val != b)
            {
                c.wait();
            }
        }
    }
}
