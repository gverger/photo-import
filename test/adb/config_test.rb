require 'minitest/autorun'
require_relative '../../adb/config'

module Adb
  class ConfigTest < Minitest::Test
    def test_for_device_id
      Config.class_eval do
        def self.all
          {
            'devices' => {
              'dev_id' => {
                'name' => 'ConfigName',
                'human_id' => 'dev-id',
                'folders' => { 'path' => 'destination' }
              },
              'another_id' => { 'name' => 'AnotherOne' }
            }
          }
        end
      end

      config = Config.for_device_id('dev_id')

      assert_equal 'ConfigName', config.name
      assert_equal 'dev-id', config.human_id
      assert_equal({ 'path' => 'destination' }, config.folders)
    end
  end
end
