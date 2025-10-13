#!/bin/bash

# PostgreSQLのregistrationデータとMySQLのlocation情報をINNER JOINするスクリプト

set -e

# 引数チェック
if [ $# -ne 1 ]; then
    echo "使用方法: $0 OUTPUT_CSV_PATH"
    echo "例: $0 output/registration_location_join.csv"
    echo "※ファイル名には自動的に実行日時が追加されます"
    exit 1
fi

# 実行日時を取得（YYYY-MM-DD_HHMMSS形式）
TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)

# 出力ファイルパスに日時を含める
OUTPUT_BASE="$1"
OUTPUT_DIR=$(dirname "$OUTPUT_BASE")
OUTPUT_NAME=$(basename "$OUTPUT_BASE" .csv)
OUTPUT_CSV="${OUTPUT_DIR}/${OUTPUT_NAME}_${TIMESTAMP}.csv"

echo "🔗 Registration×Location JOIN処理開始"
echo "⏰ 実行日時: $(date '+%Y-%m-%d %H:%M:%S')"

# 固定のクエリファイル
PG_SQL_FILE="postgresql/queries/registration_location_count.sql"
MYSQL_SQL_FILE="mysql/queries/location_custom_metadata.sql"

# 一時ディレクトリ
TEMP_DIR="temp"
mkdir -p "$(dirname "$OUTPUT_CSV")" "$TEMP_DIR"

# 一時ファイル名
PG_TEMP_CSV="$TEMP_DIR/pg_registration_temp.csv"
MYSQL_TEMP_CSV="$TEMP_DIR/mysql_location_temp.csv"

echo "🔄 Registration データを取得中..."
./postgresql/scripts/to_csv.sh -f "$PG_SQL_FILE" "$PG_TEMP_CSV"

echo "🔄 Location 情報を取得中..."
./mysql/scripts/to_csv.sh -f "$MYSQL_SQL_FILE" "$MYSQL_TEMP_CSV"

# 取得したファイルの確認
PG_COUNT=$(tail -n +2 "$PG_TEMP_CSV" | wc -l | tr -d ' ')
MYSQL_COUNT=$(tail -n +2 "$MYSQL_TEMP_CSV" | wc -l | tr -d ' ')

echo "📊 Registration データ: ${PG_COUNT}件"
echo "📊 Location 情報: ${MYSQL_COUNT}件"

# ヘッダー作成
# BOM（Byte Order Mark）を追加してUTF-8 with BOMに変換
printf '\xEF\xBB\xBF' > "$OUTPUT_CSV"
echo "location_id,location_sid,facility_name,facility_id,registered_children_count,date" >> "$OUTPUT_CSV"

# INNER JOIN処理実行
echo "🔄 INNER JOIN処理中..."
awk -F, '
NR==FNR {
    # MySQLのlocation情報を連想配列に格納
    # カラム順序: custom_metadata,location_id,location_sid,location_name
    # location_id($2) をキーとして、location_sid($3),location_name($4),custom_metadata($1) を値とする
    mysql[$2] = $3 "," $4 "," $1
    next
}
{
    # PostgreSQLのregistrationデータを処理
    # 各行（location_id + date）に対してMySQLのlocation情報を結合（INNER JOIN）
    if ($1 in mysql) {
        # location_id,registered_children_count,date の順番で
        # location_id,location_sid,facility_name,facility_id,registered_children_count,date に変換
        print $1 "," mysql[$1] "," $2 "," $3
    }
}' <(tail -n +2 "$MYSQL_TEMP_CSV") <(tail -n +2 "$PG_TEMP_CSV") >> "$OUTPUT_CSV"

# 結果表示
RESULT_COUNT=$(tail -n +2 "$OUTPUT_CSV" | wc -l | tr -d ' ')
FILE_SIZE=$(ls -lh "$OUTPUT_CSV" | awk '{print $5}')

echo "✅ INNER JOIN完了!"
echo "📊 結果件数: ${RESULT_COUNT}件"
echo "📄 ファイルサイズ: $FILE_SIZE"
echo "📄 出力先: $OUTPUT_CSV"

# 一時ファイル削除
rm -f "$PG_TEMP_CSV" "$MYSQL_TEMP_CSV"

echo ""
echo "📋 結果サンプル（先頭5件）:"
head -6 "$OUTPUT_CSV"

echo ""
echo "📋 結果サンプル（末尾5件）:"
tail -5 "$OUTPUT_CSV" 