module Store
  def self.store_file(file_path : String, file : HTTP::FormData::Part)
    File.open(file_path, "w") do |f|
      IO.copy(file.body, f)
    end
  end
  def self.size(folder)
    compressed_disk_space = Dir.children(folder)
      .reduce(0){ |sum, file| sum + File.info(File.join(folder,file)).size }
  end
  def self.active_jobs(folder)
    Dir.glob(folder + "/*.part")
  end
end