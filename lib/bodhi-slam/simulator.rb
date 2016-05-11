module Bodhi
  class SimulationFrame
    include Bodhi::Properties
    include Bodhi::Validations

    property :iteration, type: Integer, default: 0
    property :time, type: DateTime
  end

  class Simulator
    include Bodhi::Properties
    include Bodhi::Validations

    # Initial conditions
    property :starts_at, type: DateTime
    property :iterations, type: Integer
    property :time_units, type: String
    property :time_scale, type: Integer, default: 1

    # Dynamic attributes
    # Updated every iteration
    property :current_frame, type: SimulationFrame

    # Model validations
    validates :starts_at, required: true
    validates :iterations, required: true, min: 1
    validates :time_units, required: true
    validates :time_scale, min: 1

    # ================
    # Class Methods
    # ================

    # Run a new simulation using the given +settings+ and +&block+
    # Yields the +simulation.current_time+ to the user defined +&block+
    # Ignores +current_frame+ settings and zero's them before the simulation
    #
    #   Bodhi::Simulator.execute(starts_at: "2016-05-10", iterations: 10, time_units: "days") do |current_time|
    #     # do some simulation stuff!
    #   end
    #
    #   # You can even go crazy and do things like:
    #   Bodhi::Simulator.execute(...) do |outer_time|
    #     # do some simulation stuff!
    #     Bodhi::Simulator.execute(...) do |inner_time|
    #       # do a nested simulation!
    #     end
    #     # do more stuff after the netsted simulation...
    #   end
    def self.execute(settings, &block)
      simulation = Bodhi::Simulator.new(settings)

      if simulation.invalid?
        raise ArgumentError.new("Invalid settings: #{simulation.errors.to_a}")
      end

      if simulation.current_frame.nil?
        simulation.current_frame = Bodhi::SimulationFrame.new(iteration: 0, time: simulation.starts_at)
      else
        simulation.current_frame.iteration = 0
        simulation.current_frame.time = simulation.starts_at
      end

      until simulation.complete?
        yield simulation.current_frame.clone
        simulation.increment
      end
    end

    # ================
    # Instance Methods
    # ================

    # returns true if the simulation has processed all iterations
    def complete?
      self.current_frame.iteration == self.iterations
    end

    # Increments the simulation loop by one iteration
    # Updates +current_time+ to the new time offset
    # Updates +current_iteration+ to the next iteration
    #
    #   simulation = Bodhi::Simulator.new(starts_at: "2016-05-13", iterations: 2, time_units: "days")
    #   simulation.increment
    #   simulation #=> #<Bodhi::Simulator @starts_at: "2016-05-13" @iterations: 2, @time_units: "days", @current_time: "2016-05-14", @current_iteration: 1 >
    #
    def increment
      self.current_frame.iteration += 1
      self.current_frame.time = self.starts_at + (self.current_frame.iteration * 1.send(self.time_units) * self.time_scale)
    end
  end
end