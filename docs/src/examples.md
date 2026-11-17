# Examples

This page shows practical recipes for common use cases with NormalizedTimeTypes.jl.

## Basic Parsing and Creation

### Creating from Different Date/Time Types

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> # From a Date (defaults to UTC)
       norm = NormalizedTimeType(Date(2024, 11, 17))
NormalizedTimeType(tz"UTC", DateTime("2024-11-17T00:00:00"), ZonedDateTime(2024, 11, 17, tz"UTC"), 1731801600000)

julia> # From a DateTime (defaults to UTC)
       norm = NormalizedTimeType(DateTime(2024, 11, 17, 10, 30, 0))
NormalizedTimeType(tz"UTC", DateTime("2024-11-17T10:30:00"), ZonedDateTime(2024, 11, 17, 10, 30, tz"UTC"), 1731839400000)

julia> # From a ZonedDateTime
       zdt = ZonedDateTime(2024, 11, 17, 10, 30, 0, tz"America/New_York")
       norm = NormalizedTimeType(zdt)
NormalizedTimeType(tz"America/New_York", DateTime("2024-11-17T15:30:00"), ZonedDateTime(2024, 11, 17, 10, 30, tz"America/New_York"), 1731857400000)
```

### Parsing ISO 8601 Strings

ISO 8601 format is automatically detected with or without timezone information:

```jldoctest
julia> using NormalizedTimeTypes

julia> # Without timezone (defaults to UTC)
       norm = NormalizedTimeType("2024-11-17T10:30:00")
NormalizedTimeType(tz"UTC", Dates.DateTime("2024-11-17T10:30:00"), TimeZones.ZonedDateTime(2024, 11, 17, 10, 30, tz"UTC"), 1731839400000)

julia> # With timezone offset (+HH:MM format)
       norm = NormalizedTimeType("2024-11-17T10:30:00+05:30")
NormalizedTimeType(tz"UTC+05:30", Dates.DateTime("2024-11-17T05:00:00"), TimeZones.ZonedDateTime(2024, 11, 17, 10, 30, tz"UTC+05:30"), 1731819600000)

julia> # With timezone offset (-HH:MM format)
       norm = NormalizedTimeType("2024-11-17T10:30:00-05:00")
NormalizedTimeType(tz"UTC-05:00", Dates.DateTime("2024-11-17T15:30:00"), TimeZones.ZonedDateTime(2024, 11, 17, 10, 30, tz"UTC-05:00"), 1731857400000)

julia> # With milliseconds
       norm = NormalizedTimeType("2024-11-17T10:30:00.123")
NormalizedTimeType(tz"UTC", Dates.DateTime("2024-11-17T10:30:00.123"), TimeZones.ZonedDateTime(2024, 11, 17, 10, 30, 0, 123, tz"UTC"), 1731839400123)
```

### Parsing Space-Separated Dates

The library also supports space-separated date and time components:

```jldoctest
julia> using NormalizedTimeTypes

julia> # Space-separated with no timezone
       norm = NormalizedTimeType("2024-11-17 10:30:00")
NormalizedTimeType(tz"UTC", Dates.DateTime("2024-11-17T10:30:00"), TimeZones.ZonedDateTime(2024, 11, 17, 10, 30, tz"UTC"), 1731839400000)

julia> # Space-separated with offset
       norm = NormalizedTimeType("2024-11-17 10:30:00-0500")
NormalizedTimeType(tz"UTC-05:00", Dates.DateTime("2024-11-17T15:30:00"), TimeZones.ZonedDateTime(2024, 11, 17, 10, 30, tz"UTC-05:00"), 1731857400000)
```

## Working with Timezones

### Specifying Timezone for Naive Datetimes

When creating from a `DateTime` or `Date`, provide a timezone string or `TimeZone` object:

```jldoctest
julia> using NormalizedTimeTypes, TimeZones, Dates

julia> # With a TimeZone object
       dt = DateTime(2024, 11, 17, 10, 30, 0)
       norm = NormalizedTimeType(dt, tz"America/Los_Angeles")
NormalizedTimeType(tz"America/Los_Angeles", DateTime("2024-11-17T18:30:00"), ZonedDateTime(2024, 11, 17, 10, 30, tz"America/Los_Angeles"), 1731868200000)

