# センサー接続テストコード

ラズベリーパイと各種センサーを、Rubyを使って制御するテストコード


## ラズベリーパイの準備

### ハードウェア

本体と、ラズパイ用 Grove Base Hat for Raspberry Pi (https://www.seeedstudio.com/Grove-Base-Hat-for-Raspberry-Pi.html) 等を用意する。

もしくは、このようなパッチケーブル (https://www.seeedstudio.com/Grove-4-pin-Female-Jumper-to-Grove-4-pin-Conversion-Cable-5-PCs-per-PAck.html) を使って接続する。


### OSの設定

1. raspi-config コマンドで、I2Cを有効にする。
2. Rubyのインストール。

```
sudo apt install ruby
sudo gem install i2c
```
