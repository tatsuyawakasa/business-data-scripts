#!/bin/bash

# AWS VPN Client で VPN接続を切断するスクリプト

echo "🔒 VPN切断中..."

# AWS VPN Clientを終了（VPNも自動的に切断される）
osascript <<'EOF'
tell application "AWS VPN Client"
    quit
end tell
EOF

if [ $? -eq 0 ]; then
    echo "✅ AWS VPN Clientを終了しました（VPN切断）"
    sleep 2
else
    echo "⚠️  VPN切断処理に失敗しました"
fi
