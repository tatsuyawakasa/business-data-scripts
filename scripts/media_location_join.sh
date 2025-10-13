#!/bin/bash

# メディア活動データ（PostgreSQL）とロケーション情報（MySQL）をJOINするスクリプト

set -e

# 引数チェック
if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "使用方法: $0 OUTPUT_CSV_PATH [PG_SQL_FILE]"
    echo "例: $0 output/media_location_join.csv"
    echo "例: $0 output/media_location_join.csv postgresql/queries/media_location_count_before_current_month_start.sql"
    echo "※ファイル名には自動的に最終月曜日の日付が追加されます"
    echo "※PG_SQL_FILEが省略された場合は postgresql/queries/media_location_count.sql を使用"
    exit 1
fi

# 日付計算（月末締めモード対応）
if [ "${MONTH_END_MODE}" = "true" ]; then
    # 月末締めモード：2025-07-01を使用
    LAST_MONDAY="2025-07-01"
    echo "🗓️  月末締めモード: ${LAST_MONDAY} 0時まで集計"
else
    # 通常モード：最終月曜日の日付を計算（YYYY-MM-DD形式）
    # macOS(BSD)とLinux(GNU)の両方に対応
    if date -v-1w >/dev/null 2>&1; then
        # macOS (BSD date)
        LAST_MONDAY=$(date -v-$(date +%u)d -v+1d +%Y-%m-%d)
    else
        # Linux (GNU date)
        LAST_MONDAY=$(date -d "last monday" +%Y-%m-%d)
    fi
fi

# 出力ファイルパスに日付を含める
OUTPUT_BASE="$1"
OUTPUT_DIR=$(dirname "$OUTPUT_BASE")
OUTPUT_NAME=$(basename "$OUTPUT_BASE" .csv)
OUTPUT_CSV="${OUTPUT_DIR}/${OUTPUT_NAME}_${LAST_MONDAY}.csv"

echo "🔗 メディア×ロケーション JOIN処理開始"
echo "📅 対象期間終了日: ${LAST_MONDAY} 00:00"

# 固定のクエリファイル
if [ $# -eq 2 ]; then
    PG_SQL_FILE="$2"
else
    PG_SQL_FILE="postgresql/queries/media_location_count.sql"
fi
MYSQL_SQL_FILE="mysql/queries/location_custom_metadata.sql"

echo "🔍 使用SQLファイル: $PG_SQL_FILE"

# 一時ディレクトリ
TEMP_DIR="temp"
mkdir -p "$(dirname "$OUTPUT_CSV")" "$TEMP_DIR"

# 一時ファイル名
PG_TEMP_CSV="$TEMP_DIR/pg_media_temp.csv"
MYSQL_TEMP_CSV="$TEMP_DIR/mysql_location_temp.csv"

echo "🔄 メディア活動データを取得中..."
./postgresql/scripts/to_csv.sh -f "$PG_SQL_FILE" "$PG_TEMP_CSV"

echo "🔄 ロケーション情報を取得中..."
./mysql/scripts/to_csv.sh -f "$MYSQL_SQL_FILE" "$MYSQL_TEMP_CSV"

# 取得したファイルの確認
PG_COUNT=$(tail -n +2 "$PG_TEMP_CSV" | wc -l | tr -d ' ')
MYSQL_COUNT=$(tail -n +2 "$MYSQL_TEMP_CSV" | wc -l | tr -d ' ')

echo "📊 メディア活動データ: ${PG_COUNT}件"
echo "📊 ロケーション情報: ${MYSQL_COUNT}件"

# ヘッダー作成（tlnk_shooting_mode別集計対応）
# BOM（Byte Order Mark）を追加してUTF-8 with BOMに変換
printf '\xEF\xBB\xBF' > "$OUTPUT_CSV"
echo "location_id,location_sid,facility_name,facility_id,manual_upload_count,app_upload_count,total_count,date" >> "$OUTPUT_CSV"

# JOIN処理実行
echo "🔄 JOIN処理中..."
awk -F, '
NR==FNR {
    # MySQLのlocation情報を連想配列に格納
    # カラム順序: custom_metadata,location_id,location_sid,location_name
    # location_id($2) をキーとして、location_sid($3),location_name($4),custom_metadata($1) を値とする
    mysql[$2] = $3 "," $4 "," $1
    next
}
{
    # PostgreSQLのメディアデータを処理
    # 各行（location_id + date）に対してMySQLのlocation情報を結合
    if ($1 in mysql) {
        # location_id,manual_upload_count,app_upload_count,total_count,date の順番で
        # location_id,location_sid,facility_name,facility_id,manual_upload_count,app_upload_count,total_count,date に変換
        print $1 "," mysql[$1] "," $2 "," $3 "," $4 "," $5
    }
}' <(tail -n +2 "$MYSQL_TEMP_CSV") <(tail -n +2 "$PG_TEMP_CSV") >> "$OUTPUT_CSV"

# 結果表示
RESULT_COUNT=$(tail -n +2 "$OUTPUT_CSV" | wc -l | tr -d ' ')
FILE_SIZE=$(ls -lh "$OUTPUT_CSV" | awk '{print $5}')

echo "✅ JOIN完了!"
echo "📊 結果件数: ${RESULT_COUNT}件"
echo "📄 ファイルサイズ: $FILE_SIZE"
echo "📄 出力先: $OUTPUT_CSV"

# 一時ファイル削除
rm -f "$PG_TEMP_CSV" "$MYSQL_TEMP_CSV"

echo ""
echo "📋 結果サンプル（先頭5件）:"
head -6 "$OUTPUT_CSV" 