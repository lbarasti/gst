require "uuid"

module Bus
  JobQueue = Channel(UUID).new
  ReadyQueue = Channel(UUID).new
  FailedQueue = Channel(UUID).new
  def self.enqueue(filename : UUID)
    spawn JobQueue.send(filename)
  end
  def self.dequeue() : UUID
    JobQueue.receive.tap { |filename|
      WS.status_update(filename, JobStatus::Compressing)
      log "Processing job #{filename}"
    }
  end
  def self.notify_ready(filename : UUID)
    spawn ReadyQueue.send(filename)
    log "Converted #{filename}"
  end
  def self.check_ready() : UUID
    ReadyQueue.receive.tap { |filename|
      WS.status_update(filename, JobStatus::Publishing)
      log "Publishing job #{filename}"
    }
  end
  def self.notify_failed(filename : UUID)
    spawn FailedQueue.send(filename)
    WS.status_update(filename, JobStatus::Failed)
    log "Failed #{filename}"
  end
  def self.notify_published(filename : UUID, file_size)
    WS.status_update(filename, JobStatus::Done, file_size)
    log "Finished job #{filename}"
  end
  def self.notify_client(filename : UUID, job_status : JobStatus)
    WS.status_update(filename, job_status)
  end
end