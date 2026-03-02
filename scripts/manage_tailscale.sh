#!/bin/bash

# Tailscaleの一時停止・再開を管理するヘルパースクリプト
# AWS VPN Client使用中にTailscaleとの競合を回避するために使用
#
# Usage:
#   manage_tailscale.sh down   — Tailscaleを一時停止
#   manage_tailscale.sh up     — Tailscaleを再開

TAILSCALE_CLI="/usr/local/bin/tailscale"

# Tailscaleがインストールされていない場合はスキップ
if [ ! -x "$TAILSCALE_CLI" ]; then
    echo "ℹ️  Tailscaleが見つかりません。スキップします"
    exit 0
fi

get_backend_state() {
    "$TAILSCALE_CLI" status --json 2>/dev/null \
        | python3 -c "import json,sys; print(json.load(sys.stdin).get('BackendState',''))" 2>/dev/null
}

case "${1:-}" in
    down)
        STATE=$(get_backend_state)
        if [ "$STATE" != "Running" ]; then
            echo "ℹ️  Tailscaleは既に停止中です (state: ${STATE:-unknown})"
            exit 0
        fi

        echo "⏸️  Tailscaleを一時停止します..."
        "$TAILSCALE_CLI" down 2>/dev/null

        # 停止確認（最大5秒）
        for i in $(seq 1 5); do
            STATE=$(get_backend_state)
            if [ "$STATE" = "Stopped" ]; then
                echo "✅ Tailscale停止完了"
                exit 0
            fi
            sleep 1
        done

        echo "⚠️  Tailscale停止を確認できませんでしたが、処理を続行します (state: ${STATE:-unknown})"
        exit 0
        ;;

    up)
        STATE=$(get_backend_state)
        if [ "$STATE" = "Running" ]; then
            echo "ℹ️  Tailscaleは既に稼働中です"
            exit 0
        fi

        echo "▶️  Tailscaleを再開します..."
        "$TAILSCALE_CLI" up 2>/dev/null

        # 起動確認（最大10秒）
        for i in $(seq 1 10); do
            STATE=$(get_backend_state)
            if [ "$STATE" = "Running" ]; then
                echo "✅ Tailscale再開完了"
                exit 0
            fi
            sleep 1
        done

        echo "⚠️  Tailscale再開を確認できませんでしたが、処理を続行します (state: ${STATE:-unknown})"
        exit 0
        ;;

    *)
        echo "Usage: $(basename "$0") {down|up}" >&2
        exit 1
        ;;
esac
