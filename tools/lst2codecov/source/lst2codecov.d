/**
 * Lst2CodeCov module implements logic to convert DMD *.lst coverage
 * files into simple codecov custom JSON.
 *
 * Copyright: Copyright 2026 Garrett D'Amore
 * Authors: Garrett D'Amore
 * License:
 *   Distributed under the Boost Software License, Version 1.0.
 *   (See accompanying file LICENSE or https://www.boost.org/LICENSE_1_0.txt)
 *   SPDX-License-Identifier: BSL-1.0
 */
module lst2codecov;

alias FileData = int[string];

// coverage is map of filenames -> line number (as string) -> count
static int[string][string] coverage;

void main()
{
    import std.conv;
    import std.string;
    import std.file;
    import std.json;

    // Approach - find all the *.lst files.
    // The files have a format of:
    // count|source
    // (count might be empty, if nothing is executed)
    // (count might be 0000000 if the line is missed)
    // last line is "filename is %% covered" or "filename has no code"
    // There will not be a | character on that last line.

    // for now shallow only
    foreach (entry; dirEntries(".", "*.lst", SpanMode.shallow))
    {
        auto lineNo = 0;
        auto fileName = entry.name;
        int[string] counts;
        auto lst = readText(entry.name);
        foreach (line; lst.splitLines())
        {
            lineNo++;
            auto parts = line.split("|");
            if (parts.length == 1)
            {
                parts = line.split(" ");
                fileName = parts[0].idup;
            }
            else
            {
                auto countStr = parts[0].strip;
                if (countStr.isNumeric()) {
                    counts[lineNo.to!string] = countStr.to!int;
                }
            }
        }
        coverage[fileName] = counts;
    }

    JSONValue js = ["coverage" : JSONValue(coverage)];

    write("coverage.json", js.toString);
}
