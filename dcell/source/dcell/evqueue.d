// Copyright 2022 Garrett D'Amore
//
// Distributed under the Boost Software License, Version 1.0.
// (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)

module dcell.evqueue;

import core.sync.condition;
import core.sync.mutex;
import core.time;
import std.concurrency;

import dcell.event;

package class EventQueue
{
    this()
    {
        mx = new Mutex();
        cv = new Condition(mx);
    }

    Event receive(this Q)(Duration dur)
            if (is(Q == EventQueue) || is(Q == shared EventQueue))
    {
        Event ev;
        synchronized (mx)
        {
            while ((q.length == 0) && !closed)
            {
                if (!cv.wait(dur))
                {
                    return (ev);
                }
            }

            if (closed)
            {
                return Event(EventType.closed);
            }
            ev = q[0];
            q = q[1 .. $];
        }

        return ev;
    }

    Event receive(this Q)() if (is(Q == EventQueue) || is(Q == shared EventQueue))
    {
        Event ev;
        synchronized (mx)
        {
            while ((q.length == 0) && !closed)
            {
                cv.wait();
            }
            if (closed)
            {
                return Event(EventType.closed);
            }

            ev = q[0];
            q = q[1 .. $];
        }

        return ev;
    }

    void close(this Q)() if (is(Q == EventQueue) || is(Q == shared EventQueue))
    {
        synchronized (mx)
        {
            closed = true;
            cv.notifyAll();
        }
    }

    void send(this Q)(Event ev) if (is(Q == EventQueue) || is(Q == shared EventQueue))
    {
        synchronized (mx)
        {
            if (!closed) // cannot send any more events after close
            {
                q ~= ev;
                cv.notify();
            }
        }
    }

private:

    Mutex mx;
    Condition cv;
    Event[] q;
    bool closed;
}

unittest
{
    import core.thread;
    auto eq = new EventQueue();

    eq.send(Event(EventType.key));
    assert(eq.receive().type  == EventType.key);

    assert(eq.receive(msecs(10)).type == EventType.none);

    spawn(function(shared EventQueue eq){
        Thread.sleep(msecs(50));
        eq.send(Event(EventType.mouse));
    }, cast(shared EventQueue)eq);
    assert(eq.receive().type == EventType.mouse);
    eq.close();
    assert(eq.receive().type == EventType.closed);
}
