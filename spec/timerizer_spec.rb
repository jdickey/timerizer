require "spec_helper"

RSpec.describe Timerizer::Duration do
  context "given an existing time" do
    before :all do
      @time = Time.new(2000, 1, 1, 3, 45, 00)
      @end_of_march = Time.new(2000, 3, 31, 3, 45, 00)
      @end_of_january = Time.new(2000, 1, 31, 3, 45, 00)
    end

    it "calculates a new time before itself" do
      expect(5.minutes.before(@time)).to eq(Time.new(2000, 1, 1, 3, 40, 00))
      expect(5.months.before(@time)).to eq(Time.new(1999, 8, 1, 3, 45, 00))
      expect(65.months.before(@time)).to eq(Time.new(1994, 8, 1, 3, 45, 00))

      expect(
        (60.minutes 12.months).before(@time)
      ).to eq(Time.new(1999, 1, 1, 2, 45, 00))

      expect(
        1.month.before(@end_of_march)
      ).to eq(Time.new(2000, 2, 29, 3, 45, 00))

      expect(
        (1.year 1.month 1.week 1.day 1.hour 1.minute 1.second).before(@time)
        # 2000, 1, 1, 3, 45, 00
        # 1999, 1, 1, 3, 45, 00
        # 1998, 12, 1, 3, 45, 00
        # 1998, 11, 25, 3, 45, 00
        # 1998, 11, 24, 3, 45, 00
        # 1998, 11, 24, 2, 45, 00
        # 1998, 11, 24, 2, 44, 00
        # 1998, 11, 24, 2, 43, 59
      ).to eq(Time.new(1998, 11, 23, 2, 43, 59))

      expect(
        (1.year 1.month 1.week 1.day 1.hour 1.minute 1.second)
          .before(@end_of_march)
        # 2000, 3, 31, 3, 45, 00
        # 1999, 3, 31, 3, 45, 00
        # 1999, 2, 28, 3, 45, 00
        # 1999, 2, 21, 3, 45, 00
        # 1999, 2, 20, 3, 45, 00
        # 1999, 2, 20, 2, 45, 00
        # 1999, 2, 20, 2, 44, 00
        # 1999, 2, 20, 2, 43, 59
      ).to eq(Time.new(1999, 2, 20, 2, 43, 59))
    end

    it "calculates a new time after itself" do
      expect(5.minutes.after(@time)).to eq(Time.new(2000, 1, 1, 3, 50, 00))
      expect(5.months.after(@time)).to eq(Time.new(2000, 6, 1, 3, 45, 00))
      expect(65.months.after(@time)).to eq(Time.new(2005, 6, 1, 3, 45, 00))

      expect(
        (60.minutes 12.months).after(@time)
      ).to eq(Time.new(2001, 1, 1, 4, 45, 00))

      expect(
        1.month.after(@end_of_january)
      ).to eq(Time.new(2000, 2, 29, 3, 45, 00))

      expect(
        (1.year 1.month 1.week 1.day 1.hour 1.minute 1.second).after(@time)
        # 2000, 1, 1, 3, 45, 00
        # 2001, 1, 1, 3, 45, 00
        # 2001, 2, 1, 3, 45, 00
        # 2001, 2, 8, 3, 45, 00
        # 2001, 2, 9, 3, 45, 00
        # 2001, 2, 9, 4, 45, 00
        # 2001, 2, 9, 4, 46, 00
        # 2001, 2, 9, 4, 46, 01
      ).to eq(Time.new(2001, 2, 9, 4, 46, 01))

      expect(
        (1.year 1.month 1.week 1.day 1.hour 1.minute 1.second)
          .after(@end_of_january)
        # 2000, 1, 31, 3, 45, 00
        # 2001, 1, 31, 3, 45, 00
        # 2001, 2, 28, 3, 45, 00
        # 2001, 3, 7,  3, 45, 00
        # 2001, 3, 8,  3, 45, 00
        # 2001, 3, 8,  4, 45, 00
        # 2001, 3, 8,  4, 46, 00
        # 2001, 3, 8,  4, 46, 01
      ).to eq(Time.new(2001, 3, 8,  4, 46, 01))
    end
  end

  describe "#new" do
    it "can construct a new `Duration` from a hash of units" do
      duration = Timerizer::Duration.new
      expect(duration.get(:seconds)).to eq(0)
      expect(duration.get(:months)).to eq(0)

      duration = Timerizer::Duration.new(seconds: 10)
      expect(duration.get(:seconds)).to eq(10)
      expect(duration.get(:months)).to eq(0)

      duration = Timerizer::Duration.new(second: 10, minute: 20, hours: 30)
      expect(duration.get(:seconds)).to eq(10 + (20 * 60) + (30 * 60 * 60))
      expect(duration.get(:months)).to eq(0)

      duration = Timerizer::Duration.new(seconds: 10, months: 20)
      expect(duration.get(:seconds)).to eq(10)
      expect(duration.get(:months)).to eq(20)

      duration = Timerizer::Duration.new(hours: 1, days: 2, year: 10)
      expect(duration.get(:seconds)).to eq((60 * 60) + (2 * 24 * 60 * 60))
      expect(duration.get(:months)).to eq(10 * 12)
    end
  end

  describe "#to_wall" do
    it "calculates an equivalent WallClock time" do
      expect(
        (5.hours 30.minutes).to_wall
      ).to eq(Timerizer::WallClock.new(5, 30))
    end

    it "raises an error for times beyond 24 hours" do
      expect do
        1.day.to_wall
      end.to raise_error Timerizer::WallClock::TimeOutOfBoundsError

      expect do
        217.hours.to_wall
      end.to raise_error Timerizer::WallClock::TimeOutOfBoundsError

      expect do
        (1.month 3.seconds).to_wall
      end.to raise_error Timerizer::WallClock::TimeOutOfBoundsError
    end
  end

  describe "#to_s" do
    it "converts all units into a string" do
      expect(
        (1.hour 3.minutes 4.seconds).to_s
      ).to eq("1 hour, 3 minutes, 4 seconds")

      expect(
        (1.year 3.months 4.days).to_s(:long)
      ).to eq("1 year, 3 months, 4 days")
    end

    it "converts units into a micro syntax" do
      expect(
        (1.hour 3.minutes 4.seconds).to_s(:micro)
      ).to eq("1h")

      expect(
        (1.year 3.months 4.days).to_s(:micro)
      ).to eq("1y")
    end

    it "converts units into a medium syntax" do
      expect(
        (1.hour 3.minutes 4.seconds).to_s(:short)
      ).to eq("1hr 3min")

      expect(
        (1.year 3.months 4.days).to_s(:short)
      ).to eq("1yr 3mn")
    end

    it "converts units using a user-defined syntax" do
      expect(
        (1.hour 3.minutes 4.seconds).to_s(
          units: {
            seconds: "second(s)",
            minutes: "minute(s)",
            hours: "hour(s)"
          },
          separator: ' ',
          delimiter: ' / '
        )
      ).to eq("1 hour(s) / 3 minute(s) / 4 second(s)")
    end
  end

  describe "unit conversions" do
    it "converts any `Duration` to seconds" do
      expect(1.second.in_seconds).to eq(1)
      expect((10.minutes 3.seconds).in_seconds).to eq((10 * 60) + 3)
      expect((1.hour 4.minutes).in_seconds).to eq((60 * 60) + (4 * 60))
      expect(3.days.in_seconds).to eq(3 * 24 * 60 * 60)
      expect(2.weeks.in_seconds).to eq(2 * 7 * 24 * 60 * 60)

      expect(1.month.in_seconds).to eq(30 * 24 * 60 * 60)
      expect(1.year.in_seconds).to eq(365 * 24 * 60 * 60)
      expect((1.year 1.second).in_seconds).to eq((365 * 24 * 60 * 60) + 1)
    end

    it "converts any `Duration` to any second-based unit" do
      expect(1.minute.in_minutes).to eq(1)
      expect((10.hours 3.minutes).in_minutes).to eq((10 * 60) + 3)
      expect(2.days.in_hours).to eq(2 * 24)
      expect(3.days.in_days).to eq(3)
      expect(2.weeks.in_weeks).to eq(2)

      expect(1.month.in_days).to eq(30)
      expect(1.year.in_days).to eq(365)
    end

    it "converts any `Duration` to months" do
      expect(1.month.in_months).to eq(1)
      expect(366.days.in_months).to eq(12)
      expect(10.years.in_months).to eq(120)
      expect((366.days 1.month).in_months).to eq(13)
    end

    it "converts any `Duration` to any month-based unit" do
      expect(1.year.in_years).to eq(1)
      expect(732.days.in_years).to eq(2)
      expect(500.years.in_centuries).to eq(5)
      expect((3_660.days 12.month).in_years).to eq(11)
    end

    it "truncates any partial units that cannot be represented exactly" do
      expect(1.second.in_minutes).to eq(0)
      expect((3.days 2.seconds).in_minutes).to eq(3 * 24 * 60)
      expect((367.days).in_years).to eq(1)
    end
  end

  describe "#to_unit" do
    it "converts any `Duration` to seconds" do
      expect(1.second.to_unit(:second)).to eq(1)
      expect((10.minutes 3.seconds).to_unit(:second)).to eq((10 * 60) + 3)
      expect((1.hour 4.minutes).to_unit(:second)).to eq((60 * 60) + (4 * 60))
      expect(3.days.to_unit(:seconds)).to eq(3 * 24 * 60 * 60)
      expect(2.weeks.to_unit(:seconds)).to eq(2 * 7 * 24 * 60 * 60)

      expect(1.month.to_unit(:second)).to eq(30 * 24 * 60 * 60)
      expect(1.year.to_unit(:second)).to eq(365 * 24 * 60 * 60)
      expect((1.year 1.second).to_unit(:second)).to eq((365 * 24 * 60 * 60) + 1)
    end

    it "converts any `Duration` to any second-based unit" do
      expect(1.minute.to_unit(:minute)).to eq(1)
      expect((10.hours 3.minutes).to_unit(:minutes)).to eq((10 * 60) + 3)
      expect(2.days.to_unit(:hour)).to eq(2 * 24)
      expect(3.days.to_unit(:day)).to eq(3)
      expect(2.weeks.to_unit(:week)).to eq(2)

      expect(1.month.to_unit(:days)).to eq(30)
      expect(1.year.to_unit(:days)).to eq(365)
    end

    it "converts any `Duration` to months" do
      expect(1.month.to_unit(:month)).to eq(1)
      expect(366.days.to_unit(:month)).to eq(12)
      expect(10.years.to_unit(:months)).to eq(120)
      expect((366.days 1.month).to_unit(:months)).to eq(13)
    end

    it "converts any `Duration` to any month-based unit" do
      expect(1.year.to_unit(:year)).to eq(1)
      expect(732.days.to_unit(:years)).to eq(2)
      expect(500.years.to_unit(:centuries)).to eq(5)
      expect((3_660.days 12.month).to_unit(:years)).to eq(11)
    end

    it "truncates any partial units that cannot be represented exactly" do
      expect(1.second.to_unit(:minute)).to eq(0)
      expect((3.days 2.seconds).to_unit(:minutes)).to eq(3 * 24 * 60)
      expect((367.days).to_unit(:years)).to eq(1)
    end
  end

  describe "#to_units" do
    it "breaks down a `Duration` into multiple pieces" do
      expect(365.days.to_units(:hours)).to eq(hours: 365 * 24)
      expect(180.days.to_units(:weeks, :days)).to eq(weeks: 25, days: 5)

      expect(
        90.minutes.to_units(:days, :hours, :minutes, :seconds)
      ).to eq(days: 0, hours: 1, minutes: 30, seconds: 0)

      expect(
        (2.years 14.months).to_units(:years, :hours)
      ).to eq(years: 3, hours: 1_440)

      expect(-365.days.to_units(:hours)).to eq(hours: -365 * 24)
      expect(-180.days.to_units(:weeks, :days)).to eq(weeks: -25, days: -5)


      expect(
        -90.minutes.to_units(:days, :hours, :minutes, :seconds)
      ).to eq(days: 0, hours: -1, minutes: -30, seconds: 0)

      expect(
        (-2.years -14.months).to_units(:years, :hours)
      ).to eq(years: -3, hours: -1_440)
    end

    it "returns a hash that has the same keys as the passed-in unit names" do
      # Note that we mix singular and plural forms, and that the returned
      # hash matches the pluralization for each given unit.
      expect(
        0.seconds.to_units(:second, :minutes, :hour, :days)
      ).to eq(second: 0, minutes: 0, hour: 0, days: 0)
    end
  end

  describe "#-@" do
    it "negates the `Duration`" do
      expect(-(10.seconds)).to eq((-10).seconds)
      expect(-(10.years)).to eq((-10).years)
      expect(-(10.years 10.seconds)).to eq((-10).seconds - 10.years)
    end
  end

  describe "#normalize" do
    it "can approxmiate month-based units as second-based units" do
      expect(1.month.normalize.to_unit(:seconds)).to eq(30 * 24 * 60 * 60)

      expect(
        11.months.normalize.to_unit(:seconds)
      ).to eq(11 * 30 * 24 * 60 * 60)

      expect(
        14.months.normalize.to_unit(:seconds)
      ).to eq((365 * 24 * 60 * 60) + (2 * 30 * 24 * 60 * 60))

      expect(
        (25.months 366.days).normalize.get(:seconds)
      ).to eq((3 * 365 * 24 * 60 * 60) + (30 * 24 * 60 * 60) + (24 * 60 * 60))

      expect((-1.month).normalize.to_unit(:seconds)).to eq(-30 * 24 * 60 * 60)

      expect(
        (-11.months).normalize.to_unit(:seconds)
      ).to eq(-11 * 30 * 24 * 60 * 60)

      expect(
        (-14).months.normalize.to_unit(:seconds)
      ).to eq(-(365 * 24 * 60 * 60) - (2 * 30 * 24 * 60 * 60))

      expect(
        (-(25.months 366.days)).normalize.get(:seconds)
      ).to eq(-(3 * 365 * 24 * 60 * 60) - (30 * 24 * 60 * 60) - (24 * 60 * 60))
    end

    it "can normalize using different normalization methods" do
      expect(
        1.month.normalize(method: :minimum).to_unit(:seconds)
      ).to eq(28 * 24 * 60 * 60)

      expect(
        1.month.normalize(method: :maximum).to_unit(:seconds)
      ).to eq(31 * 24 * 60 * 60)

      expect(
        1.year.normalize(method: :minimum).to_unit(:seconds)
      ).to eq(365 * 24 * 60 * 60)

      expect(
        1.year.normalize(method: :maximum).to_unit(:seconds)
      ).to eq(366 * 24 * 60 * 60)
    end
  end

  describe "#denormalize" do
    it "can approximate second-based units as month-based units" do
      expect(30.days.denormalize.to_unit(:months)).to eq(1)

      expect(
        (1.month 100.days).denormalize.to_units(:months, :days)
      ).to eq(months: 4, days: 10)

      expect(
        (2.years 366.days).denormalize.to_units(:years, :days)
      ).to eq(years: 3, days: 1)

      expect((-30.days).denormalize.to_unit(:months)).to eq(-1)

      expect(
        (-(1.month 100.days)).denormalize.to_units(:months, :days)
      ).to eq(months: -4, days: -10)

      expect(
        (-(2.years 366.days)).denormalize.to_units(:years, :days)
      ).to eq(years: -3, days: -1)
    end

    it "can denormalize using different normalization methods" do
      expect(
        32.days.denormalize(method: :minimum).to_units(:months, :days)
      ).to eq(months: 1, days: 4)

      expect(
        32.days.denormalize(method: :maximum).to_units(:months, :days)
      ).to eq(months: 1, days: 1)

      expect(
        367.days.denormalize(method: :minimum).to_units(:years, :days)
      ).to eq(years: 1, days: 2)

      expect(
        367.days.denormalize(method: :maximum).to_units(:years, :days)
      ).to eq(years: 1, days: 1)
    end
  end

  it "can be compared against other `Duration`s" do
    expect(1.minute).to eq(1.minute)
    expect(1.minute).not_to eq(1.hour)

    expect(1.minute).to eq(60.seconds)
    expect(1.week).to eq(7.days)
    expect(12.months).to eq(1.year)
  end
