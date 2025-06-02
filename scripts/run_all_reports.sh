#!/bin/bash

# 複数のレポート生成コマンドをまとめて実行するスクリプト
# CoDMONサービス関連のデータ分析レポートを一括生成

set -e

# スクリプトのディレクトリを取得し、プロジェクトルートを設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# プロジェクトルートに移動
cd "$PROJECT_ROOT"

# VPN接続チェック関数
check_vpn_connection() {
    echo "🔒 VPN接続チェック中..."
    
    # PostgreSQL接続テスト（タイムアウト5秒）
    echo "  📊 PostgreSQL接続テスト..."
    if ! timeout 5 psql -h $(grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f1) -U $(grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f4) -d $(grep -E "^[^#].*:" ~/.pgpass | head -1 | cut -d: -f3) -c "SELECT 1;" >/dev/null 2>&1; then
        echo ""
        echo "❌ エラー: PostgreSQLサーバーに接続できません"
        echo "🔒 VPN接続を確認してください"
        echo ""
        echo "📋 確認事項:"
        echo "  • VPN接続が有効になっているか"
        echo "  • ネットワーク接続が安定しているか"
        echo "  • データベース認証情報が正しいか（~/.pgpass）"
        echo ""
        exit 1
    fi
    
    # MySQL接続テスト（タイムアウト5秒）
    echo "  🗄️  MySQL接続テスト..."
    if ! timeout 5 mysql -e "SELECT 1;" >/dev/null 2>&1; then
        echo ""
        echo "❌ エラー: MySQLサーバーに接続できません"
        echo "🔒 VPN接続を確認してください"
        echo ""
        echo "📋 確認事項:"
        echo "  • VPN接続が有効になっているか"
        echo "  • ネットワーク接続が安定しているか"
        echo "  • データベース認証情報が正しいか（~/.my.cnf）"
        echo ""
        exit 1
    fi
    
    echo "✅ VPN接続確認完了"
    echo ""
}

echo "🚀 CoDMONサービス レポート生成開始"
echo "================================================"
echo "📁 実行ディレクトリ: $PROJECT_ROOT"

# VPN接続チェックを実行
check_vpn_connection

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
echo "  📊 レポート2-1: 直近月曜日までのデータ分析"
./scripts/media_location_join.sh "${OUTPUT_DIR}/media_location_join_recent_monday.csv" postgresql/queries/media_location_count_before_most_recent_monday.sql

echo ""
echo "  📊 レポート2-2: 今月開始前までのデータ分析"
./scripts/media_location_join.sh "${OUTPUT_DIR}/media_location_join_current_month.csv" postgresql/queries/media_location_count_before_current_month_start.sql

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