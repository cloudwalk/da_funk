class Device
  class ParamsDat
    FILE_NAME = "./main/params.dat"

    include Device::Helper

    class << self
      attr_accessor :file, :apps, :valid, :files
    end

    self.apps = Array.new
    self.files = Array.new

    # To control if there is any app and parse worked
    self.valid = false

    def self.file
      self.setup unless @file
      @file
    end

    def self.setup
      @file = FileDb.new(FILE_NAME)
    end

    def self.exists?
      File.exists?(FILE_NAME)
    end

    def self.ready?
      return unless exists?
      apps.each {|app| return false if app.outdated? } if apps.size > 0
      files.each {|f| return false if f.outdated? } if files.size > 0
      true
    end

    def self.parse_apps
      new_apps = []
      self.file["apps_list"].to_s.gsub("\"", "").split(";").each do |app|
        label, name, type, crc = app.split(",")
        if application = get_app(name)
          application.crc = crc
        else
          application = Device::Application.new(label, name, type, crc)
        end
        new_apps << application
      end
      Device::Application.delete(@apps - new_apps)
      @apps = new_apps
    end

    def self.parse_files
      new_files = []
      self.file["files_list"].to_s.gsub("\"", "").split(";").each do |f|
        name, crc = f.split(",")
        if file_ = get_file(name)
          file_.crc = crc
        else
          file_ = DaFunk::FileParameter.new(name, crc)
        end
        new_files << file_
      end
      Device::Application.delete(@files - new_files)
      @files = new_files
    end

    # TODO Scalone: Change after @bmsatierf change the format
    # For each apps on apps_list We'll have:
    # Today: <label>,<arquivo>,<pages>,<crc>;
    # After: <label>,<arquivo>,<type>,<crc>;
    # Today: "1 - App,pc2_app.posxml,1,E0A0;"
    # After: "1 - App,pc2_app.posxml,posxml,E0A0;"
    # After: "1 - App,pc2_app.zip,ruby,E0A0;"
    def self.parse
      return unless self.setup
      parse_apps
      parse_files

      if (@apps.size >= 1)
        self.valid = true
      else
        self.valid = false
      end
      self.valid
    end

    def self.get_app(name)
      @apps.each {|app| return app if app.original == name }
      nil
    end

    def self.get_file(name)
      @files.each {|file_| return file_ if file_.original == name}
      nil
    end

    def self.download
      if attach
        parse
        ret = try(3) do |attempt|
          Device::Display.clear
          I18n.pt(:downloading_content, :args => ["PARAMS", 1, 1])
          ret = Device::Transaction::Download.request_param_file(FILE_NAME)
          unless check_download_error(ret)
            sleep(2) 
            false
          else
            true
          end
        end
        parse if ret
        ret
      end
    end

    def self.update_apps(force = false)
      self.download if force || ! self.valid
      if self.valid
        size_apps = @apps.size
        @apps.each_with_index do |app, index|
          self.update_app(app, index+1, size_apps)
        end

        size_files = @files.size
        @files.each_with_index do |file_, index|
          self.update_file(file_, index+1, size_files)
        end
      end
    end

    def self.format!
      Device::Application.delete(self.apps)
      DaFunk::FileParameter.delete(self.files)
      File.delete(FILE_NAME) if exists?
      @apps = []
      @files = []
      Dir.entries("./shared/").each do |f|
        begin
          path = "./shared/#{f}"
          File.delete(path) if File.file?(path) && f != Device::Display::MAIN_BMP
        rescue
        end
      end
    end

    def self.update_app(application, index = 1, all = 1, force = false)
      if attach && application
        try(3) do |attempt|
          Device::Display.clear
          I18n.pt(:downloading_content, :args => [I18n.t(:apps), index, all])
          ret = check_download_error(application.download(force))
          sleep(1)
          ret
        end
      end
    end

    def self.update_file(file_parameter, index = 1, all = 1, force = false)
      if attach && file_parameter
        try(3) do |attempt|
          Device::Display.clear
          I18n.pt(:downloading_content, :args => [I18n.t(:files), index, all])
          ret = check_download_error(file_parameter.download(force))
          file_parameter.unzip if ret
          sleep(1)
          ret
        end
      end
    end

    def self.apps
      self.parse unless self.valid
      @apps
    end

    def self.files
      self.parse unless self.valid
      @files
    end

    def self.executable_app
      selected = self.executable_apps
      if selected && selected.size == 1
        selected.first
      end
    end

    def self.executable_apps
      self.apps.select{|app| app.label != "X"}
    end

    def self.application_menu
      options = Hash.new
      executable_apps.each { |app| options[app.label] = app }
      menu("Application Menu", options, {:number => true})
    end
  end
end
