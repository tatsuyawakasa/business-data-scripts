#!/bin/bash

# 複数のレポート生成コマンドをまとめて実行するスクリプト
# CoDMONサービス関連のデータ分析レポートを一括生成

set -e

echo "🚀 CoDMONサービス レポート生成開始"
echo "================================================"

# 最終月曜日の日付を計算（YYYY-MM-DD形式）
if date -v-1w >/dev/null 2>&1; then
    # macOS (BSD date)
    LAST_MONDAY=$(date -v-$(date +%u)d -v+1d +%Y-%m-%d)
else
    # Linux (GNU date)
    LAST_MONDAY=$(date -d "last monday" +%Y-%m-%d)
fi

echo "📅 対象期間終了日: ${LAST_MONDAY} 00:00"
echo ""

# 出力ディレクトリの準備
OUTPUT_DIR="output"
mkdir -p "$OUTPUT_DIR"

echo "📊 レポート1: CoDMONサービス アプリログインカウント集計"
echo "---------------------------------------------------"
./mysql/scripts/to_csv.sh -f mysql/queries/camera_count_by_location.sql "${OUTPUT_DIR}/codmon_app_login_count_${LAST_MONDAY}.csv"

echo ""
echo "📊 レポート2: メディア活動×ロケーション情報 JOIN分析"
echo "---------------------------------------------------"
./scripts/media_location_join.sh "${OUTPUT_DIR}/media_location_join.csv"

echo ""
echo "📊 レポート3: Registration×Location情報 JOIN分析"
echo "---------------------------------------------------"
./scripts/registration_location_join.sh "${OUTPUT_DIR}/registration_location_join.csv"

echo ""
echo "================================================"
echo "✅ 全レポート生成完了!"
echo "📁 出力ディレクトリ: $OUTPUT_DIR"
echo ""
echo "📋 生成されたファイル:"
ls -la "${OUTPUT_DIR}"/*"${LAST_MONDAY}"* 2>/dev/null || echo "（日付付きファイルなし）" 