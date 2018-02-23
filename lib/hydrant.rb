module Hydrant
  class HydrantException < Exception; end

  # TODO: Move the logic from can_sell_hydrant here. The goal is to have any
  # request be handled by any tester, if possible, though we'll have to be
  # very explicit about how we set test records when we call sell_hydrant;
  # we'll probably need to return the name of the tester so we can explicitly
  # add a test record to that tester's queue.
  class Queue
    # We don't know and don't care who the testers are. Even if there's just one
    # and it's passed as a string, we dynamically set up each tester as a sorted
    # set, and provide a dynamic getter so that they can be called individually.
    def initialize(testers)
      Array.wrap(testers).each do |q|
        instance_variable_set(('@' + q).to_sym, SortedSet.new)
        self.class.send(:attr_reader, q.to_sym) # ruby magic
        (@testers ||= []).push(q.to_sym)
      end
    end
    attr_reader :testers

    # Returns the number of items in the sorted set keyed to :tester which have
    # a time between the specified :period and the specified :start_time. This
    # allows testing for occurrences between *any* two periods of time but in
    # practice will be used to enforce our testers' somewhat mystifying
    # contractual provisions.
    def period_count(tester: :piddles, period:, start_time: Time.now)
      raise HydrantException.new("Invalid start time") unless start_time.is_a? Time
      raise HydrantException.new("Invalid test period") unless period.is_a? ActiveSupport::Duration

      # This is a nifty bit of Ruby. Explained:
      # self.send(tester.to_sym) => call the instance method whose name matches the value of tester,
      #    which returns a Ruby SortedSet, as initialized when this instance was created.
      # map {|o| o < ((start_time - period).to_i .. start_time.to_i).include? o} => Find all
      #    values in the SortedSet that are inclusively between start_time and start_time - period.
      #    Returns an array of Booleans.
      # reject{|i| !i}.count => remove any false bools in the array, and count the remaining trues.
      self.send(tester.to_sym).map {|o| ((start_time - period).to_i .. start_time.to_i).include? o}.reject{|i| !i}.count
    end

    def period_all_count(period:, start_time: Time.now)
      raise HydrantException.new("Invalid start time") unless start_time.is_a? Time
      raise HydrantException.new("Invalid test period") unless period.is_a? ActiveSupport::Duration

      results = {}
      @testers.each do |tester|
        results[tester] = period_count(tester: tester.to_sym, period: period, start_time: start_time)
      end
      results
    end

    # Add a new timestamp to a tester's history. Also, execute a utility function
    # that trims that tester's history.
    def add_test_record(tester: :piddles, sell_time: Time.now)
      self.send(tester.to_sym).add(sell_time.to_i)
      truncate_test_record(tester: tester, sell_time: sell_time)
    end

    # Delete any test records for a tester older than 1 hour (default).
    def truncate_test_record(tester: :piddles, sell_time: Time.now, trim_time: 1.hour)
      self.send(tester.to_sym).delete_if {|t| t < (sell_time - trim_time).to_i }
    end

    def empty_test_record(tester: :piddles)
      if tester.to_sym == :all
        @testers.each do |t|
          self.send(t.to_sym).clear
        end
      else
        self.send(tester.to_sym).clear
      end
    end
  end

  class << self
    # V1 ==========
    # only works with a single seller (piddles).

    # returns true if there are no sell records in the last 5 minutes, and
    # fewer than 5 in the past hour.
    def can_sell_hydrant(sell_time: Time.now)
      last_5_minutes = HydrantQueue.period_count(period: 5.minutes, start_time: sell_time)
      last_hour = HydrantQueue.period_count(period: 1.hour, start_time: sell_time)
      return [last_5_minutes == 0, last_hour < 5].all?
    end

    # returns false if we're unable to sell a hydrant right now. Sets a sale record
    # and returns true if we can.
    def sell_hydrant(sell_time: Time.now)
      return false unless can_sell_hydrant(sell_time: sell_time)

       # we sold a hydrant! tell the queue we've done so.
      HydrantQueue.add_test_record(sell_time: sell_time.to_i)
      return true # this stands in for some other business logic
    end

    # V2 ==========

    # returns an array of all testers who match the given criteria. Downstream
    # methods will do the logic needed on that array.
    def available_testers(sell_time: Time.now)
      last_5_minutes = HydrantQueue.period_all_count(period: 5.minutes, start_time: sell_time)
      last_hour = HydrantQueue.period_all_count(period: 1.hour, start_time: sell_time)

      # This logic is:
      # last_5_minutes.select{|k,v| v == 0} => array of seller keys with no sales in last 5 minutes
      # last_hour.select{|k,v| v < 5} => array of seller keys with fewer than 5 sales in the last 5 minutes
      # available_sellers is an intersection (&) of those two arrays of keys
      available_testers = (last_5_minutes.select{|k,v| v == 0}.keys) & (last_hour.select{|k,v| v < 5}.keys)
    end

    # Return true if ANY tester can sell a hydrant at the specified sell_time,
    # otherwise false.
    def any_can_sell_hydrant(sell_time: Time.now)
      return !(available_testers(sell_time: sell_time).empty?)
    end

    # Return false if no tester can sell a hydrant at the specified sell time,
    # otherwise:
    # 1. selects an available tester
    # 2. gives them a sell record
    # 3. returns true
    def any_sell_hydrant(sell_time: Time.now)
      testers = available_testers(sell_time: sell_time)
      return false if testers.empty?

      # We may have more than one tester right now, so we choose one at random.
      HydrantQueue.add_test_record(tester: testers.sample, sell_time: sell_time)
      return true
    end
  end
end
