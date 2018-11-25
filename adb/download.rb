require 'tty-progressbar'
require 'fileutils'

module Adb
  class Download
    attr_reader :storage
    def initialize(storage)
      @storage = storage
    end

    def download_media(dest_folder)
      FileUtils.mkdir_p(dest_folder)
      bar = TTY::ProgressBar.new("Copying #{filenames.size} files to #{dest_folder} [:bar]", total: filenames.size)
      filenames.each do |filename|
        storage.download(filename, dest_folder) unless File.exist?("#{dest_folder}/#{filename}")
        bar.advance
      end
    end

    def filenames
      @filenames = storage.videos + storage.images
    end
  end
end
