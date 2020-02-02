require "yaml"

class Config
  YAML.mapping(
    workers: Int32,
    document_ttl: Int32,
    uploaded_folder: String,
    compressed_folder: String,
    max_active_jobs: Int32,
    max_file_size_mb: UInt64,
    max_ws_connections: Int32,
  )
  
  def self.load(config : String = File.read("config.yml"))
    Config.from_yaml(config)
  end
end