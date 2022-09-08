# dcell

[![Stand With Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://stand-with-ukraine.pp.ua)

This is an early effort to "rewrite" my well-known
[tcell](https://github.com/gdamore/tcell) (for Go)
project into D.

At present, this works reasonably well for most TTY type devices
(think xterm, Terminal, Term2, etc) on Posix (Linux, macOS, etc)
systems.

Windows support is missing.

It supports most of the things that tcell supports.  The API is
subject to change, as I'm working on improving this.

The demos/ directory has a few demo programs which might be
interesting.  These were ported from tcell.

This effort was done principally to learn D, but hopefully it may
someday later be useless because it appears that D does not have an
analog for tcell.
