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
  completions = folders + ['quit']

  Readline.completion_proc = proc do |input|
    completions.select { |name| name.start_with?(input) }
  end

  loop do
    puts "Which folder to download from ? (quit or one of #{folders.join(', ')})"
    folder = Readline.readline('> ', false).strip
    return folder if completions.include?(folder)

    puts "Not a valid folder: [#{folder}]"
  end
end

def folders
  @folders ||= current_config.folders.keys
end

loop do
  folder = choose_folder
  break if folder == 'quit'

  adb = Adb::Storage.new(current_config, folder: folder)
  downloader = Adb::Download.new(adb)
  downloader.download_media(current_config.folders[folder]['destination'])
end
