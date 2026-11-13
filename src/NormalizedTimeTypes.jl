module NormalizedTimeTypes

using Dates
using TimeZones

export NormalizedTimeType, TimeWindowType, NormalizedTimeWindowType, TimeWindowTypeUnion

"""
Ordered list of `(Regex, DateFormat)` pairs for parsing timezone-naïve date/time
strings.

Each entry matches a specific string pattern and provides the corresponding
`Dates.DateFormat` to parse it into a `DateTime`. Patterns are tried in order; the
first match wins.

Supported formats:
- `yyyy-mm-dd HH:MM:SS[.sss]`   — space separator, optional milliseconds
- `yyyy-mm-ddTHH:MM:SS[.sss]`   — ISO 8601 T separator, optional milliseconds
- `yyyy-mm-ddTHH:MM:SS[.sss]+`  — trailing `+` sentinel (offset stripped by caller)
- `yyyy-mm-ddTHH:MM:SS[.sss]-`  — trailing `-` sentinel (offset stripped by caller)

Used by [`NormalizedTimeType`](@ref) for strings without a numeric timezone offset.
For timezone-aware strings see [`DATE_FORMATS_TZ`](@ref).
"""
const DATE_FORMATS = [
    (r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(?:\.\d{0,3})?$", Dates.DateFormat("y-m-d H:M:S.s")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{0,3})?$", Dates.DateFormat("y-m-dTH:M:S.s")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{1,3}\+$"   , Dates.DateFormat("y-m-dTH:M:S.s+")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{1,3}\-$"   , Dates.DateFormat("y-m-dTH:M:S.s-")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+$"            , Dates.DateFormat("y-m-dTH:M:S+")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\-$"            , Dates.DateFormat("y-m-dTH:M:S-")),
]


