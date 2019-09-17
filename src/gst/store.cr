module Store
  def self.store_file(job_id : UUID, file : HTTP::FormData::Part) : UUID
    _ = file.filename # discarding the file name
    filename = job_id
    file_path = ::File.join [UPLOADS_FOLDER, filename]
    File.open(file_path, "w") do |f|
      IO.copy(file.body, f)
    end
    return filename
  end
end