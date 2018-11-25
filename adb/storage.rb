load 'adb/config.rb'

module Adb
  class Storage
    attr_reader :config, :device_folder
    def initialize(config, folder:)
      @config = config
      @device_folder = config.folders[folder]
    end

    def rm(file)
      puts "DELETING #{file}"
      `adb shell rm #{device_folder}/#{file}`
    end

    def download(file, local_dir)
      puts "COPYING #{file}"
      `adb pull "#{device_folder}/#{file}" #{local_dir}/`
    end

    def ls
      @ls ||= `adb shell ls #{device_folder}`.split("\n")
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

    class << self
      def connect(folder: 'camera')
        device = connected_device_ids.first
        raise 'No connected device found' unless device

        new(Adb::Config.for_device_id(device), folder: folder)
      end

      def connected_device_ids
        `adb devices`
          .split("\n")[1..-1]
          .map { |d| d.split("\t") }
          .select { |id, state| state == 'device' }
          .map(&:first)
      end

      def connected?(device_id)
        devices.include? device_id
      end
    end
  end
end
