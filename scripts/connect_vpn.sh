#!/bin/bash

# AWS VPN Client で "develop" プロファイルに接続するスクリプト
# Command + D のショートカットを使用

echo "🔒 AWS VPN Client 'develop'プロファイルに接続中..."

osascript <<'EOF'
tell application "AWS VPN Client"
    activate
    delay 1
end tell

tell application "System Events"
    tell process "AWS VPN Client"
        -- Command + D を送信して接続
        keystroke "d" using command down
        delay 2
    end tell
end tell

return "✅ VPN接続コマンドを送信しました"
EOF

if [ $? -eq 0 ]; then
    echo "✅ VPN接続処理を実行しました"
    echo "⏳ 接続完了まで数秒待機します..."
    sleep 5
    echo "✅ VPN接続完了（想定）"
else
    echo "❌ VPN接続処理に失敗しました"
    exit 1
fi
