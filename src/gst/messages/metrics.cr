class Heartbeat
  getter fiber_id : String
  def initialize
    @fiber_id = Fiber.current.name || Fiber.current.object_id.to_s(16)
  end
end