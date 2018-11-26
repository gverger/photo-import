module Adb
  class Connection
    class << self
      def connected_device_ids
        `adb devices`
          .split("\n")[1..-1]
          .map { |d| d.split("\t") }
          .select { |_id, state| state == 'device' }
          .map(&:first)
      end
    end
  end
end