julia> # With a timezone string
       norm = NormalizedTimeType(dt, "Europe/London")
NormalizedTimeType(tz"Europe/London", DateTime("2024-11-17T10:30:00"), ZonedDateTime(2024, 11, 17, 10, 30, tz"Europe/London"), 1731839400000)
```

### Using Legacy Timezone Abbreviations

The library recognizes common timezone abbreviations and maps them to full timezone names:

```jldoctest; filter = r"^(..@ NormalizedTimeTypes) [^\n]*(NormalizedTimeTypes.jl/src/NormalizedTimeTypes.jl):\d+$"sm => s"\1 \2"
julia> using NormalizedTimeTypes, Dates

julia> # EDT automatically resolves to America/New_York
       dt = DateTime(2024, 7, 17, 10, 30, 0)
       norm = NormalizedTimeType(dt, "EDT")
┌ Warning: Received an abbreviated TimeZone: EDT, using full timezone: America/New_York instead.
└ @ NormalizedTimeTypes /data/NormalizedTimeTypes.jl/src/NormalizedTimeTypes.jl:369
NormalizedTimeType(tz"America/New_York", DateTime("2024-07-17T14:30:00"), TimeZones.ZonedDateTime(2024, 7, 17, 10, 30, tz"America/New_York"), 1721226600000)

julia> # PST maps to America/Los_Angeles
       norm = NormalizedTimeType(DateTime(2024, 1, 15, 14, 0, 0), "PST")
┌ Warning: Received an abbreviated TimeZone: PST, using full timezone: America/Los_Angeles instead.
└ @ NormalizedTimeTypes /data/NormalizedTimeTypes.jl/src/NormalizedTimeTypes.jl:369
NormalizedTimeType(tz"America/Los_Angeles", DateTime("2024-01-15T22:00:00"), TimeZones.ZonedDateTime(2024, 1, 15, 14, tz"America/Los_Angeles"), 1705356000000)

julia> # Other common abbreviations work too
       norm = NormalizedTimeType(DateTime(2024, 11, 17, 10, 30, 0), "JST")
┌ Warning: Received an abbreviated TimeZone: JST, using full timezone: Asia/Tokyo instead.
└ @ NormalizedTimeTypes /data/NormalizedTimeTypes.jl/src/NormalizedTimeTypes.jl:369
NormalizedTimeType(tz"Asia/Tokyo", DateTime("2024-11-17T01:30:00"), TimeZones.ZonedDateTime(2024, 11, 17, 10, 30, tz"Asia/Tokyo"), 1731807000000)
```

### Handling DST Transitions

The library gracefully handles times that fall within DST transitions:

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> # Spring forward transition: 2:00 AM doesn't exist on 2024-03-10 in America/New_York
       # The library adjusts to a valid time
       norm = NormalizedTimeType(DateTime(2024, 3, 10, 2, 30, 0), tz"America/New_York")
NormalizedTimeType(tz"America/New_York", DateTime("2024-03-10T06:30:00"), ZonedDateTime(2024, 3, 10, 1, 30, tz"America/New_York"), 1710052200000)
```

## Accessing Time Values

Each `NormalizedTimeType` stores the same instant in multiple formats. Access the representation you need:

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> norm = NormalizedTimeType(DateTime(2024, 11, 17, 10, 30, 0), tz"America/New_York")
NormalizedTimeType(tz"America/New_York", DateTime("2024-11-17T15:30:00"), ZonedDateTime(2024, 11, 17, 10, 30, tz"America/New_York"), 1731857400000)

julia> # Get UTC DateTime
       norm.utc_datetime
2024-11-17T15:30:00

julia> # Get timezone-aware ZonedDateTime
       norm.tz_datetime
2024-11-17T10:30:00-05:00

julia> # Get Unix timestamp in milliseconds
       norm.unix_ms
1731857400000

julia> # Get the timezone
       norm.timezone
