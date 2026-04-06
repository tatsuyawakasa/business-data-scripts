#!/bin/bash

# AWS VPN Client で "develop" プロファイルに接続するスクリプト
# launchd環境（スリープ復帰直後）でも動作するよう堅牢化
#
# 接続方式（優先順）:
#   1. OpenVPN CLI（brew install openvpn → GUI不要、画面ロック影響なし）
#   2. AWS VPN Client GUI操作（AppleScript経由）
#
# スリープ復帰時の問題:
#   ディスプレイがオフ or 画面ロック中だとWindowServerがウィンドウを作成できない。
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

# =============================================================================
# 方式1: OpenVPN CLI（GUIなし — 画面ロック状態でも動作）
# =============================================================================
# セットアップ: brew install openvpn
#               sudo visudo -f /etc/sudoers.d/openvpn
#               内容: t_wakasa ALL=(ALL) NOPASSWD: /opt/homebrew/sbin/openvpn
# =============================================================================

OPENVPN_BIN="/opt/homebrew/sbin/openvpn"
OVPN_CONFIG="$HOME/.config/AWSVPNClient/OpenVpnConfigs/develop"

try_openvpn_cli() {
    if [ ! -x "$OPENVPN_BIN" ]; then
        echo "ℹ️  OpenVPN CLIが未インストール（GUI方式にフォールバック）"
        return 1
    fi

    if ! sudo -n "$OPENVPN_BIN" --version >/dev/null 2>&1; then
        echo "ℹ️  OpenVPN CLIのsudo権限なし（GUI方式にフォールバック）"
        echo "   セットアップ: sudo visudo -f /etc/sudoers.d/openvpn"
        echo "   内容: $USER ALL=(ALL) NOPASSWD: $OPENVPN_BIN"
        return 1
    fi

    echo "🔌 OpenVPN CLI方式で接続を試みます..."

    # 既存のopenvpnプロセスを停止
    sudo -n killall openvpn 2>/dev/null || true
    sleep 1

    # バックグラウンドでopenvpn起動
    sudo -n "$OPENVPN_BIN" --config "$OVPN_CONFIG" --daemon --log /tmp/openvpn_connect.log 2>&1

    if [ $? -ne 0 ]; then
        echo "⚠️  OpenVPN CLI起動エラー"
        cat /tmp/openvpn_connect.log 2>/dev/null | tail -5
        return 1
    fi

    echo "⏳ OpenVPN接続確立を待機中..."

    # VPN接続を確認（最大90秒待機）
    MAX_WAIT=90
    WAIT_COUNT=0

    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        if test_pg_connection; then
            echo ""
            echo "✅ VPN接続完了（OpenVPN CLI）"
            return 0
        fi

        sleep 3
        WAIT_COUNT=$((WAIT_COUNT + 3))
        echo -n "."
    done

    echo ""
    echo "⚠️  OpenVPN CLI接続タイムアウト（${MAX_WAIT}秒）"

    # 失敗時はopenvpnプロセスを停止
    sudo -n killall openvpn 2>/dev/null || true

    # ログの最後を表示
    echo "📋 OpenVPNログ（最新5行）:"
    cat /tmp/openvpn_connect.log 2>/dev/null | tail -5
    return 1
}

# OpenVPN CLIを試行
if try_openvpn_cli; then
    exit 0
fi

echo ""

# =============================================================================
# 方式2: AWS VPN Client GUI操作（AppleScript経由）
# =============================================================================

echo "🖥️  AWS VPN Client GUI方式で接続を試みます..."

# ディスプレイを強制ON（300秒間維持）— スリープ復帰後のGUI操作に必須
caffeinate -u -t 300 &
CAFFEINATE_PID=$!

# ディスプレイとWindowServerが完全に復帰するまで待機
echo "⏳ システム復帰を待機中..."
sleep 15

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

# ディスプレイ状態を診断出力
echo "📋 ディスプレイ状態:"
if pmset -g assertions 2>/dev/null | grep -q "PreventUserIdleDisplaySleep"; then
    echo "  ✅ ディスプレイ: アサーション有効"
else
    echo "  ⚠️  ディスプレイ: アサーションなし"
fi

# AWS VPN Clientを起動（既存プロセスがあっても安全）
open -a "AWS VPN Client"
sleep 5

# 最大4回リトライ（Cmd+D送信）
MAX_ATTEMPTS=4
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
            echo "   AWS VPN Clientを再起動してリトライします..."
            # アプリを完全再起動（新しいウィンドウ作成を促す）
            osascript -e 'tell application "AWS VPN Client" to quit' 2>/dev/null || true
            sleep 5
            open -a "AWS VPN Client"
            sleep 10
            # ディスプレイ再wake（念押し）
            caffeinate -u -t 60 &
            sleep 5
            continue
        fi
    fi

    echo "✅ VPN接続コマンドを送信しました"
    echo "⏳ 接続確立を待機中..."

    # VPN接続を確認（最大90秒待機）
    MAX_WAIT=90
    WAIT_COUNT=0

    while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
        if test_pg_connection; then
            echo ""
            echo "✅ VPN接続完了（確認済み）"
            exit 0
        fi

        sleep 3
        WAIT_COUNT=$((WAIT_COUNT + 3))
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
