# NormalizedTimeTypes

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://bluesmoon.github.io/NormalizedTimeTypes.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://bluesmoon.github.io/NormalizedTimeTypes.jl/dev/)
[![Build Status](https://github.com/bluesmoon/NormalizedTimeTypes.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/bluesmoon/NormalizedTimeTypes.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://coveralls.io/repos/github/bluesmoon/NormalizedTimeTypes.jl/badge.svg?branch=main)](https://coveralls.io/github/bluesmoon/NormalizedTimeTypes.jl?branch=main)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

## Overview

**NormalizedTimeTypes.jl** handles the messy reality of time data from web and non-Julia sources. It provides a unified way to work with dates and times that arrive in various string formats, timezone representations, and precision levels—often from JavaScript systems where millisecond precision is standard.

Following Postel's Law ("be strict in what you produce, lenient in what you accept"), this package:
- Accepts diverse input formats: ISO 8601, RFC 2822, space-separated, T-separated, with or without timezone info
- Parses legacy timezone abbreviations (EST, PST, etc.) and resolves them to their most common regions
- Handles DST transitions gracefully, including non-existent times during spring-forward transitions
- Normalizes everything to a consistent internal representation with millisecond precision
- Provides access to UTC, local timezone, and Unix timestamp forms simultaneously

## Quick Start

**Note** You will need the `TimeZones` module in your project for this package to be most useful. Install it with:

```julia
] add NormalizedTimeTypes TimeZones
```

### Basic Usage

```jldoctest; filter = r"^(..@ NormalizedTimeTypes) [^\n]*(NormalizedTimeTypes.jl/src/NormalizedTimeTypes.jl):\d+$"sm => s"\1 \2"
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> # From a Date, uses UTC by default

julia> norm = NormalizedTimeType(Date(2016, 10, 10))
NormalizedTimeType(tz"UTC", DateTime("2016-10-10T00:00:00"), ZonedDateTime(2016, 10, 10, tz"UTC"), 1476057600000)

julia> # From a ZonedDateTime

julia> norm = NormalizedTimeType(ZonedDateTime(2016, 10, 10, 12, 30, 0, tz"America/New_York"))
NormalizedTimeType(tz"America/New_York", DateTime("2016-10-10T16:30:00"), ZonedDateTime(2016, 10, 10, 12, 30, tz"America/New_York"), 1476117000000)

julia> # From a DateTime with legacy timezone as a string

julia> norm = NormalizedTimeType(DateTime(2016, 10, 10, 12, 30, 0), "EDT")  # Eastern Daylight Time
┌ Warning: Received an abbreviated TimeZone: EDT, using full timezone: America/New_York instead.
└ @ NormalizedTimeTypes /data/NormalizedTimeTypes.jl/src/NormalizedTimeTypes.jl:352
NormalizedTimeType(tz"America/New_York", DateTime("2016-10-10T16:30:00"), ZonedDateTime(2016, 10, 10, 12, 30, tz"America/New_York"), 1476117000000)

julia> # Prints a warning: "Received an abbreviated TimeZone: EDT, using full timezone: America/New_York instead."

julia> # From a string (format auto-detected)

julia> norm = NormalizedTimeType("2016-10-10T12:30:00")
NormalizedTimeType(tz"UTC", DateTime("2016-10-10T12:30:00"), ZonedDateTime(2016, 10, 10, 12, 30, tz"UTC"), 1476102600000)

julia> norm = NormalizedTimeType("2016-10-10T12:30:00-05:00")  # with timezone offset
NormalizedTimeType(tz"UTC-05:00", DateTime("2016-10-10T17:30:00"), ZonedDateTime(2016, 10, 10, 12, 30, tz"UTC-05:00"), 1476120600000)
```

### Accessing Time Values

Each `NormalizedTimeType` provides multiple views of the same instant:

```jldoctest; output=false
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> norm = NormalizedTimeType(DateTime(2016, 10, 10, 12, 30, 0), tz"America/New_York")
NormalizedTimeType(tz"America/New_York", DateTime("2016-10-10T16:30:00"), ZonedDateTime(2016, 10, 10, 12, 30, tz"America/New_York"), 1476117000000)

julia> # UTC DateTime

julia> norm.utc_datetime  # DateTime(2016, 10, 10, 16, 30, 0)
2016-10-10T16:30:00

julia> # Timezone-aware view

julia> norm.tz_datetime   # ZonedDateTime(2016, 10, 10, 12, 30, 0, America/New_York)
2016-10-10T12:30:00-04:00

julia> # Milliseconds since Unix Epoch

julia> norm.unix_ms       # Int64
1476117000000

julia> # Timezone info

julia> norm.timezone      # TimeZone("America/New_York")
America/New_York (UTC-5/UTC-4)
```

### Working with Multiple Timestamps

Normalize a collection of timestamps (possibly with different timezones):

```jldoctest; output=false
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> # Without explicit timezone (each retains its own)

julia> timestamps = NormalizedTimeTypes.normalizeTimestamps(
           DateTime(2016, 10, 10),
           ZonedDateTime(2016, 10, 12, tz"America/New_York"),
           Date(2015, 4, 3)
       )
3-element Vector{NormalizedTimeType}:
 NormalizedTimeType(tz"UTC", DateTime("2016-10-10T00:00:00"), ZonedDateTime(2016, 10, 10, tz"UTC"), 1476057600000)
 NormalizedTimeType(tz"America/New_York", DateTime("2016-10-12T04:00:00"), ZonedDateTime(2016, 10, 12, tz"America/New_York"), 1476244800000)
 NormalizedTimeType(tz"UTC", DateTime("2015-04-03T00:00:00"), ZonedDateTime(2015, 4, 3, tz"UTC"), 1428019200000)

julia> # With a default timezone for unaware inputs

julia> timestamps = NormalizedTimeTypes.normalizeTimestamps(
           tz"America/Los_Angeles",
           DateTime(2016, 10, 10),
           Date(2015, 4, 3)
       )
2-element Vector{NormalizedTimeType}:
 NormalizedTimeType(tz"America/Los_Angeles", DateTime("2016-10-10T07:00:00"), ZonedDateTime(2016, 10, 10, tz"America/Los_Angeles"), 1476082800000)
 NormalizedTimeType(tz"America/Los_Angeles", DateTime("2015-04-03T07:00:00"), ZonedDateTime(2015, 4, 3, tz"America/Los_Angeles"), 1428044400000)
```

### Arithmetic Operations

Add or subtract time periods:

```jldoctest; output=false
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> norm1 = NormalizedTimeType(DateTime(2016, 10, 10), "America/New_York")
NormalizedTimeType(tz"America/New_York", DateTime("2016-10-10T04:00:00"), ZonedDateTime(2016, 10, 10, tz"America/New_York"), 1476072000000)

julia> # Add/subtract Dates.Period or CompoundPeriod

julia> norm2 = norm1 + Dates.Month(1)           # One month later
NormalizedTimeType(tz"America/New_York", DateTime("2016-11-10T05:00:00"), ZonedDateTime(2016, 11, 10, tz"America/New_York"), 1478754000000)

julia> norm3 = norm1 - Dates.Week(2)            # Two weeks earlier
NormalizedTimeType(tz"America/New_York", DateTime("2016-09-26T04:00:00"), ZonedDateTime(2016, 9, 26, tz"America/New_York"), 1474862400000)

julia> norm4 = norm1 + (Dates.Day(1) - Dates.Hour(6))
NormalizedTimeType(tz"America/New_York", DateTime("2016-10-10T22:00:00"), ZonedDateTime(2016, 10, 10, 18, tz"America/New_York"), 1476136800000)

julia> # Difference between two NormalizedTimeType objects

julia> diff = norm4 - norm1            # Returns a Dates.Period
64800000 milliseconds
```

### Type Conversion

`NormalizedTimeType` can be used wherever `DateTime`, `ZonedDateTime`, or `Int64` are needed:

```jldoctest; output=false
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> norm = NormalizedTimeType(DateTime(2016, 10, 10, 12, 30, 0), "America/New_York")
NormalizedTimeType(tz"America/New_York", DateTime("2016-10-10T16:30:00"), ZonedDateTime(2016, 10, 10, 12, 30, tz"America/New_York"), 1476117000000)

julia> # Automatic conversion via Base.convert

julia> convert(DateTime, norm)         # UTC DateTime
2016-10-10T16:30:00

julia> convert(ZonedDateTime, norm)    # ZonedDateTime in original timezone
2016-10-10T12:30:00-04:00

julia> convert(Int64, norm)            # Milliseconds since Unix Epoch
1476117000000
```

## Supported Input Formats

The package handles a variety of string date/time formats with flexible parsing, including ISO 8601 variants, space-separated dates, timezone offsets in multiple formats, legacy timezone abbreviations, and more. See the [full API documentation](https://bluesmoon.github.io/NormalizedTimeTypes.jl/dev/) for complete details on supported formats.

## Key Features

### Lenient Parsing

The package resolves ambiguous inputs gracefully:
- Legacy timezone abbreviations (e.g., `EST`, `PST`) are mapped to their most common regions
- Missing timezone info defaults to UTC (unless you specify otherwise)
- Non-existent times during DST transitions are handled intelligently

### DST Awareness

Times that don't exist due to DST transitions (e.g., 2:00 AM during spring-forward) are automatically corrected to valid local times.

### Time Windows

Define time ranges using `TimeWindowType` or `NormalizedTimeWindowType`:

```julia
function accept_time_window(window::TimeWindowTypeUnion)
   (start_time, end_time) = window
   ...
end

accept_time_window(tuple(start_time, end_time))  # Tuple of two TimeType or NormalizedTimeType values
```
