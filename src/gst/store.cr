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
  def self.size(folder)
    compressed_disk_space = Dir.children(folder)
      .reduce(0){ |sum, file| sum + File.info(File.join(folder,file)).size }
  end
end