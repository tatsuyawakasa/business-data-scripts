#!/bin/bash

# VPN接続を切断するスクリプト
# OpenVPN CLIデーモン と AWS VPN Client GUI の両方に対応

echo "🔒 VPN切断中..."

DISCONNECTED=false

# OpenVPN CLIデーモンの停止
if pgrep -x openvpn >/dev/null 2>&1; then
    echo "  🔌 OpenVPNデーモンを停止中..."
    sudo -n /usr/bin/killall openvpn 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "  ✅ OpenVPNデーモンを停止しました"
        DISCONNECTED=true
    else
        echo "  ⚠️  OpenVPNデーモンの停止に失敗しました"
    fi
fi

# AWS VPN Client GUIの終了
if pgrep -f "AWS VPN Client" >/dev/null 2>&1; then
    echo "  🖥️  AWS VPN Clientを終了中..."
    osascript -e 'tell application "AWS VPN Client" to quit' 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "  ✅ AWS VPN Clientを終了しました"
        DISCONNECTED=true
    else
        echo "  ⚠️  AWS VPN Clientの終了に失敗しました"
    fi
fi

if [ "$DISCONNECTED" = true ]; then
    sleep 2
    echo "✅ VPN切断完了"
else
    echo "ℹ️  切断対象のVPNプロセスはありませんでした"
fi
