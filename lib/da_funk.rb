unless Object.const_defined?(:MTest)
  file_path = File.dirname(File.realpath(__FILE__))
  require file_path + "/file_db.rb"
  require file_path + "/da_funk/helper.rb"
  require file_path + "/da_funk/rake_task.rb"
  require file_path + "/iso8583/bitmap.rb"
  require file_path + "/iso8583/codec.rb"
  require file_path + "/iso8583/exception.rb"
  require file_path + "/iso8583/field.rb"
  require file_path + "/iso8583/fields.rb"
  require file_path + "/iso8583/message.rb"
  require file_path + "/iso8583/util.rb"
  require file_path + "/iso8583/version.rb"
  require file_path + "/iso8583/file_parser.rb"
  require file_path + "/device/version.rb"
  require file_path + "/da_funk/version.rb"
  require file_path + "/da_funk/test.rb"
  require file_path + "/da_funk/screen.rb"
  require file_path + "/da_funk/callback_flow.rb"
  require file_path + "/da_funk/screen_flow.rb"
  #require file_path + "/da_funk/i18n_error.rb"
  #require file_path + "/da_funk/i18n.rb"
  require file_path + "/da_funk/file_parameter.rb"
  require file_path + "/da_funk/helper/status_bar.rb"
  require file_path + "/da_funk/event_listener.rb"
  require file_path + "/da_funk/event_handler.rb"
  require file_path + "/da_funk/engine.rb"
  require file_path + "/da_funk/struct.rb"
  require file_path + "/da_funk/application.rb"
  require file_path + "/da_funk/transaction/iso.rb"
  require file_path + "/da_funk/transaction/download.rb"
  require file_path + "/da_funk/notification_event.rb"
  require file_path + "/da_funk/notification_callback.rb"
  require file_path + "/da_funk/notification.rb"
  require file_path + "/da_funk/params_dat.rb"
  require file_path + "/device.rb"
  require file_path + "/device/audio.rb"
  require file_path + "/device/crypto.rb"
  require file_path + "/device/display.rb"
  require file_path + "/device/io.rb"
  require file_path + "/device/network.rb"
  require file_path + "/device/printer.rb"
  require file_path + "/device/runtime.rb"
  require file_path + "/device/setting.rb"
  require file_path + "/device/support.rb"
  require file_path + "/device/system.rb"
  require file_path + "/device/magnetic.rb"
end

module DaFunk
  def self.setup_command_line
    # TODO Setup the environment to command line
  end
end

