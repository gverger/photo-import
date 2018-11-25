class Adb
  attr_reader :config_id, :device_folder
  def initialize(config_id)
    @config_id = config_id
    @device_folder = self.class.configs['devices'][config_id]
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
    def configs
      @configs ||= YAML.load_files('config/adb.yml')
    end
  end
end

class Downloader
  attr_reader :folder, :storage
  def initialize(storage: Adb, folder: 'images')
    @storage = storage
    @folder = folder
  end

  def download(files)
    files.each do |file|
      storage.download(file, folder) if !File.exist?("images/#{file}")
    end
  end

end

class Deleter
  attr_reader :storage
  def initialize(storage: Adb)
    @storage = storage
  end
  def delete(files)
    files.each do |file|
      storage.rm(file) if File.exist?("images/#{file}")
    end
  end
end

def save_filenames
  files = `adb shell ls #{DIR}`
  File.open('files-to-copy.txt', 'w') do |save|
    save.write files
  end
end

# files = File.read('files-to-copy.txt').split("\n")

files = Adb.ls;

images = files.select { |file| file.end_with?('.jpg') }

FileUtils.mkdir_p('images')

def download(files)
  files.each do |file|
    if !File.exist?("images/#{file}")
      puts "COPYING #{file}"
      `adb pull "#{DIR}/#{file}" images/`
    end
  end
end

download(Adb.images);

download(Adb.videos);

def delete(files)
  files.each do |file|
    if File.exist?("images/#{file}")
      puts "DELETING #{file}"
      Adb.rm(file)
    end
  end
end

saved_files = Dir['*', base: 'images/'];

left_images = Adb.images - saved_filesk

delete(saved_files)
