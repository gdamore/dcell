// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.turnstile;

import core.sync.condition;

package shared class Turnstile
{
    private Mutex m;
    private Condition c;
    private bool val;

    this()
    {
        m = new shared Mutex();
        c = new shared Condition(m);
    }

    void set(bool b)
    {
        synchronized (m)
        {
            val = b;
            c.notifyAll();
        }
    }

    bool get()
    {
        bool b;
        synchronized (m)
        {
            b = val;
        }
        return b;
    }

    void wait(bool b)
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
