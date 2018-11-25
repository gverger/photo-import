require 'yaml'

module Adb
  class Config
    attr_reader :device_id, :name, :human_id, :folders
    def initialize(device_id, config)
      @device_id = device_id
      @name = config['name']
      @human_id = config['human_id']
      @folders = config['folders']
    end

    class << self
      def for_human_id(human_id)
        device_id, config = all['devices'].find { |_key, device| device['human_id'] == human_id }
        new(device_id, config) if device_id
      end

      def for_device_id(device_id)
        config = all['devices'][device_id]
        new(device_id, config) if config
      end

      def all
        YAML.load_file('config/adb.yml')
      end
    end
  end
end
