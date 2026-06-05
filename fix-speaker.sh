#!/bin/bash
# Pixelbook Go 2019 MAX98373 扬声器修复脚本
# 参考: https://www.bilibili.com/opus/1183962508913803272

set -e

echo "=========================================="
echo "MAX98373 扬声器修复脚本"
echo "=========================================="

# 检查声卡
echo "[1/4] 检查 MAX98373 声卡..."
if ! amixer -c 0 contents | grep -q "MAX98373"; then
    echo "错误：未找到 MAX98373 声卡"
    exit 1
fi

# 设置 ALSA 控制项
echo "[2/4] 设置 ALSA 控制项..."
amixer -c 0 cset numid=121 1073741823  # DSP Volume
amixer -c 0 cset numid=71 10            # Left Speaker Volume
amixer -c 0 cset numid=12 10            # Right Speaker Volume
amixer -c 0 cset numid=60 on            # Left Digital Vol Sel Switch
amixer -c 0 cset numid=1 on             # Right Digital Vol Sel Switch
amixer -c 0 cset numid=119 on           # Left Spk Switch
amixer -c 0 cset numid=120 on           # Right Spk Switch

# 保存 ALSA 状态
echo "[3/4] 保存 ALSA 状态..."
alsactl -f ~/.asound.state store

# 安装 WirePlumber 配置
echo "[4/4] 安装 WirePlumber 配置..."
mkdir -p ~/.config/wireplumber/wireplumber.conf.d/
cp wireplumber-max98373.conf ~/.config/wireplumber/wireplumber.conf.d/50-max98373.conf

# 重启 PipeWire
systemctl --user restart pipewire wireplumber

echo ""
echo "=========================================="
echo "修复完成！"
echo "=========================================="
echo ""
echo "请测试扬声器："
echo "  speaker-test -c 2 -t sine -f 1000"
