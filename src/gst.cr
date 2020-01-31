require "kemal"
require "dataclass"
require "uuid"
require "uuid/json"
require "./gst/*"
require "./gst/tasks/*"

cfg = Config.load
workers = cfg.workers # TODO: read from config
document_ttl = cfg.document_ttl.seconds # TODO: read from config
uploaded_folder = cfg.uploaded_folder
compressed_folder = cfg.compressed_folder

[uploaded_folder, compressed_folder].each { |folder|
  Dir.mkdir(folder) unless Dir.exists?(folder)
}

Kemal.config.add_error_handler(400, &CustomExceptionHandler)
Kemal.config.add_error_handler(503, &CustomExceptionHandler)

before_post "/submit", &Validate::CurrentLoad
before_post "/submit", &Validate::ContentLength

post "/submit" do |env|
  dpi = Validate.query_string(env, "dpi", GS::DPI)
  color = Validate.query_string(env, "color", GS::ColorConversionStrategy)
  Validate.multipart(env) do |part| # HTTP::FormData::Part
    next("") unless part.name == Validate::FileField
    job_id = UUID.random
    file_path = ::File.join [uploaded_folder, job_id]
    Store.store_file(file_path, part)
    job = Job.new(job_id, dpi: dpi, color: color)
    Bus.enqueue(job)
    env.response.status_code = 201
    {"job_id": job_id, "status": JobStatus::Uploaded.to_s}.to_json
  end
end

get "/compressed/:filename" do |env|
  filename = env.params.url["filename"]
  path = ::File.join [compressed_folder, "#{filename}.pdf"]
  if File.exists?(path)
    send_file env, path, "application/pdf"
  else
    message = {"error": "File not found"}.to_json
    env.response.content_type = "application/json"
    halt env, status_code: 404, response: message
  end
end

get "/" do |env|
  path = ::File.join [Kemal.config.public_folder, "index.html"]
  send_file env, path, "text/html"
end

get "/info" do |env|
  env.response.content_type = "application/json"
  {
    "compressed_size": Store.size(compressed_folder),
    "uploaded_size": Store.size(uploaded_folder),
    "active_jobs": [] of String, # TODO: get active jobs by scanning compressed_folder for *.part files
    "active_sockets": WS.active_sockets
  }.to_json
end

ws "/:id" do |socket, context|
  id = UUID.new(context.ws_route_lookup.params["id"])
  WS.init(id, socket)
end

# Compressor task
workers.times do |worker_id|
  spawn do
    loop do
      Compressor.run(uploaded_folder, compressed_folder)
    end
  end
end

# Cleaner task
spawn do
  loop do
    sleep document_ttl/2
    [uploaded_folder, compressed_folder].each { |folder|
      Cleaner.run(folder, document_ttl)
    }
  end
end

# Publisher task
spawn do
  loop do
    Publisher.run(compressed_folder)
  end
end

Kemal.run