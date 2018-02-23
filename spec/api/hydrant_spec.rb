require 'spec_helper'
require 'pry'

describe Hydrant do

  before :all do
    @base_time = Time.parse('2018-01-01 00:00')
  end

  before :each do
    HydrantQueue.empty_test_record(tester: :all)
  end

  describe 'V1' do

    it 'can sell hydrant with empty queue' do
      expect(Hydrant.can_sell_hydrant(sell_time: @base_time)).to be_true
    end

    it 'sells hydrant with empty queue' do
      expect(Hydrant.sell_hydrant(sell_time: @base_time)).to be_true
    end

    it 'cannot sell another hydrant within 5 minutes' do
      Hydrant.sell_hydrant(sell_time: @base_time)

      working_time = @base_time + 5.minutes
      expect(Hydrant.can_sell_hydrant(sell_time: working_time)).to be_false
      expect(Hydrant.sell_hydrant(sell_time: working_time)).to be_false
    end

    it 'can sell a hydrant 5:01 after sale' do
      Hydrant.sell_hydrant(sell_time: @base_time)

      working_time = @base_time + 5.minutes + 1.second
      expect(Hydrant.can_sell_hydrant(sell_time: working_time)).to be_true
      expect(Hydrant.sell_hydrant(sell_time: working_time)).to be_true
    end

    it 'can sell 5 hydrants in 1 hour' do
      Hydrant.sell_hydrant(sell_time: @base_time)

      working_time = @base_time + 6.minutes
      4.times do
        expect(Hydrant.can_sell_hydrant(sell_time: working_time)).to be_true
        expect(Hydrant.sell_hydrant(sell_time: working_time)).to be_true
        working_time += 6.minutes
      end
    end

    it 'cannot sell 6 hydrants in 1 hour' do
      Hydrant.sell_hydrant(sell_time: @base_time)

      working_time = @base_time + 6.minutes
      4.times do
        Hydrant.sell_hydrant(sell_time: working_time)
        working_time += 6.minutes
      end

      expect(Hydrant.can_sell_hydrant(sell_time: working_time)).to be_false
      expect(Hydrant.sell_hydrant(sell_time: working_time)).to be_false
    end

    it 'can sell 1 hydrant an hour after selling 5 hydrants' do
      Hydrant.sell_hydrant(sell_time: @base_time)
      working_time = @base_time + 6.minutes
      4.times do
        Hydrant.sell_hydrant(sell_time: working_time)
        working_time += 6.minutes
      end

      working_time = @base_time + 1.hour + 1.second
      expect(Hydrant.can_sell_hydrant(sell_time: working_time)).to be_true
      expect(Hydrant.sell_hydrant(sell_time: working_time)).to be_true
    end
  end

  describe 'V2' do
    it 'can sell 3 hydrants immediately' do
      3.times do
        expect(Hydrant.any_can_sell_hydrant(sell_time: @base_time)).to be_true
        expect(Hydrant.any_sell_hydrant(sell_time: @base_time)).to be_true
      end
    end

    it 'cannot sell any hydrants less than 5 minutes after selling 3 hydrants' do
      3.times do
        Hydrant.any_sell_hydrant(sell_time: @base_time)
      end

      working_time = @base_time + 5.minutes
      expect(Hydrant.any_can_sell_hydrant(sell_time: working_time)).to be_false
      expect(Hydrant.any_sell_hydrant(sell_time: working_time)).to be_false
    end

    it 'can sell 3 hydrants every 5 minutes' do
      working_time = @base_time
      5.times do
        3.times do
          expect(Hydrant.any_can_sell_hydrant(sell_time: working_time)).to be_true
          expect(Hydrant.any_sell_hydrant(sell_time: working_time)).to be_true
          working_time += 1.second
        end
        working_time += 5.minutes
      end
    end

    it 'cannot sell 6 hydrants for any tester in 1 hour' do
      working_time = @base_time
      5.times do
        3.times do
          Hydrant.any_sell_hydrant(sell_time: working_time)
          working_time += 1.second
        end
        working_time += 5.minutes
      end

      expect(Hydrant.any_can_sell_hydrant(sell_time: working_time)).to be_false
      expect(Hydrant.any_sell_hydrant(sell_time: working_time)).to be_false
    end

    it 'can sell hydrants an hour after first if 5 hydrants sold per tester per hour... *GASP*' do
      working_time = @base_time
      5.times do
        3.times do
          Hydrant.any_sell_hydrant(sell_time: working_time)
          working_time += 1.second
        end
        working_time += 5.minutes
      end

      working_time = @base_time + 1.hour + 1.second
      expect(Hydrant.any_can_sell_hydrant(sell_time: working_time)).to be_true
      expect(Hydrant.any_sell_hydrant(sell_time: working_time)).to be_true
    end
  end

end
