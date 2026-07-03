#!/bin/bash
set -e

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [15] 🔊 配置 WirePlumber 音频"

# 仅桌面版需要配置音频
if [[ "$SYSTEM_TYPE" == *"server"* ]]; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [15]   └─ 服务器版跳过音频配置"
    exit 0
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [15]   └─ 创建 WirePlumber 配置目录"
mkdir -p rootdir/etc/wireplumber/wireplumber.conf.d

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [15]   └─ 配置 ALSA 音频参数"
cat > rootdir/etc/wireplumber/wireplumber.conf.d/51-disable-suspension.conf << 'EOF'
monitor.alsa.rules = [
  {
    matches = [
      {
        # Matches all sources
        node.name = "~alsa_input.*"
      },
      {
        # Matches all sinks
        node.name = "~alsa_output.*"
      }
    ]
    actions = {
      update-props = {
        audio.format           = "S16LE"
        audio.rate             = 48000
        api.alsa.period-size   = 4096
        api.alsa.period-num    = 6
        api.alsa.headroom      = 512,
       # session.suspend-timeout-seconds = 0
       # dither.method = "wannamaker3", # add dither of desired shape
       # dither.noise = 2, # add additional bits of noise
     }
    }
  }
]
EOF

echo "[$(date +'%Y-%m-%d %H:%M:%S')] [15] ✅ 音频配置完成"
