#!/bin/bash

# launchd → iTerm2 経由で実行されるラッパースクリプト
# 環境変数（PATH等）を設定してから run_all_reports.sh を実行する

# Homebrew 環境の PATH を設定
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:/opt/homebrew/opt/mysql-client/bin:/opt/homebrew/opt/postgresql@16/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# ロケール設定（launchd環境ではLANG未設定のため、MySQL日本語が文字化けする対策）
export LANG=ja_JP.UTF-8
export LC_ALL=ja_JP.UTF-8

# HOME を明示的に設定（.pgpass, .my.cnf の参照に必要）
export HOME="/Users/t_wakasa"

# ログディレクトリ
LOG_DIR="/Users/t_wakasa/Cursor/projects/business-data-scripts/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/scheduled_report.log"

# スリープ防止（スクリプト終了時に自動解除）
caffeinate -dims -w $$ &

# ディスプレイを強制ON（VPN接続のGUI操作に必須、スクリプト全体をカバー）
# -u: UserIsActive assertion（ディスプレイ起動 + 画面ロック防止）
# 600秒 = 10分間維持（スクリプト全体の実行時間をカバー）
caffeinate -u -t 600 &

# ディスプレイとWindowServerが完全に復帰するまで待機
echo "⏳ ディスプレイ起動待機中（30秒）..."
sleep 30

echo "========================================"
echo "スケジュール実行開始: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

# スクリプト本体を実行（ターミナルに出力しつつログにも記録）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/run_all_reports.sh" 2>&1 | tee "$LOG_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo "========================================"
echo "スケジュール実行終了: $(date '+%Y-%m-%d %H:%M:%S') (exit code: $EXIT_CODE)"
echo "========================================"

exit $EXIT_CODE
