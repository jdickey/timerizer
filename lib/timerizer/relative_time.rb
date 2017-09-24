# Represents a relative amount of time. For example, '`5 days`', '`4 years`', and '`5 years, 4 hours, 3 minutes, 2 seconds`' are all RelativeTimes.
class RelativeTime
  UNITS = {
    seconds: {seconds: 1},
    minutes: {seconds: 60},
    hours: {seconds: 60 * 60},
    days: {seconds: 24 * 60 * 60},
    weeks: {seconds: 7 * 24 * 60 * 60},
    months: {months: 1},
    years: {months: 12},
    decades: {months: 12 * 10},
    centuries: {months: 12 * 100},
    millennia: {months: 12 * 1000}
  }

  UNIT_PLURALS = {
    second: :seconds,
    minute: :minutes,
    hour: :hours,
    day: :days,
    week: :weeks,
    month: :months,
    year: :years,
    decade: :decades,
    century: :centuries,
    millennium: :millennia
  }

  @@units = {
    second: :seconds,
    minute: :minutes,
    hour: :hours,
    day: :days,
    week: :weeks,
    month: :months,
    year: :years,
    decade: :decades,
    century: :centuries,
    millennium: :millennia
  }

  @@in_seconds = {
    second: 1,
    minute: 60,
    hour: 3600,
    day: 86400,
    week: 604800
  }

  @@in_months = {
    month: 1,
    year: 12,
    decade: 120,
    century: 1200,
    millennium: 12000
  }

  # Average amount of time in a given unit. Used internally within the {#average} and {#unaverage} methods.
  @@average_seconds = {
    month: 2629746,
    year: 31556952
  }

  # Default syntax formats that can be used with #to_s
  # @see #to_s
  @@syntaxes = {
    micro: {
      units: {
        seconds: 's',
        minutes: 'm',
        hours: 'h',
        days: 'd',
        weeks: 'w',
        months: 'mn',
        years: 'y',
      },
      separator: '',
      delimiter: ' ',
      count: 1
    },
    short: {
      units: {
        seconds: 'sec',
        minutes: 'min',
        hours: 'hr',
        days: 'd',
        weeks: 'wk',
        months: 'mn',
        years: 'yr',
        centuries: 'ct',
        millenia: 'ml'
      },
      separator: '',
      delimiter: ' ',
      count: 2
    },
    long: {
      units: {
        seconds: ['second', 'seconds'],
        minutes: ['minute', 'minutes'],
        hours: ['hour', 'hours'],
        days: ['day', 'days'],
        weeks: ['week', 'weeks'],
        months: ['month', 'months'],
        years: ['year', 'years'],
        centuries: ['century', 'centuries'],
        millennia: ['millenium', 'millenia'],
      }
    }
  }

  # All potential units. Key is the unit name, and the value is its plural form.
  def self.units
    @@units
  end

  # Unit values in seconds. If a unit is not present in this hash, it is assumed to be in the {@@in_months} hash.
  def self.units_in_seconds
    @@in_seconds
  end

  # Unit values in months. If a unit is not present in this hash, it is assumed to be in the {@@in_seconds} hash.
  def self.units_in_months
    @@in_months
  end

  # Initialize a new instance of RelativeTime.
  # @overload new(hash)
  #   @param [Hash] units The base units to initialize with
  #   @option units [Integer] :seconds The number of seconds
  #   @option units [Integer] :months The number of months
  # @overload new(count, unit)
  #   @param [Integer] count The number of units to initialize with
  #   @param [Symbol] unit The unit to initialize. See {RelativeTime#units}
  def initialize(count = 0, unit = :second)
    if count.is_a? Hash
      units = count
      units.default = 0
      @seconds, @months = units.values_at(:seconds, :months)
    else
      @seconds = @months = 0

      if @@in_seconds.has_key?(unit)
        @seconds = count * @@in_seconds.fetch(unit)
      elsif @@in_months.has_key?(unit)
        @months = count * @@in_months.fetch(unit)
      end
    end
  end

  # Compares two RelativeTimes to determine if they are equal
  # @param [RelativeTime] time The RelativeTime to compare
  # @return [Boolean] True if both RelativeTimes are equal
  # @note Be weary of rounding; this method compares both RelativeTimes' base units
  def ==(time)
    if time.is_a?(RelativeTime)
      @seconds == time.get(:seconds) && @months == time.get(:months)
    else
      false
    end
  end

  # Return the number of base units in a RelativeTime.
  # @param [Symbol] unit The unit to return, either :seconds or :months
  # @return [Integer] The requested unit count
  # @raise [ArgumentError] Unit requested was not :seconds or :months
  def get(unit)
    if unit == :seconds
      @seconds
    elsif unit == :months
      @months
    else
      raise ArgumentError
    end
  end

  # Determines the time between RelativeTime and the given time.
  # @param [Time] time The initial time.
  # @return [Time] The difference between the current RelativeTime and the given time
  # @example 5 hours before January 1st, 2000 at noon
  #   5.minutes.before(Time.new(2000, 1, 1, 12, 00, 00))
  #     => 2000-01-01 11:55:00 -0800
  # @see #ago
  # @see #after
  # @see #from_now
  def before(time)
    time = time.to_time - @seconds

    new_month = time.month - self.months
    new_year = time.year - self.years
    while new_month < 1
      new_month += 12
      new_year -= 1
    end
    if Date.valid_date?(new_year, new_month, time.day)
      new_day = time.day
    else
      new_day = Date.new(new_year, new_month).days_in_month
    end

    new_time = Time.new(
      new_year, new_month, new_day,
      time.hour, time.min, time.sec
    )
    Time.at(new_time.to_i, time.nsec/1000)
  end

  # Return the time between the RelativeTime and the current time.
  # @return [Time] The difference between the current RelativeTime and Time#now
  # @see #before
  def ago
    self.before(Time.now)
  end

  # Return the time after the given time according to the current RelativeTime.
  # @param [Time] time The starting time
  # @return [Time] The time after the current RelativeTime and the given time
  # @see #before
  def after(time)
    time = time.to_time + @seconds

    new_year = time.year + self.years
    new_month = time.month + self.months
    while new_month > 12
      new_year += 1
      new_month -= 12
    end
    if Date.valid_date?(new_year, new_month, time.day)
      new_day = time.day
    else
      new_day = Date.new(new_year, new_month).days_in_month
    end


    new_time = Time.new(
      new_year, new_month, new_day,
      time.hour, time.min, time.sec
    )
    Time.at(new_time.to_i, time.nsec/1000.0)
  end

  # Return the time after the current time and the RelativeTime.
  # @return [Time] The time after the current time
  def from_now
    self.after(Time.now)
  end

  @@units.each do |unit, plural|
    in_method = "in_#{plural}"
    count_method = plural
    superior_unit = @@units.keys.index(unit) + 1

    if @@in_seconds.has_key? unit
      class_eval "
        def #{in_method}
          @seconds / #{@@in_seconds[unit]}
        end
      "
    elsif @@in_months.has_key? unit
      class_eval "
        def #{in_method}
          @months / #{@@in_months[unit]}
        end
      "
    end

    in_superior = "in_#{@@units.values[superior_unit]}"
    count_superior = @@units.keys[superior_unit]


    class_eval "
      def #{count_method}
        time = self.#{in_method}
        if @@units.length > #{superior_unit}
          time -= self.#{in_superior}.#{count_superior}.#{in_method}
        end
        time
      end
    "
  end

  def to_unit(unit)
    unit_details = self.class.resolve_unit(unit)

    if unit_details.has_key?(:seconds)
      seconds = self.unaverage.get(:seconds)
      seconds / unit_details.fetch(:seconds)
    elsif unit_details.has_key?(:months)
      months = self.average.get(:months)
      months / unit_details.fetch(:months)
    else
      raise "Unit should have key :seconds or :months"
    end
  end

  def to_units(*units)
    sorted_units = self.class.sort_units(units).reverse

    _, parts = sorted_units.reduce([self, {}]) do |(remainder, parts), unit|
      # TODO: Refactor to avoid calling `#send`
      part = remainder.to_unit(unit)
      new_remainder = remainder - part.send(unit)

      [new_remainder, parts.merge(unit => part)]
    end

    parts
  end

  # Average second-based units to month-based units.
  # @return [RelativeTime] The averaged RelativeTime
  # @example
  #   5.weeks.average
  #     => 1 month, 4 days, 13 hours, 30 minutes, 54 seconds
  # @see #average!
  # @see #unaverage
  def average
    if @seconds > 0
      months = (@seconds / @@average_seconds[:month])
      seconds = @seconds - months.months.unaverage.get(:seconds)
      RelativeTime.new(
        seconds: seconds,
        months: months + @months
      )
    else
      self
    end
  end

  # Destructively average second-based units to month-based units.
  # @see #average
  def average!
    averaged = self.average
    @seconds = averaged.get(:seconds)
    @months = averaged.get(:months)
    self
  end

  # Average month-based units to second-based units.
  # @return [RelativeTime] the unaveraged RelativeTime.
  # @example
  #   1.month.unaverage
  #     => 4 weeks, 2 days, 10 hours, 29 minutes, 6 seconds
  # @see #average
  # @see #unaverage!
  def unaverage
    seconds = @@average_seconds[:month] * @months
    seconds += @seconds
    RelativeTime.new(seconds: seconds)
  end

  # Destructively average month-based units to second-based units.
  # @see #unaverage
  def unaverage!
    unaveraged = self.average
    @seconds = unaverage.get(:seconds)
    @months = unaverage.get(:months)
    self
  end

  # Add two {RelativeTime}s together.
  # @raise ArgumentError Argument isn't a {RelativeTime}
  # @see #-
  def +(time)
    raise ArgumentError unless time.is_a?(RelativeTime)
    RelativeTime.new({
      seconds: @seconds + time.get(:seconds),
      months: @months + time.get(:months)
    })
  end

  # Find the difference between two {RelativeTime}s.
  # @raise ArgumentError Argument isn't a {RelativeTime}
  # @see #+
  def -(time)
    raise ArgumentError unless time.is_a?(RelativeTime)
    RelativeTime.new({
      seconds: @seconds - time.get(:seconds),
      months: @months - time.get(:months)
    })
  end

  # Converts {RelativeTime} to {WallClock}
  # @return [WallClock] {RelativeTime} as {WallClock}
  # @example
  #   (17.hours 30.minutes).to_wall
  #     # => 5:30:00 PM
  def to_wall
    raise WallClock::TimeOutOfBoundsError if @months > 0
    WallClock.new(second: @seconds)
  end

  # Convert {RelativeTime} to a human-readable format.
  # @overload to_s(syntax)
  #   @param [Symbol] syntax The syntax from @@syntaxes to use
  # @overload to_s(hash)
  #   @param [Hash] hash The custom hash to use
  #   @option hash [Hash] :units The unit names to use. See @@syntaxes for examples
  #   @option hash [Integer] :count The maximum number of units to output. `1` would output only the unit of greatest example (such as the hour value in `1.hour 3.minutes 2.seconds`).
  #   @option hash [String] :separator The separator to use in between a unit and its value
  #   @option hash [String] :delimiter The delimiter to use in between different unit-value pairs
  # @example
  #   (14.months 49.hours).to_s
  #     => 2 years, 2 months, 3 days, 1 hour
  #   (1.day 3.hours 4.minutes).to_s(:short)
  #     => 1d 3hr
  # @raise KeyError Symbol argument isn't in @@syntaxes
  # @raise ArgumentError Argument isn't a hash (if not a symbol)
  # @see @@syntaxes
  def to_s(syntax = :long)
    if syntax.is_a? Symbol
      syntax = @@syntaxes.fetch(syntax)
    end

    raise ArgumentError unless syntax.is_a? Hash
    times = []

    if syntax[:count].nil? || syntax[:count] == :all
      syntax[:count] = @@units.count
    end
    units = syntax.fetch(:units)

    count = 0
    units = Hash[units.to_a.reverse]
    units.each do |unit, (singular, plural)|
      if count < syntax.fetch(:count)
        time = self.respond_to?(unit) ? self.send(unit) : 0

        if time > 1 && !plural.nil?
          times << [time, plural]
          count += 1
        elsif time > 0
          times << [time, singular]
          count += 1
        end
      end
    end

    times.map do |time|
      time.join(syntax[:separator] || ' ')
    end.join(syntax[:delimiter] || ', ')
  end

  private

  def self.normalize_unit(unit)
    if UNITS.has_key?(unit)
      unit
    elsif UNIT_PLURALS.has_key?(unit)
      UNIT_PLURALS.fetch(unit)
    else
      raise ArgumentError, "Unknown unit: #{unit.inspect}"
    end
  end

  def self.resolve_unit(unit)
    normalized_unit = self.normalize_unit(unit)
    UNITS.fetch(normalized_unit)
  end

  def self.sort_units(units)
    units.sort_by do |unit|
      index = UNITS.find_index {|u, _| u == self.normalize_unit(unit)}
      index or raise ArgumentError, "Unknown unit: #{unit.inspect}"
    end
  end
end