America/New_York (UTC-5/UTC-4)
```

### Converting to Standard Julia Types

`NormalizedTimeType` can be automatically converted to `DateTime`, `ZonedDateTime`, or `Int64`:

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> norm = NormalizedTimeType(DateTime(2024, 11, 17, 10, 30, 0), "America/Chicago")
NormalizedTimeType(tz"America/Chicago", DateTime("2024-11-17T16:30:00"), ZonedDateTime(2024, 11, 17, 10, 30, tz"America/Chicago"), 1731861000000)

julia> # Convert to DateTime (always UTC)
       dt = convert(DateTime, norm)
2024-11-17T16:30:00

julia> # Convert to ZonedDateTime (preserves timezone)
       zdt = convert(ZonedDateTime, norm)
2024-11-17T10:30:00-06:00

julia> # Convert to milliseconds since epoch
       ms = convert(Int64, norm)
1731861000000
```

### Using `datetime2unix_ms` for Unix Timestamps

Convert any `DateTime`, `ZonedDateTime`, or `NormalizedTimeType` to milliseconds since the Unix Epoch:

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> # From a NormalizedTimeType
       norm = NormalizedTimeType(DateTime(2024, 11, 17, 10, 30, 0), tz"America/New_York")
       datetime2unix_ms(norm)
1731857400000

julia> # From a DateTime (interpreted as UTC)
       dt = DateTime(2024, 11, 17, 15, 30, 0)
       datetime2unix_ms(dt)
1731857400000

julia> # From a ZonedDateTime (automatically converted to UTC)
       zdt = ZonedDateTime(2024, 11, 17, 10, 30, 0, tz"America/New_York")
       datetime2unix_ms(zdt)
1731857400000

julia> # All three representations of the same instant give the same result
       datetime2unix_ms(norm) == datetime2unix_ms(dt) == datetime2unix_ms(zdt)
true
```

## Arithmetic and Date Calculations

### Adding and Subtracting Time Periods

You can add or subtract any `Dates.Period` to/from a `NormalizedTimeType`:

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> norm = NormalizedTimeType(DateTime(2024, 11, 17), tz"America/New_York")
NormalizedTimeType(tz"America/New_York", DateTime("2024-11-17T05:00:00"), ZonedDateTime(2024, 11, 17, tz"America/New_York"), 1731819600000)

julia> # Add days
       norm + Dates.Day(5)
NormalizedTimeType(tz"America/New_York", DateTime("2024-11-22T05:00:00"), ZonedDateTime(2024, 11, 22, tz"America/New_York"), 1732251600000)

julia> # Subtract weeks
       norm - Dates.Week(2)
NormalizedTimeType(tz"America/New_York", DateTime("2024-11-03T04:00:00"), ZonedDateTime(2024, 11, 3, tz"America/New_York"), 1730606400000)

julia> # Add months
       norm + Dates.Month(3)
NormalizedTimeType(tz"America/New_York", DateTime("2025-02-17T05:00:00"), ZonedDateTime(2025, 2, 17, tz"America/New_York"), 1739768400000)

julia> # Combine multiple periods
       norm + Dates.Month(1) - Dates.Day(2) + Dates.Hour(6)
NormalizedTimeType(tz"America/New_York", DateTime("2024-12-15T11:00:00"), ZonedDateTime(2024, 12, 15, 6, tz"America/New_York"), 1734260400000)
```

### Computing Time Differences

Subtract two `NormalizedTimeType` objects to get the difference as a `Dates.Period`:

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> norm1 = NormalizedTimeType(DateTime(2024, 11, 17, 10, 0, 0), tz"America/New_York")
NormalizedTimeType(tz"America/New_York", DateTime("2024-11-17T15:00:00"), ZonedDateTime(2024, 11, 17, 10, tz"America/New_York"), 1731855600000)

julia> norm2 = NormalizedTimeType(DateTime(2024, 11, 17, 14, 30, 0), tz"America/New_York")
NormalizedTimeType(tz"America/New_York", DateTime("2024-11-17T19:30:00"), ZonedDateTime(2024, 11, 17, 14, 30, tz"America/New_York"), 1731871800000)

julia> # Difference in milliseconds
       diff = norm2 - norm1
16200000 milliseconds

julia> # Convert to seconds
       div(diff.value, 1000)
