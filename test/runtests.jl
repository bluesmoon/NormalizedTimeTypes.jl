using NormalizedTimeTypes
using Test, Dates, TimeZones

using NormalizedTimeTypes: expand_legacy_timezone, normalizeTimestamps

@testset "Legacy Time Zones" begin
    @test tz"UTC" == expand_legacy_timezone("")
    @test tz"America/New_York" == expand_legacy_timezone("America/New_York")
    @test tz"America/New_York" == (@test_logs (:warn, "Received an abbreviated TimeZone: EST, using full timezone: America/New_York instead.") expand_legacy_timezone("EST"))
    @test tz"UTC" == (@test_logs (:warn, "Received an unrecognized TimeZone: America/Old_York, falling back to UTC.") expand_legacy_timezone("America/Old_York"))
end


@testset "NormalizedTimeType" begin
    # NormalizedTimeType
    # 1. Simple Date object
    norm = NormalizedTimeType(Date(2016, 10, 10))
    @test norm.timezone     == TimeZone("UTC")
    @test norm.utc_datetime == DateTime(2016, 10, 10)
    @test norm.tz_datetime  == ZonedDateTime(2016, 10, 10, TimeZone("UTC"))
    @test norm.unix_ms      == 1476057600000

    # 2. Simple DateTime object
    norm = NormalizedTimeType(DateTime(2016, 10, 10, 12, 34, 56, 789))
    @test norm.timezone     == TimeZone("UTC")
    @test norm.utc_datetime == DateTime(2016, 10, 10, 12, 34, 56, 789)
    @test norm.tz_datetime  == ZonedDateTime(2016, 10, 10, 12, 34, 56, 789, TimeZone("UTC"))
    @test norm.unix_ms      == 1476102896789

    # 3. ZonedDateTime object
    norm = NormalizedTimeType(ZonedDateTime(2016, 10, 10, 12, 34, 56, 789, TimeZone("America/New_York")))
    @test norm.timezone     == TimeZone("America/New_York")
    @test norm.utc_datetime == DateTime(2016, 10, 10, 16, 34, 56, 789)
    @test norm.tz_datetime  == ZonedDateTime(2016, 10, 10, 12, 34, 56, 789, TimeZone("America/New_York"))
    @test norm.unix_ms      == 1476117296789

    # 4. DateTime & TimeZone
    norm = NormalizedTimeType(DateTime(2016, 10, 10, 12, 34, 56, 789), TimeZone("America/New_York"))
    @test norm.timezone     == TimeZone("America/New_York")
    @test norm.utc_datetime == DateTime(2016, 10, 10, 16, 34, 56, 789)
    @test norm.tz_datetime  == ZonedDateTime(2016, 10, 10, 12, 34, 56, 789, TimeZone("America/New_York"))
    @test norm.unix_ms      == 1476117296789

    # 4. DateTime & TimeZone String
    norm = NormalizedTimeType(DateTime(2016, 10, 10, 12, 34, 56, 789), "America/New_York")
    @test norm.timezone     == TimeZone("America/New_York")
    @test norm.utc_datetime == DateTime(2016, 10, 10, 16, 34, 56, 789)
    @test norm.tz_datetime  == ZonedDateTime(2016, 10, 10, 12, 34, 56, 789, TimeZone("America/New_York"))
    @test norm.unix_ms      == 1476117296789

    @test NormalizedTimeType(DateTime(2024, 4, 15)) == trunc(NormalizedTimeType(DateTime(2024, 4, 17)), Dates.Week)

    @test ZonedDateTime(2020, 3, 8, 1, tz"America/New_York") == NormalizedTimeType("2020-03-08T01:00:00", tz"America/New_York").tz_datetime
    @test ZonedDateTime(2020, 3, 8, 1, tz"America/New_York") == NormalizedTimeType("2020-03-08T01:00:00Z", tz"America/New_York").tz_datetime
    @test ZonedDateTime(2020, 3, 8, 1, tz"America/New_York") == NormalizedTimeType("2020-03-08T02:00:00", tz"America/New_York").tz_datetime
    @test ZonedDateTime(2020, 3, 8, 1, 10, tz"America/New_York") == NormalizedTimeType("2020-03-08T02:10:00", tz"America/New_York").tz_datetime
    @test ZonedDateTime(2020, 3, 8, 3, tz"America/New_York") == NormalizedTimeType("2020-03-08T03:00:00", tz"America/New_York").tz_datetime
    @test ZonedDateTime(2020, 3, 8, tz"America/New_York") == NormalizedTimeType(Date(2020, 3, 8), tz"America/New_York").tz_datetime
    @test ZonedDateTime(2020, 3, 8, 1, tz"Asia/Kolkata") == NormalizedTimeType("2020-03-08T01:00:00+0530", tz"America/Los_Angeles").tz_datetime
    @test ZonedDateTime(2020, 3, 8, 1, tz"Asia/Kathmandu") == NormalizedTimeType("2020-03-08T01:00:00+05:45", tz"America/Los_Angeles").tz_datetime
    @test ZonedDateTime(2016, 10, 10, 12, 30, 45, 123, tz"UTC+5") == NormalizedTimeType("2016-10-10T12:30:45.123+0500", tz"UTC").tz_datetime
    @test_throws ArgumentError("No match for FOOBAR, unable to parse into a NormalizedTimeType") NormalizedTimeType("FOOBAR", tz"America/New_York")


    # normalizeTimestamps
    # 1. Simple DateTime objects

    norms = normalizeTimestamps(DateTime(2016, 10, 10), DateTime(2016, 10, 12))

    @test length(norms) == 2
    @test norms[1].timezone     == TimeZone("UTC")
    @test norms[2].timezone     == TimeZone("UTC")
    @test norms[1].utc_datetime == DateTime(2016, 10, 10)
    @test norms[2].utc_datetime == DateTime(2016, 10, 12)
    @test norms[1].unix_ms      == 1476057600000
    @test norms[2].unix_ms      == 1476230400000

    # 2. ZonedDateTime

    norms = normalizeTimestamps(
        ZonedDateTime(2016, 10, 10, TimeZone("America/New_York")),
        ZonedDateTime(2016, 10, 12, TimeZone("America/New_York"))
    )

    @test length(norms) == 2
    @test norms[1].timezone     == TimeZone("America/New_York")
    @test norms[2].timezone     == TimeZone("America/New_York")
    @test norms[1].utc_datetime == DateTime(2016, 10, 10, 4)
    @test norms[2].utc_datetime == DateTime(2016, 10, 12, 4)
    @test norms[1].unix_ms      == 1476072000000
    @test norms[2].unix_ms      == 1476244800000


    # 3. Mixed

    norms = normalizeTimestamps(
        ZonedDateTime(2016, 10, 10, TimeZone("America/New_York")),
        ZonedDateTime(2016, 10, 12, TimeZone("America/Los_Angeles"))
    )

    @test length(norms) == 2
    @test norms[1].timezone     == TimeZone("America/New_York")
    @test norms[2].timezone     == TimeZone("America/Los_Angeles")
    @test norms[1].utc_datetime == DateTime(2016, 10, 10, 4)
    @test norms[2].utc_datetime == DateTime(2016, 10, 12, 7)
    @test norms[1].unix_ms      == 1476072000000
    @test norms[2].unix_ms      == 1476255600000


    # 4. DST Boundary outer

    norms = normalizeTimestamps(
        ZonedDateTime(2016, 11, 6, 0, TimeZone("America/New_York")),
        ZonedDateTime(2016, 11, 6, 3, TimeZone("America/New_York"))
    )

    @test length(norms) == 2
    @test norms[1].timezone     == TimeZone("America/New_York")
    @test norms[2].timezone     == TimeZone("America/New_York")
    @test norms[1].utc_datetime == DateTime(2016, 11, 6, 4)
    @test norms[2].utc_datetime == DateTime(2016, 11, 6, 8)
    @test norms[1].unix_ms      == 1478404800000
    @test norms[2].unix_ms      == 1478419200000

    # 5. DST Boundary inner

    norms = normalizeTimestamps(
        ZonedDateTime(2016, 11, 6, 1, 30, TimeZone("America/New_York"), true),                   # true  == Daylight Time
        ZonedDateTime(2016, 11, 6, 1, 30, TimeZone("America/New_York"), false)                   # false == Standard Time
    )

    @test length(norms) == 2
    @test norms[1].timezone     == TimeZone("America/New_York")
    @test norms[2].timezone     == TimeZone("America/New_York")
    @test norms[1].utc_datetime == DateTime(2016, 11, 6, 5, 30)
    @test norms[2].utc_datetime == DateTime(2016, 11, 6, 6, 30)
    @test norms[1].unix_ms      == 1478410200000
    @test norms[2].unix_ms      == 1478413800000


    # 6. Mixed types
    norms = normalizeTimestamps(
        DateTime(2016, 10, 10, 1, 2, 3),
        ZonedDateTime(2016, 10, 10, TimeZone("America/New_York")),
        Date(2015, 4, 3)
    )

    @test length(norms) == 3
    @test norms[1].timezone     == TimeZone("UTC")
    @test norms[2].timezone     == TimeZone("America/New_York")
    @test norms[3].timezone     == TimeZone("UTC")
    @test norms[1].utc_datetime == DateTime(2016, 10, 10, 1, 2, 3)
    @test norms[2].utc_datetime == DateTime(2016, 10, 10, 4, 0, 0)
    @test norms[3].utc_datetime == DateTime(2015, 4, 3, 0, 0, 0)
    @test norms[1].unix_ms      == 1476061323000
    @test norms[2].unix_ms      == 1476072000000
    @test norms[3].unix_ms      == 1428019200000

    # 7. Pass in an array
    dts = Dates.TimeType[
        DateTime(2016, 10, 10, 1, 2, 3),
        ZonedDateTime(2016, 10, 10, TimeZone("America/New_York")),
        Date(2015, 4, 3)
    ]
    norms = normalizeTimestamps(dts...)

    @test length(norms) == 3
    @test norms[1].timezone     == TimeZone("UTC")
    @test norms[2].timezone     == TimeZone("America/New_York")
    @test norms[3].timezone     == TimeZone("UTC")
    @test norms[1].utc_datetime == DateTime(2016, 10, 10, 1, 2, 3)
    @test norms[2].utc_datetime == DateTime(2016, 10, 10, 4, 0, 0)
    @test norms[3].utc_datetime == DateTime(2015, 4, 3, 0, 0, 0)
    @test norms[1].unix_ms      == 1476061323000
    @test norms[2].unix_ms      == 1476072000000
    @test norms[3].unix_ms      == 1428019200000

    # 8. Pass in an array and timezone
    dts = Dates.TimeType[
        DateTime(2016, 10, 10, 1, 2, 3),
        ZonedDateTime(2016, 10, 10, TimeZone("America/New_York")),
        Date(2015, 4, 3)
    ]
    norms = normalizeTimestamps("America/Los_Angeles", dts...)

    @test length(norms) == 3
    @test norms[1].timezone     == TimeZone("America/Los_Angeles")
    @test norms[2].timezone     == TimeZone("America/New_York")
    @test norms[3].timezone     == TimeZone("America/Los_Angeles")
    @test norms[1].utc_datetime == DateTime(2016, 10, 10, 8, 2, 3)
    @test norms[2].utc_datetime == DateTime(2016, 10, 10, 4, 0, 0)
    @test norms[3].utc_datetime == DateTime(2015, 4, 3, 7, 0, 0)
    @test norms[1].unix_ms      == 1476086523000
    @test norms[2].unix_ms      == 1476072000000
    @test norms[3].unix_ms      == 1428044400000

    norm1 = NormalizedTimeType(norms[1], "abc", "def") # test that extra args are ignored
    @test norm1 == norms[1]

    # 9. Add/subtract Dates.Period
    norm1 = NormalizedTimeType(DateTime(2016, 10, 10, 12, 34, 56, 789), TimeZone("America/New_York"))
    # 9.1. DatePeriod Month
    norm2 = norm1 + Dates.Month(1)
    @test norm2.timezone     == TimeZone("America/New_York")
    @test norm2.utc_datetime == DateTime(2016, 11, 10, 17, 34, 56, 789) # DST boundary switch so 16 becomes 17
    @test norm2.tz_datetime  == ZonedDateTime(2016, 11, 10, 12, 34, 56, 789, TimeZone("America/New_York"))
    @test norm2.unix_ms      == 1478799296789

    # 9.2. DatePeriod Week
    norm2 = norm1 - Dates.Week(1)
    @test norm2.timezone     == TimeZone("America/New_York")
    @test norm2.utc_datetime == DateTime(2016, 10, 03, 16, 34, 56, 789)
    @test norm2.tz_datetime  == ZonedDateTime(2016, 10, 03, 12, 34, 56, 789, TimeZone("America/New_York"))
    @test norm2.unix_ms      == 1475512496789

    # 9.3. TimePeriod
    norm2 = norm1 + Dates.Hour(2)
    @test norm2.timezone     == TimeZone("America/New_York")
    @test norm2.utc_datetime == DateTime(2016, 10, 10, 18, 34, 56, 789)
    @test norm2.tz_datetime  == ZonedDateTime(2016, 10, 10, 14, 34, 56, 789, TimeZone("America/New_York"))
    @test norm2.unix_ms      == 1476124496789

    # 9.4. CompoundPeriod
    # We enclose the periods in parentheses to make it a CompoundPeriod, else left associativity of + & - will result in `norm1 + Dates.Hour(2)` being evaluated first
    norm2 = norm1 + (Dates.Hour(2) - Dates.Week(1))
    @test norm2 < norm1
    @test norm2.timezone     == TimeZone("America/New_York")
    @test norm2.utc_datetime == DateTime(2016, 10, 3, 18, 34, 56, 789)
    @test norm2.tz_datetime  == ZonedDateTime(2016, 10, 3, 14, 34, 56, 789, TimeZone("America/New_York"))
    @test norm2.unix_ms      == 1475519696789

    # 9.5. Difference between two NormalizedTimeType objects
    diff = norm1 - norm2
    @test diff == Dates.Week(1) - Dates.Hour(2)

    # 10. Converters
    @test convert(DateTime, norm1)      == DateTime(2016, 10, 10, 16, 34, 56, 789)
    @test convert(ZonedDateTime, norm1) == ZonedDateTime(2016, 10, 10, 12, 34, 56, 789, TimeZone("America/New_York"))
    @test convert(Int64, norm1)         == 1476117296789
end
