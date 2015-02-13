module Serfx
  # This class wraps the low level msgpack data transformation and tcp
  # communication for the RPC session. methods in this module are used to
  # implement the actual RPC commands available via [Commands]
  class Connection
    MAX_MESSAGE_SIZE = 1024
    COMMANDS = {
      handshake:        [:header],
      auth:             [:header],
      event:            [:header],
      force_leave:      [:header],
      join:             [:header, :body],
      members:          [:header, :body],
      members_filtered: [:header, :body],
      tags:             [:header],
      stream:           [:header],
      monitor:          [:header],
      stop:             [:header],
      leave:            [:header],
      query:            [:header],
      respond:          [:header],
      install_key:      [:header, :body],
      use_key:          [:header, :body],
      remove_key:       [:header, :body],
      list_keys:        [:header, :body],
      stats:            [:header, :body]
    }

    include Serfx::Commands

    attr_reader :host, :port, :seq

    def close
      @socket.close
    end

    def closed?
      @socket.closed?
    end

    # @param  opts [Hash] Specify the RPC connection details
    # @option opts [Symbol] :host ipaddreess of the target serf agent
    # @option opts [Symbol] :port port of target serf agents RPC
    # @option opts [Symbol] :authkey encryption key for RPC communication
    def initialize(opts = {})
      @host = opts[:host] || '127.0.0.1'
      @port = opts[:port] || 7373
      @seq = 0
      @authkey = opts[:authkey]
      @requests = {}
      @responses = {}
    end

    # creates a tcp socket if does not exist already, against RPC host/port
    #
    # @return [TCPSocket]
    def socket
      @socket ||= TCPSocket.new(host, port)
    end

    # creates a MsgPack un-packer object from the tcp socket unless its
    # already present
    #
    # @return [MessagePack::Unpacker]
    def unpacker
      #buf = socket.read
      #p "Buf - #{buf.inspect}"
      @unpacker ||= MessagePack::Unpacker.new(socket)
    end

    # read data from tcp socket and pipe it through msgpack unpacker for
    # deserialization
    #
    # @return [Hash]
    def read_data
      p "1===="
      p buf = socket.recv(MAX_MESSAGE_SIZE, Socket::MSG_PEEK)
      p "2===="
      #if not socket.recv(MAX_MESSAGE_SIZE, Socket::MSG_PEEK).empty?
        #buf = socket.recv(MAX_MESSAGE_SIZE)
      #end
      p "3===="
      first_packet, second_packet = buf.split("\x85")

      if second_packet.nil?
        [MessagePack.unpack(first_packet), nil]
      else
        [MessagePack.unpack(first_packet), MessagePack.unpack("\x85" + second_packet)]
      end
    end

    # takes raw RPC command name and an optional request body
    # and convert them to msgpack encoded data and then send
    # over tcp
    #
    # @param command [String] RPC command name
    # @param body [Hash] request body of the RPC command
    #
    # @return [Integer]
    def tcp_send(command, body = nil)
      @seq += 1
      header = {
        'Command' => command.to_s.gsub('_', '-'),
        'Seq' => seq
      }
      #Log.info("#{__method__}|Header: #{header.inspect}")
      buff = MessagePack::Packer.new
      buff.write(header)
      buff.write(body) unless body.nil?
      res = socket.send(buff.to_str, 0)
      #Log.info("#{__method__}|Res: #{res.inspect}")
      @requests[seq] = { header: header, ack?: false }
      seq
    end

    # checks if the RPC response header has `error` field popular or not
    # raises [RPCError] exception if error string is not empty
    #
    # @param header [Hash] RPC response header as hash
    def check_rpc_error!(header)
      raise RPCError, header['Error'] unless header['Error'].empty?
    end

    # read data from the tcp socket. and convert it to a [Response] object
    #
    # @param command [String] RPC command name for which response will be read
    # @return [Response]
    def read_response(command)
      header, body = read_data
      check_rpc_error!(header)
      puts "Before Response.new"
      if COMMANDS[command].include?(:body)
        r = Response.new(header, body)
        p r
        r
      else
        Response.new(header)
      end
    end

    # make an RPC request against the serf agent
    #
    # @param command [String] name of the RPC command
    # @param body [Hash] an optional request body for the RPC command
    # @return [Response]
    def request(command, body = nil)
      tcp_send(command, body)
      read_response(command)
    end
  end
end