16200
```

## Working with Multiple Timestamps

### Normalize a Collection of Mixed Types

Convert multiple timestamps from different sources into a uniform format:

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> # Mix of different input types
       timestamps = NormalizedTimeTypes.normalizeTimestamps(
           DateTime(2024, 11, 17),
           ZonedDateTime(2024, 11, 18, tz"America/New_York"),
           Date(2024, 11, 19)
       )
3-element Vector{NormalizedTimeType}:
 NormalizedTimeType(tz"UTC", DateTime("2024-11-17T00:00:00"), ZonedDateTime(2024, 11, 17, tz"UTC"), 1731801600000)
 NormalizedTimeType(tz"America/New_York", DateTime("2024-11-18T05:00:00"), ZonedDateTime(2024, 11, 18, tz"America/New_York"), 1731906000000)
 NormalizedTimeType(tz"UTC", DateTime("2024-11-19T00:00:00"), ZonedDateTime(2024, 11, 19, tz"UTC"), 1731974400000)

julia> # With an explicit timezone applied to unaware inputs
       timestamps = NormalizedTimeTypes.normalizeTimestamps(
           tz"America/Los_Angeles",
           DateTime(2024, 11, 17),
           Date(2024, 11, 19)
       )
2-element Vector{NormalizedTimeType}:
 NormalizedTimeType(tz"America/Los_Angeles", DateTime("2024-11-17T08:00:00"), ZonedDateTime(2024, 11, 17, tz"America/Los_Angeles"), 1731830400000)
 NormalizedTimeType(tz"America/Los_Angeles", DateTime("2024-11-19T08:00:00"), ZonedDateTime(2024, 11, 19, tz"America/Los_Angeles"), 1732003200000)
```

## Common Patterns

### Validating and Normalizing User Input

When receiving timestamps from external sources (e.g., web APIs), normalize them to handle various formats:

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> # Simulating timestamps from different sources
       sources = [
           "2024-11-17T10:30:00",           # ISO 8601 from API A
           "2024-11-17 10:30:00-0500",       # Space-separated from API B
           DateTime(2024, 11, 17, 10, 30),   # DateTime from internal code
       ]
3-element Vector{Any}:
 "2024-11-17T10:30:00"
 "2024-11-17 10:30:00-0500"
 2024-11-17T10:30:00

julia> # Normalize all sources with a default timezone
       normalized = [NormalizedTimeType(s, tz"UTC") for s in sources]
3-element Vector{NormalizedTimeType}:
 NormalizedTimeType(tz"UTC", DateTime("2024-11-17T10:30:00"), ZonedDateTime(2024, 11, 17, 10, 30, tz"UTC"), 1731839400000)
 NormalizedTimeType(tz"UTC-05:00", DateTime("2024-11-17T15:30:00"), ZonedDateTime(2024, 11, 17, 10, 30, tz"UTC-05:00"), 1731857400000)
 NormalizedTimeType(tz"UTC", DateTime("2024-11-17T10:30:00"), ZonedDateTime(2024, 11, 17, 10, 30, tz"UTC"), 1731839400000)
```

### Working with Different Representations of the Same Instant

The same point in time can be represented in different ways. `NormalizedTimeType` maintains consistency:

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> # Three different ways to represent the same instant
       # 2024-11-17T10:30:00 in New York = 2024-11-17T15:30:00 UTC = 1731857400000 ms
       ny = NormalizedTimeType(DateTime(2024, 11, 17, 10, 30, 0), "America/New_York")
       utc = NormalizedTimeType("2024-11-17T15:30:00")
       offset = NormalizedTimeType("2024-11-17T10:30:00-05:00")
NormalizedTimeType(tz"UTC-05:00", DateTime("2024-11-17T15:30:00"), ZonedDateTime(2024, 11, 17, 10, 30, tz"UTC-05:00"), 1731857400000)

julia> # All have the same UTC datetime and unix_ms
       ny.utc_datetime == utc.utc_datetime == offset.utc_datetime
true

julia> ny.unix_ms == utc.unix_ms == offset.unix_ms
true

julia> # But different local representations
       ny.tz_datetime
2024-11-17T10:30:00-05:00

julia> utc.tz_datetime
2024-11-17T15:30:00+00:00
```

### Round-Trip Conversions

