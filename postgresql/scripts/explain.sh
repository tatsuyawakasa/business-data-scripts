#!/bin/bash

# SQLクエリの実行計画を表示するスクリプト
# 使用方法: ./explain_query.sh "SQL_QUERY"

set -e

# 引数チェック
if [ $# -ne 1 ]; then
    echo "使用方法: $0 \"SQL_QUERY\""
    echo "例: $0 \"SELECT * FROM media WHERE location_id = 1004\""
    exit 1
fi

QUERY="$1"

# データベース接続情報
DB_HOST="milshot-prod.crr6umkkdk7n.ap-northeast-1.rds.amazonaws.com"
DB_USER="postgres"
DB_NAME="milshot"

echo "📊 実行計画を確認中..."
echo "クエリ: $QUERY"
echo "----------------------------------------"

# 実行計画の表示
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "EXPLAIN (ANALYZE, BUFFERS) $QUERY"

echo "----------------------------------------"
echo "✅ 実行計画の確認が完了しました" 