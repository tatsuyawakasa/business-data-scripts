#!/bin/bash

# MySQLクエリの実行計画を表示するスクリプト
# 使用方法: ./mysql_explain.sh "SQL_QUERY"
# または: ./mysql_explain.sh -f sql_file.sql

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
if [ $# -eq 2 ] && [ "$1" = "-f" ]; then
    # SQLファイルモード
    QUERY=$(load_sql_file "$2")
    echo "📄 SQLファイルを読み込み: $2"
elif [ $# -eq 1 ]; then
    # 直接クエリモード
    QUERY="$1"
else
    echo "使用方法:"
    echo "  $0 \"SQL_QUERY\""
    echo "  $0 -f sql_file.sql"
    echo "例:"
    echo "  $0 \"SELECT * FROM location WHERE location_id = 1004\""
    echo "  $0 -f mysql_queries/location_custom_metadata.sql"
    exit 1
fi

echo "📊 MySQL実行計画を確認中..."
echo "クエリ: $QUERY"
echo "----------------------------------------"

# MySQL実行計画の表示
mysql -e "EXPLAIN $QUERY"

echo "----------------------------------------"
echo "✅ 実行計画の確認が完了しました" 