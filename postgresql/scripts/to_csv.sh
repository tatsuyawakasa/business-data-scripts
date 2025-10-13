#!/bin/bash

# SQLクエリをCSVファイルに出力するスクリプト
# 使用方法: ./query_to_csv.sh "SQL_QUERY" output_file.csv
# または: ./query_to_csv.sh -f sql_file.sql output_file.csv

set -e

# SQLファイルからクエリを読み込む関数
load_sql_file() {
    local sql_file="$1"
    if [ ! -f "$sql_file" ]; then
        echo "❌ SQLファイルが見つかりません: $sql_file"
        exit 1
    fi
    
    # コメント行と空行を除去し、セミコロンを削除
    grep -v '^--' "$sql_file" | grep -v '^$' | tr '\n' ' ' | sed 's/;/ /g' | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//'
}

# 引数チェック
if [ $# -eq 3 ] && [ "$1" = "-f" ]; then
    # SQLファイルモード
    QUERY=$(load_sql_file "$2")
    OUTPUT_FILE="$3"
    echo "📄 SQLファイルを読み込み: $2"
elif [ $# -eq 2 ]; then
    # 直接クエリモード
    QUERY="$1"
    OUTPUT_FILE="$2"
else
    echo "使用方法:"
    echo "  $0 \"SQL_QUERY\" output_file.csv"
    echo "  $0 -f sql_file.sql output_file.csv"
    echo "例:"
    echo "  $0 \"SELECT * FROM media LIMIT 10\" output/sample.csv"
    echo "  $0 -f queries/media_location_count.sql output/result.csv"
    exit 1
fi

# データベース接続情報（.pgpassファイルから自動取得）
DB_HOST="milshot-prod-v2.crr6umkkdk7n.ap-northeast-1.rds.amazonaws.com"
DB_USER="postgres"
DB_NAME="milshot"

# 出力ディレクトリの作成
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

echo "クエリを実行中..."
echo "出力先: $OUTPUT_FILE"

# SQLクエリの実行とCSV出力
# 絶対パスに変換（ファイルが存在しない場合はディレクトリ作成後に処理）
ABSOLUTE_OUTPUT_FILE=$(cd "$(dirname "$OUTPUT_FILE")" && pwd)/$(basename "$OUTPUT_FILE")

# 一時ファイルにCSVを出力
TEMP_FILE="${ABSOLUTE_OUTPUT_FILE}.tmp"
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "\copy ($QUERY) TO '$TEMP_FILE' WITH CSV HEADER;"

if [ $? -eq 0 ]; then
    # BOM（Byte Order Mark）を追加してUTF-8 with BOMに変換
    # MacのNumbersやExcelで文字化けを防ぐため
    printf '\xEF\xBB\xBF' > "$ABSOLUTE_OUTPUT_FILE"
    cat "$TEMP_FILE" >> "$ABSOLUTE_OUTPUT_FILE"
    rm -f "$TEMP_FILE"
    
    echo "✅ 正常に完了しました"
    echo "📄 ファイルサイズ: $(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
    echo "📊 レコード数: $(tail -n +2 "$OUTPUT_FILE" | wc -l | tr -d ' ')件"
else
    echo "❌ エラーが発生しました"
    rm -f "$TEMP_FILE"
    exit 1
fi 