#!/bin/bash

# child anonymous group分析実行スクリプト
# MySQL childテーブルとgroupテーブルを使用してanonymous比率を分析

set -e

# デフォルト出力ファイル名（引数で上書き可能）
DEFAULT_OUTPUT="output/child_anonymous_analysis_$(date +%Y-%m-%d).csv"
OUTPUT_FILE="${1:-$DEFAULT_OUTPUT}"

# スクリプトのディレクトリを取得し、プロジェクトルートを設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# プロジェクトルートに移動
cd "$PROJECT_ROOT"

echo "🔍 Child Anonymous Group 分析開始"
echo "📊 データソース: MySQL child + group テーブル"
echo "📁 出力ファイル: $OUTPUT_FILE"
echo ""

# 出力ディレクトリを作成
mkdir -p "$(dirname "$OUTPUT_FILE")"

# MySQL実行とCSV出力
./mysql/scripts/to_csv.sh -f mysql/queries/child_anonymous_analysis.sql "$OUTPUT_FILE"

echo ""
echo "✅ Child Anonymous Group 分析完了!"
echo "📄 出力ファイル: $OUTPUT_FILE"

# ファイルサイズとレコード数を表示
if [[ -f "$OUTPUT_FILE" ]]; then
    FILE_SIZE=$(ls -lh "$OUTPUT_FILE" | awk '{print $5}')
    RECORD_COUNT=$(tail -n +2 "$OUTPUT_FILE" | wc -l | tr -d ' ')
    echo "📊 ファイルサイズ: $FILE_SIZE"
    echo "📊 レコード数: $RECORD_COUNT 行"
fi 