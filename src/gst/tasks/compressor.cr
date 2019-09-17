module Compressor
  private def self.cmd(color, dpi, source, target)
    "gs -dNOPAUSE -dBATCH -sDEVICE=pdfwrite \
    -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook \
    -sColorConversionStrategy=#{color} \
    -dGrayImageResolution=#{dpi} -dColorImageResolution=#{dpi} \
    -sOutputFile=#{target}.part #{source}"
  end
  def self.run(source_folder, target_folder, active_jobs)
    filename = Bus.dequeue()
    dpi = active_jobs[filename].dpi
    color = active_jobs[filename].color
    active_jobs[filename] = active_jobs[filename].copy(status: JobStatus::Compressing)

    stdout = cmd(color,
      dpi,
      ::File.join(source_folder, filename.to_s),
      ::File.join(target_folder, filename.to_s)
    ).tap{ |cmd_| `#{cmd_}` } # TODO: switch to Process
    log "exit_status: #{$?.exit_code}"
    if $?.normal_exit?
      Bus.notify_ready(filename)
    else
      Bus.notify_failed(filename)
    end
    active_jobs.delete(filename)
  end
end