"""
Ordered list of `(Regex, DateFormat)` pairs for parsing date/time strings that embed
a numeric timezone offset.

Each entry matches a specific timezone-aware pattern and provides the corresponding
`Dates.DateFormat` to parse it into a `ZonedDateTime`. Patterns are tried in order;
the first match wins.

Supported offset formats (combined with both T-separator and space-separator date-time):
- `±HHMM`   — compact offset, e.g. `+0400`
- `±HH:MM`  — colon-separated offset, e.g. `-05:30`
- ` HHMM`   — space-separated offset, e.g. ` 0400`

Milliseconds are optional in all patterns.

Used by [`NormalizedTimeType`](@ref) for timezone-aware strings.
For timezone-naïve strings see [`DATE_FORMATS`](@ref).
"""
const DATE_FORMATS_TZ = [
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{1}[+-]\d{2}:?\d{2}$", Dates.DateFormat("y-m-dTH:M:S.sz")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{2}[+-]\d{2}:?\d{2}$", Dates.DateFormat("y-m-dTH:M:S.ssz")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{2}:?\d{2}$", Dates.DateFormat("y-m-dTH:M:S.sssz")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{1} \d{4}$"          , Dates.DateFormat("y-m-dTH:M:S.s z")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{2} \d{4}$"          , Dates.DateFormat("y-m-dTH:M:S.ss z")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3} \d{4}$"          , Dates.DateFormat("y-m-dTH:M:S.sss z")),
    (r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{1} \d{4}$"          , Dates.DateFormat("y-m-d H:M:S.s z")),
    (r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{2} \d{4}$"          , Dates.DateFormat("y-m-d H:M:S.ss z")),
    (r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3} \d{4}$"          , Dates.DateFormat("y-m-d H:M:S.sss z")),
    (r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{1}[+-]\d{4}$"       , Dates.DateFormat("y-m-d H:M:S.sz")),
    (r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{2}[+-]\d{4}$"       , Dates.DateFormat("y-m-d H:M:S.ssz")),
    (r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}[+-]\d{4}$"       , Dates.DateFormat("y-m-d H:M:S.sssz")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:?\d{2}$"       , Dates.DateFormat("y-m-dTH:M:SSz")),
    (r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}[+-]\d{2}:?\d{2}$"       , Dates.DateFormat("y-m-d H:M:SSz")),
    (r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} \d{4}$"                 , Dates.DateFormat("y-m-dTH:M:SS z")),
    (r"^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \d{4}$"                 , Dates.DateFormat("y-m-d H:M:SS z")),
]

"""
Internal dictionary of common legacy timezone abbreviations to their full TimeZone names.

We use this dictionary because timezones_from_abbr returns multiple results that all
match the offset of the common abbreviation. Rather than pick a random one, we use the
most likely candidate based on colloquial usage. For example, "EST" is used in multiple
timezones, but the most common usage is "America/New_York".  This dictionary is used to
disambiguate these cases.

Used by [`expand_legacy_timezone`](@ref).
"""
const COMMON_TZ_ABBRS = Dict(
    "EST" => tz"America/New_York",
    "EDT" => tz"America/New_York",
    "CST" => tz"America/Chicago",
    "CDT" => tz"America/Chicago",
    "MST" => tz"America/Denver",
    "MDT" => tz"America/Denver",
    "PST" => tz"America/Los_Angeles",
    "PDT" => tz"America/Los_Angeles",
    "GMT" => tz"Europe/London",
    "BST" => tz"Europe/London",
    "CET" => tz"Europe/Paris",
    "CEST" => tz"Europe/Paris",
    "EET" => tz"Europe/Helsinki",
    "EEST" => tz"Europe/Helsinki",
    "JST" => tz"Asia/Tokyo",
    "AEST" => tz"Australia/Sydney",
    "AEDT" => tz"Australia/Sydney",
    "ACST" => tz"Australia/Adelaide",
    "ACDT" => tz"Australia/Adelaide",
    "AWST" => tz"Australia/Perth",
    "IST" => tz"Asia/Kolkata",
    "KST" => tz"Asia/Seoul",
    "MSK" => tz"Europe/Moscow",
    "NZST" => tz"Pacific/Auckland",
    "NZDT" => tz"Pacific/Auckland",
    "HST" => tz"Pacific/Honolulu",
    "AKST" => tz"America/Anchorage",
    "AKDT" => tz"America/Anchorage",
    "AST" => tz"America/Halifax",
    "ADT" => tz"America/Halifax",
    "WET" => tz"Europe/Lisbon",
    "WEST" => tz"Europe/Lisbon",
    "ART" => tz"America/Argentina/Buenos_Aires",
    "BRT" => tz"America/Sao_Paulo",
    "CLT" => tz"America/Santiago",
    "CLST" => tz"America/Santiago",
    "EAT" => tz"Africa/Nairobi",
    "SAST" => tz"Africa/Johannesburg",
    "WAT" => tz"Africa/Lagos",
    "WAST" => tz"Africa/Windhoek",
    "AST" => tz"America/Caracas",
    "ADT" => tz"America/Caracas",
    "COT" => tz"America/Bogota",
    "PET" => tz"America/Lima",
    "VET" => tz"America/Caracas"
)


"""
A container type for various views of a given `TimeType` which, via converters.

* `struct NormalizedTimeType`

#### Fields

`timezone::TimeZone`
: The `TimeZone` of the contained `TimeType`.

`utc_datetime::DateTime`
: The `UTC` converted representation of the contained `TimeType`.

`tz_datetime::ZonedDateTime`
: A `ZonedDateTime` representing the contained `TimeType` and its `TimeZone`

`unix_ms::Int64`
: The contained `TimeType` represented as milliseconds since the Unix Epoch of
  1970-01-01T00:00:00.000Z

#### Constructors

`NormalizedTimeType(::TimeType)`
: Constructs a `NormalizedTimeType` from a `TimeType`. The passed in `TimeType`
  may be a `Date`, a `DateTime`, a `ZonedDateTime`, or any other subtype of `TimeType`

`NormalizedTimeType(::TimeType, ::TimeZone|AbstractString)`
: Constructs a `NormalizedTimeType` from a `DateTime` with an associated `TimeZone`.
  The second parameter may either be a `TimeZone` object or a string TimeZone name.

`NormalizedTimeType(::NormalizedTimeType, ...)`
: Constructs a `NormalizedTimeType` from another `NormalizedTimeType`.  This is useful
  for converting a `NormalizedTimeType` to a different timezone.

`NormalizedTimeType(::AbstractString, ::TimeZone|AbstractString="")`
: Constructs a `NormalizedTimeType` from a string representation of a date/time with an
  associated `TimeZone`. The second parameter may be excluded if the string representation
  includes a timezone, or it may be a `VariableTimeZone` to use instead of a `FixedTimeZone`
  parsed from the string.

Will check [`DATE_FORMATS`](@ref) and [`DATE_FORMATS_TZ`](@ref) for a suitable parser.

If the object represents a timestamp that falls within a DST transition period of the
specified timezone, then this function will attempt to determine the most appropriate
value by checking the delta with the DST transition, applying that to the UTC equivalent,
and then converting.

#### Converters

`NormalizedTimeType` has converters for `DateTime`, `ZonedDateTime`, and `Int64`, so it
may be used wherever one of these three types is required.

#### Operators

You may also add and subtract any `Dates.Period` or `Dates.CompoundPeriod` to/from a
`NormalizedTimeType` object to get a new `NormalizedTimeType` object.

For example:

```julia
julia> t1 = NormalizedTimeType(Date(2016, 10, 10))
NormalizedTimeType(UTC,2016-10-10T00:00:00,2016-10-10T00:00:00+00:00,1476057600000)

julia> t1 + Dates.Month(1) - Dates.Day(2)
NormalizedTimeType(UTC,2016-11-08T00:00:00,2016-11-08T00:00:00+00:00,1478563200000)

julia> t1 - Dates.Month(1) + Dates.Week(1)
NormalizedTimeType(UTC,2016-09-17T00:00:00,2016-09-17T00:00:00+00:00,1474070400000)
```


#### Examples
```julia
julia> NormalizedTimeType(Date(2016, 10, 10))
NormalizedTimeType(UTC,2016-10-10T00:00:00,2016-10-10T00:00:00+00:00,1476057600000)
```

```julia
julia> NormalizedTimeType(DateTime(2016, 10, 10, 1, 2, 3))
NormalizedTimeType(UTC,2016-10-10T01:02:03,2016-10-10T01:02:03+00:00,1476061323000)
```

```julia
julia> NormalizedTimeType(ZonedDateTime(DateTime(2016, 10, 10, 1, 2, 3), tz"America/New_York"))
NormalizedTimeType(America/New_York (UTC-5/UTC-4),2016-10-10T05:02:03,2016-10-10T05:02:03-04:00,1476075723000)
```

```julia
julia> NormalizedTimeType(DateTime(2016, 10, 10, 1, 2, 3), tz"America/New_York")
NormalizedTimeType(America/New_York (UTC-5/UTC-4),2016-10-10T05:02:03,2016-10-10T05:02:03-04:00,1476075723000)
```

```julia
julia> NormalizedTimeType(DateTime(2016, 10, 10, 1, 2, 3), "America/New_York")
NormalizedTimeType(America/New_York (UTC-5/UTC-4),2016-10-10T05:02:03,2016-10-10T05:02:03-04:00,1476075723000)
```

#### See also
[`NormalizedTimeTypes.normalizeTimestamps`](@ref)
"""
struct NormalizedTimeType
    timezone     :: TimeZone
    utc_datetime :: DateTime
    tz_datetime  :: ZonedDateTime
    unix_ms      :: Int64

    # We include the tz parameter because a caller might pass it and we do not want
    # that to fall back to the TimeType method.
    function NormalizedTimeType(t::ZonedDateTime, tz::TimeZone=tz"UTC")
        return new(t.timezone, t.utc_datetime, t, round(Int64, datetime2unix(t.utc_datetime) * 1000))
    end

    # Method for TimeTypes that are not ZonedDateTime. This function checks for ambiguity
    # and non-existent times in the given timezone.
    function NormalizedTimeType(t::TimeType, tz::TimeZone=tz"UTC")
        if tz isa FixedTimeZone
           zdt = ZonedDateTime(DateTime(t), tz)
        else
            zdt = try
                ZonedDateTime(DateTime(t), tz, 1)
            catch ex
                !isa(ex, NonExistentTimeError) && rethrow()

                # NonExistentTimeError happens when as a result of truncation and rounding
                # we end up with a date that doesn't exist
                # in a particular timezone.  eg: 2020-03-08T02:00:00 in tz"America/New_York"
                # (since we go from 01:59:59 EST to 03:00:00 EDT)
                #
                # What we do is, check how far off this is from the nearest DST transition,
                # we then subtract that value from the UTC representation of the DST transition
                # to get the UTC representation of our intended time. We can then convert this
                # to local time and come up with a reasonable value
                local undef, mindex = findmin(
                        [
                            abs(t.utc_datetime + t.zone.offset.std + t.zone.offset.dst - ex.local_dt)
                            for t in ex.timezone.transitions
                        ]
                    )
                local t = ex.timezone.transitions[mindex]

                astimezone(
                    ZonedDateTime(ex.local_dt - t.zone.offset.std - t.zone.offset.dst, tz"UTC"),
                    ex.timezone
                )
            end
        end

        return NormalizedTimeType(zdt)
    end

    function NormalizedTimeType(t::TimeType, tz::AbstractString)
        # Avoid parsing if we already have a ZonedDateTime
        t isa ZonedDateTime && return NormalizedTimeType(t)

        tz = try
            TimeZone(tz)
        catch ex
            !isa(ex, ArgumentError) && rethrow()
            # If the timezone is not recognized, try to expand it from a legacy abbreviation
            expand_legacy_timezone(tz)
        end
        return NormalizedTimeType(t, tz)
    end

    NormalizedTimeType(t::NormalizedTimeType, x...) = t

    function NormalizedTimeType(d::AbstractString, tz::Union{TimeZone, AbstractString}=tz"UTC")
        orig_d = d
        # Check if the caller appends Z to Date object
        if occursin("Z", d)
            d = replace(d, "Z" => "")
        end

        # Check if it's in a known format without a timezone
        for (re, fmt) in DATE_FORMATS
            if occursin(re, d)
                return NormalizedTimeType(DateTime(d, fmt), tz)
            end
        end

        # Check if it's in a known format with a timezone
        for (re, fmt) in DATE_FORMATS_TZ
            if occursin(re, d)
                return NormalizedTimeType(ZonedDateTime(d, fmt))
            end
        end

        throw(ArgumentError("No match for $orig_d, unable to parse into a NormalizedTimeType"))
    end
end

import Base: +, -, ==

Base.convert(::Type{DateTime}, x::NormalizedTimeType) = x.utc_datetime
Base.convert(::Type{ZonedDateTime}, x::NormalizedTimeType) = x.tz_datetime
Base.convert(::Type{Int64}, x::NormalizedTimeType) = x.unix_ms

-(ntt::NormalizedTimeType, p::Union{Dates.CompoundPeriod, Dates.Period}) = NormalizedTimeType(ntt.tz_datetime - p)
+(ntt::NormalizedTimeType, p::Union{Dates.CompoundPeriod, Dates.Period}) = NormalizedTimeType(ntt.tz_datetime + p)
-(t1::NormalizedTimeType, t2::NormalizedTimeType) = t1.utc_datetime - t2.utc_datetime
==(x::NormalizedTimeType, y::NormalizedTimeType) = x.unix_ms == y.unix_ms && x.timezone == y.timezone
Base.isless(x::NormalizedTimeType, y::NormalizedTimeType) = isless(x.unix_ms, y.unix_ms)

### Add `trunc`, `floor` and `ceil` for NormalizedTimeType
Base.trunc(dt::NormalizedTimeType, p::Type{<:Dates.Period}) = NormalizedTimeType(floor(dt.tz_datetime, p))
Base.floor(dt::NormalizedTimeType, p::Type{<:Dates.Period}) = NormalizedTimeType(floor(dt.tz_datetime, p))
Base.ceil(dt::NormalizedTimeType, p::Type{<:Dates.Period})  = NormalizedTimeType(ceil(dt.tz_datetime, p))

Dates.datetime2unix(n::NormalizedTimeType) = n.unix_ms / 1000


"""
Convert a legacy TimeZone abbreviation to a full TimeZone name. Returns UTC for
unrecognized abbreviations.
"""
function expand_legacy_timezone(tz_str::AbstractString)
    if isempty(tz_str)
        tz_str = tz"UTC"
    elseif tz_str ∈ timezone_abbrs()
        old_str = tz_str
        tz_str = get(
                    COMMON_TZ_ABBRS,
                    tz_str,
                    timezones_from_abbr(tz_str)[ceil(Int, end/2)]
                )
        if tz_str.name != old_str
            @warn("Received an abbreviated TimeZone: $old_str, using full timezone: $tz_str instead.")
        end
    elseif tz_str ∉ timezone_names()
        @warn("Received an unrecognized TimeZone: $tz_str, falling back to UTC.")
        tz_str = tz"UTC"
    end

    return tz_str isa TimeZone ? tz_str : TimeZone(tz_str, TimeZones.Class(:ALL))
end


"""
Normalize multiple `TimeType`s to `NormalizedTimeType`s

* `normalizeTimestamps(t...) → NormalizedTimeType[...]`
* `normalizeTimestamps(tz, t...) → NormalizedTimeType[...]`

`TimeType` is the common supertype for `DateTime`, `Date`, `ZonedDateTime` and others.

#### Arguments
`tz::AbstractString|TimeZone`
: [optional] The common timezone to use for all `t`s that don't have their own TimeZone

`t::TimeType...`
: The time values to normalize.

#### Returns
An array of [`NormalizedTimeType`](@ref)

#### Example

```julia
julia> norms = TimeUtilities.normalizeTimestamps(
           DateTime(2016, 10, 10, 1, 2, 3),
           ZonedDateTime(DateTime(2016, 10, 10), TimeZone("America/New_York")),
           Date(2015, 4, 3)
       )
3-element Array{TimeUtilities.NormalizedTimeType,1}:
 TimeUtilities.NormalizedTimeType(UTC,2016-10-10T01:02:03,2016-10-10T01:02:03+00:00,1476061323000)
 TimeUtilities.NormalizedTimeType(America/New_York (UTC-5/UTC-4),2016-10-10T04:00:00,2016-10-10T04:00:00-04:00,1476072000000)
 TimeUtilities.NormalizedTimeType(UTC,2015-04-03T00:00:00,2015-04-03T00:00:00+00:00,1428019200000)
```

```julia
julia> norms = TimeUtilities.normalizeTimestamps("America/New_York", DateTime(2016, 10, 10, 1, 2, 3), Date(2015, 4, 3))
2-element Array{TimeUtilities.NormalizedTimeType,1}:
 TimeUtilities.NormalizedTimeType(America/New_York (UTC-5/UTC-4),2016-10-10T05:02:03,2016-10-10T01:02:03-04:00,1476075723000)
 TimeUtilities.NormalizedTimeType(America/New_York (UTC-5/UTC-4),2015-04-03T04:00:00,2015-04-03T00:00:00-04:00,1428033600000)
```
"""
normalizeTimestamps(t::Union{NormalizedTimeType,TimeType}...) = NormalizedTimeType[NormalizedTimeType(x) for x in t]
normalizeTimestamps(tz::Union{TimeZone, AbstractString}, t::Union{NormalizedTimeType,TimeType}...) = NormalizedTimeType[NormalizedTimeType(x, tz) for x in t]



"""
A convenience type for representing a time window as a tuple of two `TimeType`s. The first
element is the start of the window, and the second element is the end of the window.

Functions that accept this type decide if the window is open or closed.
"""
const TimeWindowType = Tuple{<:TimeType, <:TimeType}

"""
A convenience type for representing a time window as a tuple of two `NormalizedTimeType`s.
The first element is the start of the window, and the second element is the end of the window.

Functions that accept this type decide if the window is open or closed.
"""
const NormalizedTimeWindowType = Tuple{NormalizedTimeType, NormalizedTimeType}

"""
A convenience type for representing a time window as a tuple of two `TimeType`s or two
`NormalizedTimeType`s. The first element is the start of the window, and the second element
is the end of the window.

Functions that accept this type decide if the window is open or closed.
"""
const TimeWindowTypeUnion = Union{TimeWindowType, NormalizedTimeWindowType}

end
