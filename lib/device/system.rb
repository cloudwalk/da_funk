
class Device
  class System
    class << self
      attr_reader :serial, :backlight
      attr_accessor :klass
    end

    def self.adapter
      Device.adapter::System
    end

    def self.shutdown
      adapter.shutdown if adapter.respond_to?(:shutdown)
    end

    def self.serial
      @serial ||= adapter.serial
    end

    # Set screen backlight (turn on automatically if there has actions like key-pressing, card-swiping or card-inserting).
    #  0 = Turn off backlight.
    #  1 = (D200): Keep backlight on for 30 seconds ( auto-shut-down after 30 seconds).
    #  1 = (Vx510): On.
    #  2 = (D200): Always on.
    #  n = (Evo/Telium 2): Percentage until 100.
    def self.backlight=(level)
      adapter.backlight = level
      @backlight = level
    end

    def self.backlight
      @backlight ||= adapter.backlight
    end

    # Check if device is connected to any power supply
    #  true Connected
    #  false Not Connected
    def self.power_supply
      adapter.power_supply
    end

    # Read the battery level, return the value in percentage.
    def self.battery
      adapter.battery
    end

    def self.beep
      adapter.beep
    end

    def self.restart
      adapter.reboot
    end

    def self.reboot
      adapter.reboot
    end

    def self.app
      self.klass.to_s.downcase
    end

    def self.model
      adapter.model
    end

    def self.brand
      adapter.brand
    end

    def self.versions
      adapter.versions
    end

    def self.update(path)
      if File.exists? path
        adapter.update(path)
      end
    end
  end
end

