require 'spec_helper'

describe Bodhi::Simulator do
  let(:simulation){ Bodhi::Simulator.new(starts_at: "2016-05-10", iterations: 2, time_scale: "days") }

  describe ".complete?" do
    it "returns true if simulation is complete" do
      simulation.iterations = 1
      simulation.current_iteration = 1
      expect(simulation.complete?).to be true
    end

    it "returns false if simulation is not complete" do
      simulation.iterations = 10
      simulation.current_iteration = 1
      expect(simulation.complete?).to be false
    end
  end

  describe ".increment" do
    it "increments the :current_iteration by 1" do
      simulation.current_iteration = 1
      simulation.increment

      expect(simulation.current_iteration).to eq 2
    end

    it "increments the :current_time by 1 :time_scale unit" do
      simulation.current_iteration = 0
      simulation.starts_at = Time.parse("2016-05-13")
      simulation.current_time = Time.parse("2016-05-13")
      simulation.time_scale = "days"
      simulation.increment
      expect(simulation.current_time).to eq Time.parse("2016-05-14")
    end
  end

  describe "#execute(settings, &block)" do
    it "raises ArgumentError if the settings are not valid" do
      expect { Bodhi::Simulator.execute(iterations: -1) }.to raise_error(ArgumentError, "Invalid settings: [\"starts_at is required\", \"iterations must be greater than or equal to 1\", \"time_scale is required\"]")
    end

    it "yields the :current_time to the &block" do
      expect { |block| Bodhi::Simulator.execute(starts_at: "2016-05-10", iterations: 1, time_scale: "days", &block) }.to yield_successive_args(Time.parse("2016-05-10"))
    end

    it "yields the :current_time as many times as the :iterations is set to" do
      expect { |block| Bodhi::Simulator.execute(starts_at: "2016-05-10", iterations: 100, time_scale: "days", &block) }.to yield_control.exactly(100).times
    end
  end
end