require 'spec_helper'

describe Bodhi::Simulation::NormalDistribution do
  describe "Instance Methods" do
    describe ".calculate(x)" do
      it "returns the +y+ value based on the +x+ independant variable" do
        distribution = Bodhi::Simulation::NormalDistribution.new(curves: [{ mean: 0, std_dev: 1, scale: 1.0 }])
        expect(distribution.calculate(0).round(3)).to eq 0.399
      end
    end
  end

  describe "Class Methods" do
    describe "#randomize(curves)" do
      it "returns a Bodhi::Simulation::NormalDistribution with randomized +curves+" do
        randomized_distribution = Bodhi::Simulation::NormalDistribution.randomize([{ mean_range: [4.5,5.5], std_dev_range: [1, 2], scale: 1.0 }])
        expect(randomized_distribution.curves[0].mean).to be_between(4.5,5.5)
        expect(randomized_distribution.curves[0].std_dev).to be_between(1,2)
      end

      it "raises ArgumentError if +curves+ is not an Array" do
        expect{ Bodhi::Simulation::NormalDistribution.randomize({ mean_range: [1,2], std_dev_range: [1, 2], scale: 1.0 }) }.to raise_error(ArgumentError, "+curves+ must be an Array")
      end

      it "raises ArgumentError if a +curve+ in +curves+ is not valid" do
        expect{ Bodhi::Simulation::NormalDistribution.randomize([1,2,3]) }.to raise_error(ArgumentError, "The value: 1 is not a valid Bodhi::Simulation::NormalDistributionCurve.  Error: undefined method `reduce' for 1:Fixnum")
      end
    end
  end
end