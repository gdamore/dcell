# Dcell

[![Stand With Ukraine](https://raw.githubusercontent.com/vshymanskyy/StandWithUkraine/main/badges/StandWithUkraine.svg)](https://stand-with-ukraine.pp.ua)
[![DMD](https://img.shields.io/github/actions/workflow/status/gdamore/dcell/dmd.yml?branch=main&logoColor=grey&logo=D&label=)](https://github.com/gdamore/dcell/actions/workflows/dmd.yml)
[![LDC](https://img.shields.io/github/actions/workflow/status/gdamore/dcell/ldc.yml?branch=main&logoColor=grey&logo=llvm&label=)](https://github.com/gdamore/dcell/actions/workflows/ldc.yml)

_Dcell_ is a rewrite, or a language port, of my well known
[Tcell](https://github.com/gdamore/tcell) (for Go) project into D.

This is a library for building terminal applications that need to work
with a full screen interface.  It is more of an enabling API (substrate)
than a high-level widget library.  It is intended that some may use
this to write rich frameworks for terminal user interfaces, while
others may prefer a lower level approach to build applications like games,
visualizations, or other things that need more complete control.

## Examples

Examples applications (simple) are located in the `demo` directory.
If you have applications or frameworks built upon _Dcell_ that you'd
like to share with others, please let us know!

## Status

At present, _Dcell_ supports most of the things that _Tcell_ supports.
We are very close to a 1.0 stable release, but we would like feedback on
the API and hopefully to find some consumers.

## Features

Here are some of the features you'll find in _Dcell_:

* Fully cross-platform (Windows, macOS, Linux, BSD, etc.)
* Rich keyboard support (including several advanced protocols)
* Full Unicode support, including grapheme clusters.
* Support for pretty much every terminal emulator or real terminal still in use.
* Mouse support, including click, drag, and motion events.
* Rich color support, including 256- and 24-bit color options, with graceful fallbacks.
* Bracketed paste and direct clipboard support.
* Window & icon title support.
* Synchronized drawing (no tearing e.g. during resize.)
* Fully `@safe` API
* Support for external `poll()` etc. loops, or simple single threaded applications (no concurrency or threads.)
* Performant - optimized to minimize unnecessary screen writes.

## Future Directions:

* System notifications (via OSC 777 or OSC 9)
* Fallback characters using VT line drawing font
* Theme notifications (Dark vs. Light mode)
* Opt-in key-release events where supported
* Sixel or Kitty graphics protocol
