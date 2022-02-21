#!/usr/bin/env ruby
# coding: utf-8
#
#  TCP to UART bridge
#
#  Copyright (C) 2022 Shimane IT Open-Innovation Center.
#
#  This file is distributed under BSD 3-Clause License.
#

require "optparse"
require "io/console"
require "serialport"    # see https://rubygems.org/gems/serialport
require "al_worker_fd"
require "al_worker_tcp"
require "al_worker_message"

TERMINATE_SEQUENCE = "\x03\x03\x03"     # ターミナルモード終了キーシーケンス

##
# TCP server class
#
class TCP_Server < AlWorker::Tcp

  ##
  # (override) start service.
  #
  def start_service(sock)
    th = Thread.new {
      begin
        @me.message.attach()
        while true
          sock.write @me.message.receive()
        end

      ensure
        @me.message.detach()
      end
    }

    while (data = sock.readpartial(100) rescue nil)
      @me.fd_uart.file.write( data )
    end
    th.kill
  end
end


##
# main worker class
#
class TCP2UART_Server < AlWorker

  attr_accessor :node
  attr_accessor :baudrate
  attr_accessor :parity
  attr_accessor :data_bits
  attr_accessor :stop_bits
  attr_accessor :replace_map
  attr_accessor :tcp_port_no
  attr_accessor :mode_terminal
  attr_accessor :mode_tcp
  attr_reader :message
  attr_reader :fd_uart

  ##
  # constructor
  #
  def initialize()
    super("tcp_uart")

    # set default values.
    @node = "/dev/serial0"
    @baudrate = 9600
    @parity = "none"
    @data_bits = 8
    @stop_bits = 1
    @replace_map = "rnrn"
    @tcp_port_no = 10023
    @mode_tcp = nil
    @mode_terminal = nil
  end


  ##
  # initializer
  #
  def initialize2()
    log.level = Logger::DEBUG
    @message = BroadcastMessage.new()

    # 改行変換マップ生成
    map = {"x"=>"", "r"=>"\r", "n"=>"\n", "t"=>"\r\n"}
    @replace_map_u2t = {"\r" => map[@replace_map[0]],
                        "\n" => map[@replace_map[1]]}
    @replace_map_t2u = {"\r" => map[@replace_map[2]],
                        "\n" => map[@replace_map[3]]}

    # UARTディスクリプタの準備
    parity = {"none"=>SerialPort::NONE, "even"=>SerialPort::EVEN, "odd"=>SerialPort::ODD}
    @fd_uart = Fd.new( SerialPort.new(@node, @baudrate, @data_bits, @stop_bits, parity[@parity]))

    # read可能になった時の処理
    @fd_uart.ready_read() {
      data = @fd_uart.file.read_nonblock(100)
      @message.send( data.gsub(/[\r\n]/, @replace_map_u2t ))
    }

    # TCPモード
    if !@mode_tcp && !@mode_terminal
      @mode_tcp = true
    end
    if @mode_tcp
      @tcp = TCP_Server.new("<any>", @tcp_port_no)
      @tcp.run(self)
    end

    # ターミナルモード
    if @mode_terminal
      terminal_mode()
    end
  end


  ##
  # setup terminal mode
  #
  def terminal_mode()
    puts "<<< TERMINAL MODE >>>"
    $stdin.raw!
    at_exit { $stdin.cooked! }
    @stdin = Fd.new( $stdin )
    @termseq_i = 0

    # read可能になった時の処理
    @stdin.ready_read() {
      data = $stdin.read_nonblock(100)

      if TERMINATE_SEQUENCE[ @termseq_i ] == data
        @termseq_i += 1
        if TERMINATE_SEQUENCE.size == @termseq_i
          exit
        end

      elsif @termseq_i == 0
        @fd_uart.file.write( data.gsub(/[\r\n]/, @replace_map_t2u ))

      else
        @fd_uart.file.write( (TERMINATE_SEQUENCE[0,@termseq_i] + data).gsub(/[\r\n]/, @replace_map_t2u ))
        @termseq_i = 0
      end
    }

    # writeの処理
    th = Thread.new {
      begin
        @message.attach()
        while true
          $stdout.write( @message.receive())
        end

      ensure
        @message.detach()
      end
    }
  end
end


##
# main
#
server = TCP2UART_Server.new()
opt = OptionParser.new
server.append_default_option_to( opt )

opt.on("--node=node", "serial device node") {|v|
  server.node = v
}
opt.on("--baud=baudrate", "baud rate.") {|v|
  server.baudrate = v.to_i
}
opt.on("--parity=even or odd", "parity. even or odd.") {|v|
  server.parity = v
}
opt.on("--data=7 or 8", "data bits.") {|v|
  server.data_bits = v.to_i
}
opt.on("--stop=1 or 2", "stop bits.") {|v|
  server.stop_bits = v.to_i
}
opt.on("--replace=rnrn", "CR LF mapping.") {|v|
  if /^[xrnt]{4}$/ =~ v
    server.replace_map = v
  else
    puts "Illegal mapping char #{v.inspect}."
    exit
  end
}
opt.on("--port=port", "TCP port number.") {|v|
  server.tcp_port_no = v.to_i
}
opt.on("--tcp", "UART to TCP/IP bridge mode (default).") {|v|
  server.mode_tcp = v
}
opt.on("--terminal", "UART to terminal (this!) mode.") {|v|
  server.mode_terminal = v
}
opt.separator("Replace character default is 'rnrn'.\n order is UART to TCP CR,LF, TCP to UART CR,LF\n character means x:drop, r:CR, n:LF, t:CRLF.")
opt.parse!(ARGV)

if server.mode_terminal
  server.run()
else
  server.daemon()
end
