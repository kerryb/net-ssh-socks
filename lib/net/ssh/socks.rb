require 'net/ssh'

module Net
  module SSH
    class Socks
      VERSION = "0.0.2"

      METHOD_NO_AUTH = 0
      CMD_CONNECT    = 1
      REP_SUCCESS    = 0
      RESERVED       = 0
      ATYP_IPV4      = 1
      ATYP_DOMAIN    = 3
      ATYP_IPV6      = 4
      SOCKS4         = 4
      SOCKS4_SUCCESS = [0, 0x5a, 0, 0, 0, 0, 0, 0].pack("C*")
      SOCKS5         = 5

      # client is an open socket
      def initialize(client)
        @client = client
      end

      # Communicates with a client application as described by the SOCKS 5
      # specification: http://tools.ietf.org/html/rfc1928 and
      # http://en.wikipedia.org/wiki/SOCKS
      # returns the host and port requested by the client
      def client_handshake
        version = @client.recv(1).unpack("C*").first
        case version
        when SOCKS4 then client_handshake_v4
        when SOCKS5 then client_handshake_v5
        else
          raise "SOCKS version not supported: #{version.inspect}"
        end
      end

      def client_handshake_v4
        command = @client.recv(1)
        port = @client.recv(2).unpack("n").first
        ip_addr = @client.recv(4).unpack("C*").join('.')
        username = @client.recv(1024) # read the rest of the stream

        @client.send SOCKS4_SUCCESS, 0
        [ip_addr, port]
      end

      def client_handshake_v5
        nmethods, *methods = @client.recv(8).unpack("C*")

        if methods.include?(METHOD_NO_AUTH)
          packet = [SOCKS5, METHOD_NO_AUTH].pack("C*")
          @client.send packet, 0
        else
          @client.close
          raise 'Unsupported authentication method. Only "No Authentication" is supported'
        end

        version, command, reserved, address_type, *destination = @client.recv(256).unpack("C*")

        packet = ([SOCKS5, REP_SUCCESS, RESERVED, address_type] + destination).pack("C*")
        @client.send packet, 0

        remote_host, remote_port = case address_type
        when ATYP_IPV4
          host = destination[0..-3].join('.')
          port = destination[-2..-1].pack('C*').unpack('n')
          [host, port]
        when ATYP_DOMAIN
          @client.close
          raise 'Unsupported address type. Only "IPv4" is supported'
        when ATYP_IPV6
          @client.close
          raise 'Unsupported address type. Only "IPv4" is supported'
        else
          raise "Unknown address_type: #{address_type}"
        end

        [remote_host, remote_port]
      end
    end
  end
end

class Net::SSH::Connection::Session
  def on_close(&block)
    @on_close = block
  end

  alias_method :close_without_callbacks, :close
  def close
    close_without_callbacks
    @on_close.call if @on_close
  end
end

class Net::SSH::Service::Forward
  # Starts listening for connections on the local host, and forwards them
  # to the specified remote host/port via the SSH connection. This method
  # accepts either one or two arguments. When two arguments are given,
  # they are:
  #
  # * the local address to bind to
  # * the local port to listen on
  #
  # If one argument is given, it is as if the local bind address is
  # "127.0.0.1", and the rest are applied as above.
  #
  #   ssh.forward.socks(8080)
  #   ssh.forward.socks("0.0.0.0", 8080)
  def socks(*args)
    if args.length < 1 || args.length > 2
      raise ArgumentError, "expected 1 or 2 parameters, got #{args.length}"
    end

    bind_address = "127.0.0.1"
    bind_address = args.shift if args.first.is_a?(String) && args.first =~ /\D/
    local_port   = args.shift.to_i
    info { "socks on #{bind_address} port #{local_port}" }

    socks_server = TCPServer.new(bind_address, local_port)
    session.listen_to(socks_server) do |server|
      client = server.accept

      socks = Net::SSH::Socks.new(client)
      remote_host, remote_port = socks.client_handshake
      info { "connection requested on #{remote_host} port #{remote_port}" }

      channel = session.open_channel("direct-tcpip", :string, remote_host, :long, remote_port, :string, bind_address, :long, local_port) do |channel|
        info { "direct channel established" }
        prepare_client(client, channel, :local)
      end

      channel.on_open_failed do |ch, code, description|
        error { "could not establish direct channel: #{description} (#{code})" }
        client.close
      end
    end

    session.on_close do
      debug { "cleaning up socks server" }
      socks_server.close
    end
  end
end
