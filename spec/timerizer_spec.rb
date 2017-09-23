require "spec_helper"

RSpec.describe RelativeTime do
  context "given an existing time" do
    before :all do
      @time = Time.new(2000, 1, 1, 3, 45, 00)
    end

    it "calculates a new time before itself" do
      expect(5.minutes.before(@time)).to eq(Time.new(2000, 1, 1, 3, 40, 00))
      expect(5.months.before(@time)).to eq(Time.new(1999, 8, 1, 3, 45, 00))
    end

    it "calculates a new time after itself" do
      expect(5.minutes.after(@time)).to eq(Time.new(2000, 1, 1, 3, 50, 00))
      expect(5.months.after(@time)).to eq(Time.new(2000, 6, 1, 3, 45, 00))
    end

    it "properly handles large periods of time" do
      expect(65.months.before(@time)).to eq(Time.new(1994, 8, 1, 3, 45, 00))
      expect(65.months.after(@time)).to eq(Time.new(2005, 6, 1, 3, 45, 00))
    end
  end

  context "given an odd time case" do
    it "properly calculates the time before it" do
      end_of_march = Time.new(2000, 3, 31, 3, 45, 00)
      expect(
        1.month.before(end_of_march)
      ).to eq(Time.new(2000, 2, 29, 3, 45, 00))
    end

    it "properly calculates the time after it" do
      end_of_january = Time.new(2000, 1, 31, 3, 45, 00)
      expect(
        1.month.after(end_of_january)
      ).to eq(Time.new(2000, 2, 29, 3, 45, 00))
    end
  end

  describe "#to_wall" do
    it "calculates an equivalent WallClock time" do
      expect((5.hours 30.minutes).to_wall).to eq(WallClock.new(5, 30))
    end

    it "raises an error for times beyond 24 hours" do
      expect do
        1.day.to_wall
      end.to raise_error WallClock::TimeOutOfBoundsError

      expect do
        217.hours.to_wall
      end.to raise_error WallClock::TimeOutOfBoundsError

      expect do
        (1.month 3.seconds).to_wall
      end.to raise_error WallClock::TimeOutOfBoundsError
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
  end

  it "can average from second units to month units" do
    five_weeks = {
      :seconds => 3024000,
      :average => {:seconds => 394254, :months => 1}
    }

    expect(5.weeks.get(:seconds)).to eq(five_weeks[:seconds])

    average = 5.weeks.average!
    expect(average.get(:seconds)).to eq(five_weeks[:average][:seconds])
    expect(average.get(:months)).to eq(five_weeks[:average][:months])
  end

  it "can unaverage from month units to second units" do
    two_months = {
      :months => 2,
      :unaverage => {:seconds => 5259492, :months => 0}
    }

    expect(2.months.get(:months)).to eq(two_months[:months])

    unaverage = 2.months.unaverage!

    expect(unaverage.get(:seconds)).to eq(two_months[:unaverage][:seconds])
    expect(unaverage.get(:months)).to eq(two_months[:unaverage][:months])
  end

  it "can compare two RelativeTimes" do
    expect(1.minute).to eq(1.minute)
    expect(1.minute).not_to eq(1.hour)
  end
end

RSpec.describe WallClock do
  it "can be created" do
    WallClock.new(12, 30, :pm)
    WallClock.new(23, 30)
  end

  it "can be created from a string" do
    expect(WallClock.from_string("9:00 PM")).to eq(WallClock.new(9, 00, :pm))
    expect(WallClock.from_string("13:00")).to eq(WallClock.new(13, 00))
    expect(WallClock.from_string("12:00 PM")).to eq(WallClock.new(12, 00, :pm))
    expect(WallClock.from_string("23:34:45")).to eq(WallClock.new(23, 34, 45))

    expect(
      WallClock.from_string("11:00:01 PM")
    ).to eq(WallClock.new(11, 00, 01, :pm))
  end

  it "can apply a time on a day" do
    date = Date.new(2000, 1, 1)
    expect(WallClock.new(9, 00, :pm).on(date)).to eq(Time.new(2000, 1, 1, 21))
  end

  it "can be initialized from a hash of values" do
    date = Date.new(2000, 1, 1)
    expect(
      WallClock.new(:second => 30*60).on(date)
    ).to eq(Time.new(2000, 1, 1, 0, 30))
  end

  it "can be converted from an integer" do
    time = WallClock.new(21, 00)
    expect(WallClock.new(time.to_i)).to eq(WallClock.new(9, 00, :pm))
  end

  it "can return its components" do
    time = WallClock.new(5, 35, 45, :pm)
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
      WallClock.new(13, 00, :pm)
    end.to raise_error(WallClock::TimeOutOfBoundsError)

    expect do
      WallClock.new(24, 00, 00)
    end.to raise_error(WallClock::TimeOutOfBoundsError)

    expect do
      WallClock.new(0, 60)
    end.to raise_error(WallClock::TimeOutOfBoundsError)
  end

  it "can be converted to RelativeTime" do
    expect(
      WallClock.new(5, 30, 27, :pm).to_relative
    ).to eq(17.hours 30.minutes 27.seconds)
  end

  describe "#to_s" do
    before do
      @time = WallClock.new(5, 30, 27, :pm)
    end

    it "can be converted to a 12-hour time string" do
      expect(@time.to_s).to eq("5:30:27 PM")
      expect(@time.to_s(:twelve_hour)).to eq("5:30:27 PM")
      expect(@time.to_s(:twelve_hour, :use_seconds => false)).to eq("5:30 PM")
      expect(@time.to_s(:twelve_hour, :include_meridiem => false)).to eq("5:30:27")

      expect(
        @time.to_s(
          :twelve_hour,
          :include_meridiem => false,
          :use_seconds => false
        )
      ).to eq("5:30")
    end

    it "can be converted to a 24-hour time string" do
      expect(@time.to_s(:twenty_four_hour)).to eq("17:30:27")
      expect(
        @time.to_s(:twenty_four_hour, :use_seconds => false)
      ).to eq("17:30")
    end

    it "zero-pads units" do
      time = WallClock.new(0, 00, 00)
      expect(time.to_s(:twelve_hour)).to eq("12:00:00 PM")
      expect(time.to_s(:twenty_four_hour)).to eq("0:00:00")

      expect(time.to_s(:twelve_hour, :use_seconds => false)).to eq("12:00 PM")
      expect(time.to_s(:twenty_four_hour, :use_seconds => false)).to eq("0:00")
    end
  end
end

RSpec.describe Time do
  it "can be added or subtracted to RelativeTime" do
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
    expect(time.to_wall).to eq(WallClock.new(5, 58, 04, :pm))
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
     time = WallClock.new(5, 00, :pm)
     expect(date.at(time)).to eq(Time.new(2000, 1, 1, 17))
  end
end

RSpec.describe Integer do
  it "makes RelativeTime objects" do
    expect(1.minute.get(:seconds)).to eq(60)
    expect(3.hours.get(:seconds)).to eq(10800)
    expect(5.days.get(:seconds)).to eq(432000)
    expect(4.years.get(:months)).to eq(48)

    relative_time = 1.second 2.minutes 3.hours 4.days 5.weeks 6.months 7.years
    expect(relative_time.get(:seconds)).to eq(3380521)
    expect(relative_time.get(:months)).to eq(90)
  end
end
