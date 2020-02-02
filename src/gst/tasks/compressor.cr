require "diagnostic_logger"

module Compressor
  @@logger = DiagnosticLogger.new({{@type.stringify}})

  private def self.cmd(color, dpi, source, target)
    "gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite \
    -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook \
    -sColorConversionStrategy=#{color} \
    -dGrayImageResolution=#{dpi} -dColorImageResolution=#{dpi} \
    -sOutputFile=#{target}.part #{source}"
  end
  def self.run(source_folder, target_folder)
    filename, dpi, color, _, _ = Bus.dequeue().to_tuple

    compress_cmd = cmd(color,
      dpi,
      ::File.join(source_folder, filename.to_s),
      ::File.join(target_folder, filename.to_s)
    )
    compression_status = Process.new(compress_cmd, shell: true).wait

    @@logger.info "exit_status: #{compression_status.to_s}"

    if compression_status.normal_exit?
      Bus.notify_ready(filename)
    else
      Bus.notify_failed(filename)
    end
  rescue
    Bus.notify_failed(filename) unless filename.nil?
  end
end