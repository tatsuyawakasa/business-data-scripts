#!/bin/bash

# AWS VPN Client で "develop" プロファイルに接続するスクリプト
# Command + D のショートカットを使用

echo "🔒 VPN接続状態を確認中..."

# 既にVPN接続済みかチェック（PostgreSQL接続テスト）
if timeout 2 psql -h $(grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f1) -U $(grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f4) -d $(grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f3) -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ VPN接続済みです。スキップします"
    exit 0
fi

echo "🔒 AWS VPN Client 'develop'プロファイルに接続中..."

# AWS VPN Clientを起動
open -a "AWS VPN Client"

# アプリが完全に起動するまで待機
sleep 3

osascript <<'EOF'
tell application "System Events"
    tell process "AWS VPN Client"
        -- ウィンドウが表示されるまで待機
        set maxWait to 10
        set waitCount to 0
        repeat until (exists window 1) or waitCount > maxWait
            delay 1
            set waitCount to waitCount + 1
        end repeat

        -- Command + D を送信して接続
        keystroke "d" using command down
        delay 2
    end tell
end tell

return "✅ VPN接続コマンドを送信しました"
EOF

if [ $? -eq 0 ]; then
    echo "✅ VPN接続処理を実行しました"
    echo "⏳ 接続確立を待機中..."

    # VPN接続を確認（最大30秒待機）
    MAX_WAIT=30
    WAIT_COUNT=0

    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        # PostgreSQL接続テスト（簡易チェック）
        if timeout 2 psql -h $(grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f1) -U $(grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f4) -d $(grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f3) -c "SELECT 1;" >/dev/null 2>&1; then
            echo "✅ VPN接続完了（確認済み）"
            exit 0
        fi

        sleep 2
        WAIT_COUNT=$((WAIT_COUNT + 2))
        echo -n "."
    done

    echo ""
    echo "⚠️  VPN接続確認がタイムアウトしました（${MAX_WAIT}秒）"
    echo "   接続は進行中の可能性があります。処理を続行します..."
else
    echo "❌ VPN接続処理に失敗しました"
    exit 1
fi
