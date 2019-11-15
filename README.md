# Tang Nano design for M5Stack

## 概要

M5StackからTang NanoをI2C経由で制御するためのTang Nanoのデザイン

## 機能

今のところ、Tang NanoのカラーLEDの点灯・消灯をI2Cから設定する機能のみ

I2Cのデバイスアドレスは `7'h48`

GW1N-1の45番ピンがSCL、44番ピンがSDA

I2Cのレジスタ・マップは次の通り

| オフセット | アクセス | 内容 |
|:---|:---|:---|
| 0x00 | RO | デバイスID。0xa5固定 |
| 0x01 | RW | LEDの点灯・消灯。 bit0:R, bit1:G, bit2:B。対応するビットが1の色が点灯する |

## モジュール

### i2c_slave.v

よくあるレジスタ・アクセス用のI2CプロトコルでFPGA内部のレジスタにアクセスするためのコア

