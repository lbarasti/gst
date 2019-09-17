# Deletes files that passed their time-to-live
module Cleaner
  def self.run(folder, ttl)
    threshold = Time.utc - ttl
    log "Deleting files in #{folder} created before #{threshold}"
    Dir.entries(folder)
      .reject(&.starts_with?("."))
      .map { |filename| ::File.join(folder, filename) }
      .map { |file_path|
        last_modified = File.info(file_path).modification_time
        {file_path, last_modified}
      }
      .select { |_, modified|
        modified < threshold
      }
      .each { |file_path, _|
        log "Deleting #{file_path}"
        File.delete(file_path)
      }
  end
end