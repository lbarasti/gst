require "yaml"

class Config
  YAML.mapping(
    workers: Int32,
    document_ttl: Int32,
    uploaded_folder: String,
    compressed_folder: String,
  )
  
  def self.load(config : String = File.read("config.yml"))
    Config.from_yaml(config)
  end
end