class Device
  class Notification
    DEFAULT_TIMEOUT        = 15
    DEFAULT_INTERVAL       = 10
    DEFAULT_STREAM_TIMEOUT = 0

    class << self
      attr_accessor :callbacks, :current
    end

    self.callbacks = Hash.new

    attr_reader :fiber, :timeout, :interval, :last_check, :stream_timeout

    def self.check
      self.current.check if self.current
    end

    def self.execute(event)
      calls = self.callbacks[event.callback]
      return unless calls
      [:before, :on, :after].each do |moment|
        calls.each{|callback| callback.call(event, moment)}
      end
    end

    def self.schedule(callback)
      self.callbacks[callback.description] ||= []
      self.callbacks[callback.description] << callback
    end

    def self.config
      notification_timeout        = Device::Setting.notification_timeout.empty? ? DEFAULT_TIMEOUT : Device::Setting.notification_timeout.to_i
      notification_interval       = Device::Setting.notification_interval.empty? ? DEFAULT_INTERVAL : Device::Setting.notification_interval.to_i
      notification_stream_timeout = Device::Setting.notification_stream_timeout.empty? ? DEFAULT_STREAM_TIMEOUT : Device::Setting.notification_stream_timeout.to_i
      [notification_timeout, notification_interval, notification_stream_timeout]
    end

    def self.start
      unless Device::Setting.logical_number.empty? || Device::Setting.company_name.empty? || (! Device::Network.connected?)
        unless Device::Notification.current && Device::Notification.current.closed?
          self.new(*self.config)
        end
      end
    end

    def self.setup
      NotificationCallback.new "APP_UPDATE", :on => Proc.new { Device::ParamsDat.update_apps(true) }
      NotificationCallback.new "SETUP_DEVICE_CONFIG", :on => Proc.new { Device::ParamsDat.update_apps(true) }
      NotificationCallback.new "RESET_DEVICE_CONFIG", :on => Proc.new { Device::ParamsDat.format! }

      NotificationCallback.new "SYSTEM_UPDATE", :on => Proc.new { |file| }
      NotificationCallback.new "CANCEL_SYSTEM_UPDATE", :on => Proc.new { }
      NotificationCallback.new "TIMEZONE_UPDATE", :on => Proc.new { Device::Setting.cw_pos_timezone = "" }
    end

    def initialize(timeout = DEFAULT_TIMEOUT, interval = DEFAULT_INTERVAL, stream_timeout = DEFAULT_STREAM_TIMEOUT)
      @timeout        = timeout
      @stream_timeout = stream_timeout
      @interval       = interval
      Device::Notification.current = self
      @fiber = create_fiber
    end

    # Check if there is any notification
    def check
      if @fiber.alive? && valid_interval? && Device::Network.connected?
        if (notification = @fiber.resume)
          Notification.execute(NotificationEvent.new(notification))
        end
        @last_check = Time.now
      end
    end

    # Close socket and finish Fiber execution
    def close
      @fiber.resume "close"
    end

    def closed?
      ! @fiber.alive?
    end

    def valid_interval?
      if @last_check
        (@last_check + self.interval) < Time.now
      else
        true
      end
    end

    private
    def create_fiber
      Fiber.new do
        Serfx.connect(socket_block: socket_callback, timeout: timeout, stream_timeout: stream_timeout) do |conn|
          conn.stream("user:#{Device::Setting.company_name};#{Device::Setting.logical_number}")
        end
        true
      end
    end

    def socket_callback
      Proc.new do
        socket_tcp = Device::Network.create_socket
        socket_tcp.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)

        if Device::Setting.ssl == "1"
          socket = Device::Network.handshake_ssl(socket_tcp)
        else
          socket = socket_tcp
        end
        [socket, socket_tcp]
      end
    end
  end
end

