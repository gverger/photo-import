load 'adb/config.rb'
require 'shellwords'

module Adb
  class Storage
    attr_reader :config, :device_folder
    def initialize(config, folder:)
      @config = config
      @device_folder = config.folders[folder]['path']
    end

    def rm(file)
      `adb shell rm "#{escaped_path(device_folder, file)}"`
    end

    def download(file, local_dir)
      `adb pull #{escaped_path(device_folder, file)} #{local_dir}/`
    end

    def ls
      @ls ||= `adb shell ls "#{escaped_path(device_folder)}"`.split("\n")
    end

    def videos
      ls.select { |filename| filename.end_with?('.mp4') }
    end

    def images
      ls.select { |filename| filename.end_with?('.jpg') }
    end

    def dirs
      ls.reject { |filename| filename.include?('.') }
    end

    private

    def escaped_path(*path)
      File.join(path).shellescape
    end
  end
end
