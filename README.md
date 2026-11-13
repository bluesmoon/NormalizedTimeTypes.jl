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

### Basic Usage

```julia
using NormalizedTimeTypes

# From a Date, uses UTC by default
norm = NormalizedTimeType(Date(2016, 10, 10))

# From a ZonedDateTime
norm = NormalizedTimeType(ZonedDateTime(2016, 10, 10, 12, 30, 0, tz"America/New_York"))

# From a DateTime with legacy timezone as a string
norm = NormalizedTimeType(DateTime(2016, 10, 10, 12, 30, 0), "EDT")  # Eastern Daylight Time
# Prints a warning: "Received an abbreviated TimeZone: EDT, using full timezone: America/New_York instead."

# From a string (format auto-detected)
norm = NormalizedTimeType("2016-10-10T12:30:00")
norm = NormalizedTimeType("2016-10-10T12:30:00-05:00")  # with timezone offset
```

### Accessing Time Values

Each `NormalizedTimeType` provides multiple views of the same instant:

```julia
norm = NormalizedTimeType(DateTime(2016, 10, 10, 12, 30, 0), tz"America/New_York")

# UTC DateTime
norm.utc_datetime  # DateTime(2016, 10, 10, 16, 30, 0)

# Timezone-aware view
norm.tz_datetime   # ZonedDateTime(2016, 10, 10, 12, 30, 0, America/New_York)

# Milliseconds since Unix Epoch
norm.unix_ms       # Int64

# Timezone info
norm.timezone      # TimeZone("America/New_York")
```

### Working with Multiple Timestamps

Normalize a collection of timestamps (possibly with different timezones):

```julia
using Dates, TimeZones

# Without explicit timezone (each retains its own)
timestamps = NormalizedTimeTypes.normalizeTimestamps(
    DateTime(2016, 10, 10),
    ZonedDateTime(2016, 10, 12, tz"America/New_York"),
    Date(2015, 4, 3)
)

# With a default timezone for unaware inputs
timestamps = NormalizedTimeTypes.normalizeTimestamps(
    tz"America/Los_Angeles",
    DateTime(2016, 10, 10),
    Date(2015, 4, 3)
)
```

### Arithmetic Operations

Add or subtract time periods:

```julia
norm1 = NormalizedTimeType(DateTime(2016, 10, 10), "America/New_York")

# Add/subtract Dates.Period or CompoundPeriod
norm2 = norm1 + Dates.Month(1)           # One month later
norm3 = norm1 - Dates.Week(2)            # Two weeks earlier
norm4 = norm1 + (Dates.Day(1) - Dates.Hour(6))

# Difference between two NormalizedTimeType objects
diff = norm4 - norm1            # Returns a Dates.Period
```

### Type Conversion

`NormalizedTimeType` can be used wherever `DateTime`, `ZonedDateTime`, or `Int64` are needed:

```julia
norm = NormalizedTimeType(DateTime(2016, 10, 10, 12, 30, 0), "America/New_York")

# Automatic conversion via Base.convert
convert(DateTime, norm)         # UTC DateTime
convert(ZonedDateTime, norm)    # ZonedDateTime in original timezone
convert(Int64, norm)            # Milliseconds since Unix Epoch
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
