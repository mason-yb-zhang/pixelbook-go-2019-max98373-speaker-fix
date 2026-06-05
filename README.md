# Pixelbook Go 2019 MAX98373 扬声器修复

## 问题描述

Pixelbook Go 2019 安装 Fedora Linux 后，内置扬声器（MAX98373 芯片）没有声音输出。耳机孔工作正常，系统音量控制显示正常，但无法从内置扬声器播放音频。

## 根本原因

MAX98373 芯片的 `DSP Volume` 控制项默认值为 **0**，导致音频信号被完全静音。这是该芯片在 Linux 下的常见问题，特别是在从 ChromeOS 迁移到标准 Linux 发行版时。

## 环境信息

- **设备**: Google Pixelbook Go 2019
- **操作系统**: Fedora Linux
- **音频服务器**: PipeWire + WirePlumber
- **音频芯片**: MAX98373 (AVS I2S)
- **驱动**: snd_soc_avs_max98373

## 快速修复

```bash
bash fix-speaker.sh
```

## 手动修复步骤

### 1. 设置 ALSA 控制项

```bash
# DSP Volume（主音量，默认为 0 导致静音）
amixer -c 0 cset numid=121 1073741823

# 扬声器音量
amixer -c 0 cset numid=71 10   # Left Speaker Volume
amixer -c 0 cset numid=12 10   # Right Speaker Volume

# 数字音量选择开关
amixer -c 0 cset numid=60 on   # Left Digital Vol Sel Switch
amixer -c 0 cset numid=1 on    # Right Digital Vol Sel Switch

# 扬声器开关
amixer -c 0 cset numid=119 on  # Left Spk Switch
amixer -c 0 cset numid=120 on  # Right Spk Switch
```

### 2. 保存 ALSA 状态

```bash
alsactl -f ~/.asound.state store
```

### 3. 安装 WirePlumber 配置

将 `wireplumber-max98373.conf` 复制到：
```bash
mkdir -p ~/.config/wireplumber/wireplumber.conf.d/
cp wireplumber-max98373.conf ~/.config/wireplumber/wireplumber.conf.d/50-max98373.conf
```

此配置解决以下问题：
- 禁用 split PCM，避免设备路径错误
- 禁用 ACP（ALSA Configuration Profile），使用直接硬件访问
- 强制设置正确的音频参数（2通道，48000Hz）

### 4. 重启 PipeWire

```bash
systemctl --user restart pipewire wireplumber
```

## 关键控制项说明

| numid | 名称 | 功能 | 推荐值 |
|-------|------|------|--------|
| 121 | DSP Volume | 数字信号处理后的主音量 | 1073741823 (最大) |
| 71 | Left Speaker Volume | 左扬声器增益 | 10 (最大) |
| 12 | Right Speaker Volume | 右扬声器增益 | 10 (最大) |
| 60 | Left Digital Vol Sel Switch | 左声道数字音量选择 | on |
| 1 | Right Digital Vol Sel Switch | 右声道数字音量选择 | on |
| 119 | Left Spk Switch | 左扬声器开关 | on |
| 120 | Right Spk Switch | 右扬声器开关 | on |

## 验证修复

```bash
# 检查 DSP Volume
amixer -c 0 cget numid=121

# 测试播放
speaker-test -c 2 -t sine -f 1000
```

## 持久化

修复脚本会自动保存 ALSA 状态到 `~/.asound.state`。系统重启后，PipeWire 会读取该状态恢复音量设置。

如需系统级持久化（所有用户），可将 `asound.state` 复制到 `/var/lib/alsa/asound.state` 并运行 `sudo alsactl store`。

## 参考

- [Bilibili 原文](https://www.bilibili.com/opus/1183962508913803272) - openclaw 的排查记录
- [OpenGMAxCodec GitHub](https://github.com/chrultrabook/opengmaxcodec) - Chromebook 音频驱动项目
