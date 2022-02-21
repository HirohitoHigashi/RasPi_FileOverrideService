# TCP <-> UART ブリッジ

ラズベリーパイのUARTと、TCPとのブリッジ。

* 実行すると、/dev/serial0 と、TCP/IP 10023 番ポートをブリッジする。
* 別途、Aloneライブラリ http://www.ruby-alone.org が必要。
* ターミナルモードにすると、シリアルターミナルとして動作する。
* CR,LF の相互変換機能がある。

```
Usage: tcp_uart [options]
    -d, --debug                      set debug mode.
    -k, --kill                       kill stay process.
    -r, --restart                    restart process.
    -p, --pid=filename               specify pid filename.
    -l, --log=filename               specify log filename.
    -c, --config=filename            specify configfilename
        --node=node                  serial device node
        --baud=baudrate              baud rate.
        --parity=even or odd         parity. even or odd.
        --data=7 or 8                data bits.
        --stop=1 or 2                stop bits.
        --replace=rnrn               CR LF mapping.
        --port=port                  TCP port number.
        --tcp                        UART to TCP/IP bridge mode (default).
        --terminal                   UART to terminal (this!) mode.
Replace character default is 'rnrn'.
 order is UART to TCP CR,LF, TCP to UART CR,LF
 character means x:drop, r:CR, n:LF, t:CRLF.
```

## 実行

```
ruby -Ialone/lib tcp_uart.rb
```

TCP/IP接続

```
telnet -8 IP 10023
```

これで、ラズベリーパイに接続されたシリアルポートとtelnet間で通信できる。
