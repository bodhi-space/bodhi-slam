module Bodhi
  module Simulation
    class NormalDistributionCurve
      include Bodhi::Properties
      include Bodhi::Validations

      property :mean, type: Float
      property :mean_range, type: Float, multi: true

      property :std_dev, type: Float
      property :std_dev_range, type: Float, multi: true

      property :scale, type: Float
      property :title, type: String

      validates :mean, required: true
      validates :std_dev, required: true, min: 0.0001
      validates :scale, required: true, min: 0.0, max: 1.0
    end

    class NormalDistribution
      include Bodhi::Properties
      include Bodhi::Validations

      GAUSSIAN_FUNCTION = lambda{|x,u,o,s| 1/Math.sqrt(2*Math::PI*(o**2)) * Math.exp(-((x-u)**2)/(2*(o**2))) * s }

      property :curves, type: Bodhi::Simulation::NormalDistributionCurve, multi: true
      validates :curves, required: true

      # ================
      # Class Methods
      # ================

      # Accepts an array of Bodhi::Simulation::NormalDistribution::Curves objects
      # Randomizes the +mean+ and +std_dev+ properties based on the given
      # +mean_range+ and +std_dev_range+ properties
      # Returns a new Bodhi::Simulation::NormalDistribution object with the randomized properties
      #
      #   curves = [{mean_range: [45.4, 50.0], std_dev_range: [1.2, 2.2], scale: 0.2, title: "Dinner rush"}]
      #
      #   Bodhi::Simulation::NormalDistribution.randomize(curves)
      #     #=> #<Bodhi::Simulation::NormalDistribution @mean=47.1234 @std_dev=1.7543 @mean_range=[45.4, 50.0] @std_dev_range=[1.2, 2.2] @scale=0.2 @title="Dinner rush">
      #
      def self.randomize(curves)
        unless curves.is_a?(Array)
          raise ArgumentError.new("+curves+ must be an Array")
        end

        randomized_curves = curves.collect do |curve|
          # Coerce the given +curve+ into a Bodhi::Simulation::NormalDistributionCurve
          unless curve.is_a?(Bodhi::Simulation::NormalDistributionCurve)
            begin
              curve = Bodhi::Simulation::NormalDistributionCurve.new(curve)
            rescue Exception => e
              raise ArgumentError.new("The value: #{curve} is not a valid Bodhi::Simulation::NormalDistributionCurve object.  Error: #{e}")
            end
          end

          # Check if the user supplied a range for mean and std_dev values
          # These are optional properies, but a required for randomizing a curve
          if curve.mean_range.nil? || curve.std_dev_range.nil?
            raise ArgumentError.new("Unable to randomize the curve: #{curve.to_json}. Reason: missing mandatory +mean_range+ OR +std_dev_range+ properties.")
          end

          # Calculate a random mean and standard deviation
          random_mean = rand(curve.mean_range[0]..curve.mean_range[1])
          random_std_dev = rand(curve.std_dev_range[0]..curve.std_dev_range[1])

          # Create a new randomized curve object
          randomized_curve = curve.clone
          randomized_curve.mean = random_mean
          randomized_curve.std_dev = random_std_dev

          # Check if the randomized curve is valid
          if randomized_curve.invalid?
            raise ArgumentError.new("Invalid Bodhi::Simulation::NormalDistributionCurve.  Reasons: #{randomized_curve.errors.to_a}")
          end

          # return the randomized curve
          randomized_curve
        end

        # Return a new NormalDistribution with the randomized curves
        Bodhi::Simulation::NormalDistribution.new(curves: randomized_curves)
      end

      # ================
      # Instance Methods
      # ================

      # Evaluates the value of +y+ at position +x+
      # Raises ArgumentError if +x+ is not a Float or Integer
      def calculate(x)
        unless x.is_a?(Integer) || x.is_a?(Float)
          raise ArgumentError.new("Expected Integer or Float but recieved: #{x.class}")
        end

        curves.collect{ |curve| GAUSSIAN_FUNCTION.call(x, curve.mean, curve.std_dev, curve.scale) }.reduce(:+)
      end

    end
  end
end