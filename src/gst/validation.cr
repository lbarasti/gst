dataclass FileTooBig{size : UInt64} < Kemal::Exceptions::CustomException
dataclass ParseFailure{exception : Exception} < Kemal::Exceptions::CustomException
dataclass TooManyActiveJobs{active_jobs : Int32} < Kemal::Exceptions::CustomException
dataclass InvalidParameter{param : String, value : String} < Kemal::Exceptions::CustomException

CustomExceptionHandler = ->(env : HTTP::Server::Context, ex : Exception) {
  message = case ex
  when FileTooBig
    "Exceeded PDF max-size: #{Validate::BytesMax}b"
  when ParseFailure
    "#{ex.exception.message || "Unable to parse attachment"}"
  when InvalidParameter
    "Invalid value for parameter #{ex.param}: #{ex.value}"
  when TooManyActiveJobs
    "There are currently too many active jobs. Please, try again later"
  else
    raise ex
  end
  
  env.response.output << {"error": message}.to_json
  env.response.close
}

module Validate
  BytesInMb = 1048576_u64 # 2 ^ 20
  BytesInKb = 1024_u64 # 2 ^ 10
  BytesMax = Config.load.max_file_size_mb * BytesInMb
  FileField = "pdf"
  MaxActiveJobs = Config.load.max_active_jobs

  ContentLength = -> (env : HTTP::Server::Context) {
    content_length = env.request.content_length.as(UInt64)
    log "content-length: #{content_length / BytesInKb}KB pdf"
    env.response.content_type = "application/json"
    if content_length > BytesMax
      env.response.status_code = 400
      raise FileTooBig.new(content_length)
    end
  }

  # raise an exception if there are too many jobs running
  CurrentLoad = -> (env : HTTP::Server::Context) {
    env.response.content_type = "application/json"
    active_jobs = Store.active_jobs(Config.load.compressed_folder).size
    log "active-jobs: #{active_jobs}"
    if active_jobs >= MaxActiveJobs
      env.response.status_code = 503
      raise TooManyActiveJobs.new(active_jobs)
    end
  }

  def self.multipart(env : HTTP::Server::Context, &f : HTTP::FormData::Part -> String)
    HTTP::FormData.parse(env.request) do |file| # HTTP::FormData::Part
      env.response.output << f.call(file)
    end
  rescue ex : Exception
    case ex
    when HTTP::FormData::Error | MIME::Multipart::Error
      env.response.status_code = 400
      raise ParseFailure.new(ex)
    else
      env.response.status_code = 500
      {"error": "Unable to decode attached file"}.to_json
    end
  end

  # validate query string parameter against type
  def self.query_string(env, var, typ)
    param = env.params.query[var]?
    if param.nil?
      invalid_param(env, var, "<absent>")
    else
      value = typ.from_string(param)
      if value.nil?
        invalid_param(env, var, param)
      else value
      end
    end
  end

  private def self.invalid_param(env, param, message)
    env.response.status_code = 400
    raise InvalidParameter.new(param, message)
  end
end