end

RSpec.describe Timerizer::WallClock do
  it "can be created" do
    Timerizer::WallClock.new(12, 30, :pm)
    Timerizer::WallClock.new(23, 30)
  end

  it "can be created from a string" do
    expect(
      Timerizer::WallClock.from_string("9:00 PM")
    ).to eq(Timerizer::WallClock.new(9, 00, :pm))

    expect(
      Timerizer::WallClock.from_string("13:00")
    ).to eq(Timerizer::WallClock.new(13, 00))

    expect(
      Timerizer::WallClock.from_string("12:00 PM")
    ).to eq(Timerizer::WallClock.new(12, 00, :pm))

    expect(
      Timerizer::WallClock.from_string("23:34:45")
    ).to eq(Timerizer::WallClock.new(23, 34, 45))

    expect(
      Timerizer::WallClock.from_string("11:00:01 PM")
    ).to eq(Timerizer::WallClock.new(11, 00, 01, :pm))
  end

  it "can apply a time on a day" do
    date = Date.new(2000, 1, 1)
    expect(
      Timerizer::WallClock.new(9, 00, :pm).on(date)
    ).to eq(Time.new(2000, 1, 1, 21))
  end

  it "can be initialized from a hash of values" do
    date = Date.new(2000, 1, 1)
    expect(
      Timerizer::WallClock.new(second: 30*60).on(date)
    ).to eq(Time.new(2000, 1, 1, 0, 30))
  end

  it "can be converted from an integer" do
    time = Timerizer::WallClock.new(21, 00)

    expect(
      Timerizer::WallClock.new(time.to_i)
    ).to eq(Timerizer::WallClock.new(9, 00, :pm))
  end

  it "can return its components" do
    time = Timerizer::WallClock.new(5, 35, 45, :pm)
    expect(time.hour).to eq(17)
    expect(time.hour(:twenty_four_hour)).to eq(17)
    expect(time.hour(:twelve_hour)).to eq(5)
    expect(time.minute).to eq(35)
    expect(time.second).to eq(45)
    expect(time.meridiem).to eq(:pm)

    expect(time.in_seconds).to eq((17*3600) + (35*60) + 45)
    expect(time.in_minutes).to eq((17*60) + 35)
    expect(time.in_hours).to eq(17)

    expect do
      time.hour(:thirteen_hour)
    end.to raise_error ArgumentError
  end

  it "raises an error for invalid wallclock times" do
    expect do
      Timerizer::WallClock.new(13, 00, :pm)
    end.to raise_error(Timerizer::WallClock::TimeOutOfBoundsError)

    expect do
      Timerizer::WallClock.new(24, 00, 00)
    end.to raise_error(Timerizer::WallClock::TimeOutOfBoundsError)

    expect do
      Timerizer::WallClock.new(0, 60)
    end.to raise_error(Timerizer::WallClock::TimeOutOfBoundsError)
  end

  it "can be converted to a `Duration`" do
    expect(
      Timerizer::WallClock.new(5, 30, 27, :pm).to_duration
    ).to eq(17.hours 30.minutes 27.seconds)
  end

  describe "#to_s" do
    before do
      @time = Timerizer::WallClock.new(5, 30, 27, :pm)
    end

    it "can be converted to a 12-hour time string" do
      expect(@time.to_s).to eq("5:30:27 PM")
      expect(@time.to_s(:twelve_hour)).to eq("5:30:27 PM")
      expect(@time.to_s(:twelve_hour, use_seconds: false)).to eq("5:30 PM")
      expect(@time.to_s(:twelve_hour, include_meridiem: false)).to eq("5:30:27")

      expect(
        @time.to_s(
          :twelve_hour,
          include_meridiem: false,
          use_seconds: false
        )
      ).to eq("5:30")
    end

    it "can be converted to a 24-hour time string" do
      expect(@time.to_s(:twenty_four_hour)).to eq("17:30:27")
      expect(
        @time.to_s(:twenty_four_hour, use_seconds: false)
      ).to eq("17:30")
    end

    it "zero-pads units" do
      time = Timerizer::WallClock.new(0, 00, 00)
      expect(time.to_s(:twelve_hour)).to eq("12:00:00 PM")
      expect(time.to_s(:twenty_four_hour)).to eq("0:00:00")

      expect(time.to_s(:twelve_hour, use_seconds: false)).to eq("12:00 PM")
      expect(time.to_s(:twenty_four_hour, use_seconds: false)).to eq("0:00")
    end
  end
