require "kemal"
require "diagnostic_logger"

class DiagnosticLoggerHandler < Kemal::BaseLogHandler
  def initialize
    @logger = DiagnosticLogger.new("log-middleware")
  end

  def call(context)
    time = Time.utc
    call_next(context)
    elapsed = Time.utc - time

    @logger.info "#{context.request.method} #{context.request.resource} - #{context.response.status_code} (#{elapsed.total_seconds}s)"
  rescue e
    @logger.error "#{context.request.method} #{context.request.resource} - Unhandled exception:"
    @logger.error e.inspect_with_backtrace
    raise e
  end

  def write(message : String)
    @logger.debug(message)
  end

end