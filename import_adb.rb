load 'adb/storage.rb'
load 'adb/download.rb'
load 'adb/connection.rb'
require 'readline'

def current_config
  @current_config ||=
    begin
      device_id = Adb::Connection.connected_device_ids.first
      raise 'No connected device' unless device_id

      Adb::Config.for_device_id(device_id)
    end
end

def choose_folder
  Readline.completion_proc = proc do |input|
    completions.select { |name| name.start_with?(input) }
  end

  loop do
    puts "Which folder to download from ? (#{completions.join(', ')})"
    folder = Readline.readline('> ', false).strip
    return folder if completions.include?(folder)

    puts "Not a valid folder: [#{folder}]"
  end
end

def previous_destinations
  @previous_destinations ||= []
end

def choose_destination
  Readline.completion_proc = proc do |input|
    previous_destinations.select { |name| name.start_with?(input) }
  end

  puts 'Which destination to download to ?'
  folder = Readline.readline('> ', false).strip
  previous_destinations << folder
  previous_destinations.uniq!

  folder
end

def completions
  @completions ||= current_config.folders.keys
end

loop do
  adb = Adb::Storage.new(current_config, folder: choose_folder)
  downloader = Adb::Download.new(adb)
  downloader.download_media(choose_destination)
end