end

RSpec.describe Time do
  it "can be added or subtracted to Duration" do
    time = Time.new(2000, 1, 1, 3, 45, 00)
    expect(time + 5.minutes).to eq(Time.new(2000, 1, 1, 3, 50, 00))
    expect(time - 5.minutes).to eq(Time.new(2000, 1, 1, 3, 40, 00))
  end

  it "can be converted to a Date object" do
    time = Time.new(2000, 1, 1, 11, 59, 00)
    expect(time.to_date).to eq(Date.new(2000, 1, 1))
  end

  it "calculates the time between two Times" do
    time = 1.minute.ago
    expect(Time.until(1.minute.from_now).in_seconds).to be_within(1.0).of(60)
    expect(Time.since(1.hour.ago).in_seconds).to be_within(1.0).of(3600)

    expect(
      Time.between(1.minute.ago, 2.minutes.ago).in_seconds
    ).to be_within(1.0).of(60)

    expect(
      Time.between(Date.yesterday, Date.tomorrow).in_seconds
    ).to be_within(1.0).of(2.days.in_seconds)

    expect do
      Time.until(1.minute.ago)
    end.to raise_error(Time::TimeIsInThePastError)

    expect do
      Time.since(Date.tomorrow)
    end.to raise_error(Time::TimeIsInTheFutureError)
  end

  it "can be converted to a WallClock time" do
    time = Time.new(2000, 1, 1, 17, 58, 04)
    expect(time.to_wall).to eq(Timerizer::WallClock.new(5, 58, 04, :pm))
  end
