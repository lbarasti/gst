require "uuid"
require "../gs"

dataclass Job {
  job_id : UUID,
  dpi : Int32,
  color : GS::ColorConversionStrategy,
  status : JobStatus = JobStatus::Uploading,
  date : Time = Time.utc()
}

enum JobStatus
  Uploading; Uploaded; Compressing; Publishing; Failed; Done
  def active? : Bool
    !(self === Failed | Done)
  end
end