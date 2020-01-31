module Publisher
  def self.run(folder)
    filename = Bus.check_ready()
    File.rename("#{::File.join [folder, filename]}.part", "#{::File.join [folder, filename]}.pdf")
    file_size = File.size("public/compressed/#{filename}.pdf")
    Bus.notify_published(filename, file_size)
  end
end