module Bodhi
  class Simulator
    include Bodhi::Properties
    include Bodhi::Validations

    # Initial conditions
    property :starts_at, type: DateTime
    property :iterations, type: Integer
    property :time_scale, type: String

    # Dynamic attributes
    property :current_iteration, type: Integer, default: 0
    property :current_time, type: DateTime

    # Model validations
    validates :starts_at, required: true
    validates :iterations, required: true, min: 1
    validates :time_scale, required: true

    # ================
    # Class Methods
    # ================

    # Run a new simulation using the given +settings+ and +&block+
    # Yields the +simulation.current_time+ to the user defined +&block+
    # Ignores +current_iteration+ and +current_time+ settings and zero's them before the simulation
    #
    #   Bodhi::Simulator.execute(starts_at: XXXXX, iterations: 10, time_scale: "days") do |current_time|
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

      simulation.current_iteration = 0
      simulation.current_time = simulation.starts_at

      until simulation.complete?
        yield simulation.current_time
        simulation.increment
      end
    end

    # ================
    # Instance Methods
    # ================

    # returns true if the simulation has processed all iterations
    def complete?
      current_iteration == iterations
    end

    # Increments the simulation loop by one iteration
    # Updates +current_time+ to the new time offset
    # Updates +current_iteration+ to the next iteration
    # Iteration count is zero based!
    #
    #   simulation = Bodhi::Simulator.new(starts_at: "2016-05-13", iterations: 2, time_scale: "days")
    #   simulation.increment
    #   simulation #=> #<Bodhi::Simulator @starts_at: "2016-05-13" @iterations: 2, @time_scale: "days", @current_time: "2016-05-14", @current_iteration: 1 >
    #
    def increment
      self.current_iteration += 1
      self.current_time = self.starts_at + (self.current_iteration * 1.send(self.time_scale))
    end
  end
end