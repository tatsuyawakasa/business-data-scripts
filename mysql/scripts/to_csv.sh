#!/bin/bash

# MySQLクエリをCSVファイルに出力するスクリプト
# 使用方法: ./mysql_to_csv.sh "SQL_QUERY" output_file.csv
# または: ./mysql_to_csv.sh -f sql_file.sql output_file.csv

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
    echo "  $0 \"SELECT * FROM location LIMIT 10\" mysql_output/sample.csv"
    echo "  $0 -f mysql_queries/location_custom_metadata.sql mysql_output/result.csv"
    exit 1
fi

# 出力ディレクトリの作成
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
mkdir -p "$OUTPUT_DIR"

echo "🔍 MySQLクエリを実行中..."
echo "📊 出力先: $OUTPUT_FILE"

# MySQLクエリの実行とCSV出力
# ~/.my.cnfファイルから接続情報を自動取得
# タブ区切りで出力してからカンマ区切りに変換
TEMP_OUTPUT=$(mktemp)
mysql --default-character-set=utf8mb4 -e "$QUERY" > "$TEMP_OUTPUT"

# BOM（Byte Order Mark）を追加してUTF-8 with BOMに変換
# MacのNumbersやExcelで文字化けを防ぐため
printf '\xEF\xBB\xBF' > "$OUTPUT_FILE"

# タブ区切りをカンマ区切りに変換してCSVファイルに追加
cat "$TEMP_OUTPUT" | tr '\t' ',' >> "$OUTPUT_FILE"

# 一時ファイルを削除
rm -f "$TEMP_OUTPUT"

if [ $? -eq 0 ]; then
    echo "✅ 正常に完了しました"
    echo "📄 ファイルサイズ: $(ls -lh "$OUTPUT_FILE" | awk '{print $5}')"
    echo "📊 レコード数: $(tail -n +2 "$OUTPUT_FILE" | wc -l | tr -d ' ')件"
else
    echo "❌ エラーが発生しました"
    exit 1
fi 