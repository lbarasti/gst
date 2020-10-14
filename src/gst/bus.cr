require "uuid"
require "diagnostic_logger"
require "./messages/*"

module Bus
  @@logger = DiagnosticLogger.new({{@type.stringify}})
  JobQueue = Channel(Job).new
  ReadyQueue = Channel(UUID).new
  FailedQueue = Channel(UUID).new
  MetricsQueue = Channel(Heartbeat).new
  def self.enqueue(job : Job)
    JobQueue.send(job)
  end
  def self.dequeue() : Job
    JobQueue.receive.tap { |job|
      WS.status_update(job.job_id, JobStatus::Compressing)
      @@logger.info "Processing job #{job.job_id}"
    }
  end
  def self.notify_ready(filename : UUID)
    ReadyQueue.send(filename)
    WS.status_update(filename, JobStatus::Publishing)
    @@logger.info "Converted #{filename}"
  end
  def self.check_ready() : UUID
    ReadyQueue.receive.tap { |filename|
      @@logger.info "Publishing job #{filename}"
    }
  end
  def self.notify_failed(filename : UUID)
    FailedQueue.send(filename)
    WS.status_update(filename, JobStatus::Failed)
    @@logger.info "Failed #{filename}"
  end
  def self.notify_published(filename : UUID, file_size)
    WS.status_update(filename, JobStatus::Done, file_size)
    @@logger.info "Finished job #{filename}"
  end
  def self.receive_metric
    MetricsQueue.receive
  end
  def self.heartbeat
    MetricsQueue.send Heartbeat.new
  end
end