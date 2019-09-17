require "kemal"
require "case_class"
require "uuid"
require "uuid/json"
require "./gst/store"
require "./gst/validation"
require "./gst/bus"
require "./gst/ws"
require "./gst/gs"
require "./gst/job"
require "./gst/tasks/cleaner"
require "./gst/tasks/compressor"
require "./gst/tasks/publisher"

WORKERS = 2 # TODO: read from config
DOCUMENT_TTL = 60.seconds # TODO: read from config
UPLOADS_FOLDER = ::File.join [Kemal.config.public_folder, "uploads/"]
COMPRESSED_FOLDER = ::File.join [Kemal.config.public_folder, "compressed/"]
ActiveJobs = {} of UUID => Job

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
    ActiveJobs[job_id] = Job.new(job_id, dpi: dpi, color: color)
    Store.store_file(job_id, part)
    Bus.enqueue(job_id)
    env.response.status_code = 201
    {"job_id": job_id, "status": JobStatus::Uploaded.to_s}.to_json
  end
end

get "/compressed/:filename" do |env|
  filename = env.params.url["filename"]
  path = ::File.join [COMPRESSED_FOLDER, "#{filename}.pdf"]
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

ws "/:id" do |socket, context|
  id = UUID.new(context.ws_route_lookup.params["id"])
  WS.init(id, socket, ActiveJobs)
end

# Compressor task
WORKERS.times do |worker_id|
  spawn do
    loop do
      Compressor.run(UPLOADS_FOLDER, COMPRESSED_FOLDER, ActiveJobs)
    end
  end
end

# Cleaner task
spawn do
  loop do
    sleep DOCUMENT_TTL/2
    [UPLOADS_FOLDER, COMPRESSED_FOLDER].each { |folder|
      Cleaner.run(folder, DOCUMENT_TTL)
    }
  end
end

# Publisher task
spawn do
  loop do
    Publisher.run(COMPRESSED_FOLDER)
  end
end

Kemal.run