Convert to different formats and back while preserving the instant:

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> # Start with a datetime in a specific timezone
       original = NormalizedTimeType(DateTime(2024, 11, 17, 10, 30, 0), "America/Los_Angeles")
NormalizedTimeType(tz"America/Los_Angeles", DateTime("2024-11-17T18:30:00"), ZonedDateTime(2024, 11, 17, 10, 30, tz"America/Los_Angeles"), 1731868200000)

julia> # Convert to UTC datetime and back
       utc_dt = original.utc_datetime
       restored = NormalizedTimeType(utc_dt)  # Defaults to UTC
NormalizedTimeType(tz"UTC", DateTime("2024-11-17T18:30:00"), ZonedDateTime(2024, 11, 17, 18, 30, tz"UTC"), 1731868200000)

julia> # Same instant, different timezone representation
       original.unix_ms == restored.unix_ms
true
```

### Date Arithmetic Across Different Timezones

Arithmetic operations work consistently across timezones because they operate on the underlying instant in UTC:

```jldoctest
julia> using NormalizedTimeTypes, Dates

julia> # Same instant represented in two different timezones
       # 2024-11-17T15:30:00 UTC = 10:30 EST in New York = 21:00 IST in Kolkata
       ny = NormalizedTimeType("2024-11-17T10:30:00-05:00")
       kolkata = NormalizedTimeType("2024-11-17T21:00:00+05:30")
NormalizedTimeType(tz"UTC+05:30", DateTime("2024-11-17T15:30:00"), TimeZones.ZonedDateTime(2024, 11, 17, 21, tz"UTC+05:30"), 1731857400000)

julia> # Both represent the exact same instant
       ny.unix_ms == kolkata.unix_ms
true

julia> # Adding the same period to each preserves the relationship
       ny_plus_1day = ny + Dates.Day(1)
       kolkata_plus_1day = kolkata + Dates.Day(1)
NormalizedTimeType(tz"UTC+05:30", DateTime("2024-11-18T15:30:00"), TimeZones.ZonedDateTime(2024, 11, 18, 21, tz"UTC+05:30"), 1731943800000)

julia> # Still the same instant
       ny_plus_1day.unix_ms == kolkata_plus_1day.unix_ms
true

julia> # Computing differences between times in different timezones
       kolkata2 = NormalizedTimeType("2024-11-18T00:45:00+05:30")
       diff = kolkata2 - ny
13500000 milliseconds

julia> # Verify this is exactly 3 hours and 45 minutes
       diff == Dates.Hour(3) + Dates.Minute(45)
true
```

## Edge Cases

### Millisecond Precision

The library maintains millisecond precision for fractional seconds:

```jldoctest
julia> using NormalizedTimeTypes, Dates

julia> # With milliseconds
       norm1 = NormalizedTimeType("2024-11-17T10:30:00.123")
NormalizedTimeType(tz"UTC", DateTime("2024-11-17T10:30:00.123"), TimeZones.ZonedDateTime(2024, 11, 17, 10, 30, 0, 123, tz"UTC"), 1731839400123)

julia> norm2 = NormalizedTimeType("2024-11-17T10:30:00.456")
NormalizedTimeType(tz"UTC", DateTime("2024-11-17T10:30:00.456"), TimeZones.ZonedDateTime(2024, 11, 17, 10, 30, 0, 456, tz"UTC"), 1731839400456)

julia> # Can distinguish between nearby timestamps
       norm2.unix_ms - norm1.unix_ms
333
```

### Leap Seconds and Boundary Dates

The library handles boundary conditions gracefully:

```jldoctest
julia> using NormalizedTimeTypes, Dates, TimeZones

julia> # Year boundaries
       norm = NormalizedTimeType("2024-12-31T23:59:59")
NormalizedTimeType(tz"UTC", DateTime("2024-12-31T23:59:59"), ZonedDateTime(2024, 12, 31, 23, 59, 59, tz"UTC"), 1735689599000)

julia> # Next instant crosses year boundary
       next = norm + Dates.Second(1)
NormalizedTimeType(tz"UTC", DateTime("2025-01-01T00:00:00"), ZonedDateTime(2025, 1, 1, tz"UTC"), 1735689600000)
```