end

RSpec.describe Date do
  it "can be converted to a Time object" do
    date = Date.new(2000, 1, 1)
    expect(date.to_time).to eq(Time.new(2000, 1, 1))
  end

  it "returns the number of days in a month" do
    expect(Date.new(2000, 1).days_in_month).to eq(31)
    expect(Date.new(2000, 2).days_in_month).to eq(29)
    expect(Date.new(2001, 2).days_in_month).to eq(28)
  end

  it "returns the date yesterday and tomorrow" do
    yesterday = 1.day.ago.to_date
    tomorrow = 1.day.from_now.to_date

    expect(Date.yesterday).to eq(yesterday)
    expect(Date.tomorrow).to eq(tomorrow)
  end

  it "returns the time on a given date" do
     date = Date.new(2000, 1, 1)
     time = Timerizer::WallClock.new(5, 00, :pm)
     expect(date.at(time)).to eq(Time.new(2000, 1, 1, 17))
  end
end

RSpec.describe Integer do
  it "makes Duration objects" do
    expect(1.minute.get(:seconds)).to eq(60)
    expect(3.hours.get(:seconds)).to eq(10800)
    expect(5.days.get(:seconds)).to eq(432000)
    expect(4.years.get(:months)).to eq(48)

    duration = 1.second 2.minutes 3.hours 4.days 5.weeks 6.months 7.years
    expect(duration.get(:seconds)).to eq(3380521)
    expect(duration.get(:months)).to eq(90)
  end
end
