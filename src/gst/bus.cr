require "uuid"

module Bus
  JobQueue = Channel(Job).new
  ReadyQueue = Channel(UUID).new
  FailedQueue = Channel(UUID).new
  def self.enqueue(job : Job)
    JobQueue.send(job)
  end
  def self.dequeue() : Job
    JobQueue.receive.tap { |job|
      WS.status_update(job.job_id, JobStatus::Compressing)
      log "Processing job #{job.job_id}"
    }
  end
  def self.notify_ready(filename : UUID)
    ReadyQueue.send(filename)
    WS.status_update(filename, JobStatus::Publishing)
    log "Converted #{filename}"
  end
  def self.check_ready() : UUID
    ReadyQueue.receive.tap { |filename|
      log "Publishing job #{filename}"
    }
  end
  def self.notify_failed(filename : UUID)
    FailedQueue.send(filename)
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