require 'spec_helper'

describe Bodhi::Simulator do
  let(:simulation){ 
    Bodhi::Simulator.new(
      starts_at: "2016-05-10", 
      iterations: 2,
      time_units: "days",
      time_scale: 1,
      current_frame: { iteration: 0, time: Time.parse("2016-05-10") }
    )
  }

  describe "Instance Methods" do
    describe ".complete?" do
      it "returns true if simulation is complete" do
        simulation.iterations = 1
        simulation.current_frame.iteration = 1

        expect(simulation.complete?).to be true
      end

      it "returns false if simulation is not complete" do
        simulation.iterations = 10
        simulation.current_frame.iteration = 1

        expect(simulation.complete?).to be false
      end
    end

    describe ".increment" do
      it "increments the :current_frame.iteration by 1" do
        simulation.current_frame.iteration = 1
        simulation.increment

        expect(simulation.current_frame.iteration).to eq 2
      end

      it "increments the :current_frame.time by 1 :time_unit" do
        simulation.current_frame.iteration = 0
        simulation.current_frame.time = Time.parse("2016-05-13")
        simulation.starts_at = Time.parse("2016-05-13")
        simulation.time_units = "days"
        simulation.time_scale = 1
        simulation.increment

        expect(simulation.current_frame.time).to eq Time.parse("2016-05-14")
      end
    end
  end

  describe "Class Methods" do
    describe "#execute(settings, &block)" do
      it "raises ArgumentError if the settings are not valid" do
        expect { Bodhi::Simulator.execute(iterations: -1) }.to raise_error(ArgumentError, "Invalid settings: [\"starts_at is required\", \"iterations must be greater than or equal to 1\", \"time_units is required\"]")
      end

      it "yields the :current_frame object to the &block" do
        expect { |block| Bodhi::Simulator.execute(starts_at: "2016-05-10", iterations: 1, time_units: "days", time_scale: 1, &block) }.to yield_successive_args(Bodhi::SimulationFrame)
      end

      it "yields the :current_frame object for each iteration" do
        expect { |block| Bodhi::Simulator.execute(starts_at: "2016-05-10", iterations: 100, time_units: "days", time_scale: 1, &block) }.to yield_control.exactly(100).times
      end
    end
  end
end