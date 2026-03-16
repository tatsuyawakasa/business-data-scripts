#!/bin/bash

# AWS VPN Client で "develop" プロファイルに接続するスクリプト
# launchd環境（スリープ復帰直後）でも動作するよう堅牢化
#
# スリープ復帰時の問題:
#   ディスプレイがオフのままだとWindowServerがウィンドウを作成できない。
#   caffeinate -u でディスプレイを強制的にオンにし、十分な待機後にGUI操作する。

# PostgreSQL接続テスト用の関数
pg_host() { grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f1; }
pg_user() { grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f4; }
pg_db()   { grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f3; }

test_pg_connection() {
    timeout 3 psql -h "$(pg_host)" -U "$(pg_user)" -d "$(pg_db)" -c "SELECT 1;" >/dev/null 2>&1
}

echo "🔒 VPN接続状態を確認中..."

# 既にVPN接続済みかチェック
if test_pg_connection; then
    echo "✅ VPN接続済みです。スキップします"
    exit 0
fi

echo "🔒 AWS VPN Client 'develop'プロファイルに接続中..."

# ディスプレイを強制オン（60秒間維持）— スリープ復帰後のGUI操作に必須
caffeinate -u -t 60 &
CAFFEINATE_PID=$!

# ディスプレイとWindowServerが完全に復帰するまで待機
echo "⏳ システム復帰を待機中..."
sleep 10

# ネットワーク復帰を待機（スリープ復帰後、Wi-Fi再接続に時間がかかる）
echo "⏳ ネットワーク復帰を待機中..."
MAX_NET_WAIT=30
NET_WAIT=0
while [ $NET_WAIT -lt $MAX_NET_WAIT ]; do
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        echo "✅ ネットワーク接続確認済み"
        break
    fi
    sleep 2
    NET_WAIT=$((NET_WAIT + 2))
    echo -n "."
done
if [ $NET_WAIT -ge $MAX_NET_WAIT ]; then
    echo ""
    echo "⚠️  ネットワーク復帰タイムアウト（${MAX_NET_WAIT}秒）。続行します..."
fi

# AWS VPN Clientを起動
open -a "AWS VPN Client"
sleep 5

# 最大2回リトライ（Cmd+D送信）
MAX_ATTEMPTS=2
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "🔑 接続試行 ${ATTEMPT}/${MAX_ATTEMPTS}..."

    # activateでウィンドウ表示を試み、ステータスバーメニューでフォローアップ
    osascript <<'APPLESCRIPT'
-- まずactivateでアプリをフォアグラウンドに（ウィンドウ作成を促す）
tell application "AWS VPN Client" to activate
delay 3

tell application "System Events"
    tell process "AWS VPN Client"
        -- ウィンドウがなければステータスバーメニューから開く
        if not (exists window 1) then
            try
                click menu bar item 1 of menu bar 2
                delay 1
                click menu item "AWS VPN Client を開く" of menu 1 of menu bar item 1 of menu bar 2
                delay 3
            end try
        end if

        -- それでもなければactivateを再試行
        if not (exists window 1) then
            tell application "AWS VPN Client" to activate
            delay 5
        end if

        -- ウィンドウ待機（最大20秒）
        set maxWait to 20
        set waitCount to 0
        repeat until (exists window 1) or waitCount > maxWait
            delay 1
            set waitCount to waitCount + 1
        end repeat

        if not (exists window 1) then
            error "AWS VPN Client ウィンドウが表示されませんでした"
        end if

        -- Command + D を送信して接続
        set frontmost to true
        delay 0.5
        keystroke "d" using command down
        delay 2
    end tell
end tell

return "OK"
APPLESCRIPT

    OSASCRIPT_EXIT=$?
    if [ $OSASCRIPT_EXIT -ne 0 ]; then
        echo "⚠️  AppleScript実行エラー (exit: $OSASCRIPT_EXIT)"
        if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
            echo "   リトライします..."
            sleep 10
            continue
        fi
    fi

    echo "✅ VPN接続コマンドを送信しました"
    echo "⏳ 接続確立を待機中..."

    # VPN接続を確認（最大60秒待機）
    MAX_WAIT=60
    WAIT_COUNT=0

    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        if test_pg_connection; then
            echo ""
            echo "✅ VPN接続完了（確認済み）"
            exit 0
        fi

        sleep 2
        WAIT_COUNT=$((WAIT_COUNT + 2))
        echo -n "."
    done

    echo ""
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        echo "⚠️  接続確認タイムアウト（${MAX_WAIT}秒）。再試行します..."
        sleep 3
    fi
done

echo "⚠️  VPN接続確認がタイムアウトしました（全${MAX_ATTEMPTS}回試行）"
echo "   接続は進行中の可能性があります。処理を続行します..."
