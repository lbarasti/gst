require "crometheus"
require "../messages/metrics"

module MetricsReporter
  @@heartbeats : Crometheus::Metric::LabeledMetric(NamedTuple(fiber_id: String), Crometheus::Counter) = Crometheus::Counter[:fiber_id].new(
    :heartbeats,
    "Fibers' heartbeats")
  
  def self.run
    case msg = Bus.receive_metric
    when Heartbeat
      @@heartbeats[fiber_id: msg.fiber_id].inc
    end
  end
end