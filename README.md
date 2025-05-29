# Database Tools

PostgreSQLとMySQLデータベースへの接続、クエリ実行、データ抽出を行うためのツールセット。

## 機能一覧

### PostgreSQL
- PostgreSQLへの安全な接続（.pgpassファイル使用）
- SQLクエリの実行とCSV出力
- 実行計画の確認
- よく使用するクエリの管理

### MySQL
- MySQLへの安全な接続（~/.my.cnfファイル使用）
- SQLクエリの実行とCSV出力
- 実行計画の確認
- よく使用するクエリの管理

## セットアップ手順

### 共通
VPN接続が必要である。

### PostgreSQL
1. **.pgpassファイルの設定**
```bash
echo "HOST:PORT:DATABASE:USER:PASSWORD" > ~/.pgpass
chmod 600 ~/.pgpass
```

2. **接続テスト**
```bash
psql -h HOST -U USER -d DATABASE -c "SELECT 1;"
```

### MySQL
1. **~/.my.cnfファイルの設定**
```bash
[client]
host=HOST
port=3306
user=USER
password=PASSWORD
database=DATABASE
```

2. **接続テスト**
```bash
mysql -e "SELECT 1;"
```

## 使用方法

### PostgreSQL
```bash
# クエリ実行とCSV出力
./scripts/query_to_csv.sh "SELECT * FROM media LIMIT 10" output/result.csv
./scripts/query_to_csv.sh -f queries/media_location_count.sql output/result.csv

# 実行計画の確認
./scripts/explain_query.sh "SELECT * FROM media LIMIT 10"
```

### MySQL
```bash
# クエリ実行とCSV出力
./mysql_scripts/mysql_to_csv.sh "SELECT * FROM location LIMIT 10" mysql_output/result.csv
./mysql_scripts/mysql_to_csv.sh -f mysql_queries/location_custom_metadata.sql mysql_output/result.csv

# 実行計画の確認
./mysql_scripts/mysql_explain.sh "SELECT * FROM location LIMIT 10"
./mysql_scripts/mysql_explain.sh -f mysql_queries/location_custom_metadata.sql
```

## ディレクトリ構造

```
database_tools/
├── README.md                    # 本ドキュメント
├── scripts/                     # PostgreSQL実行スクリプト
│   ├── query_to_csv.sh         # CSV出力
│   └── explain_query.sh        # 実行計画
├── mysql_scripts/               # MySQL実行スクリプト
│   ├── mysql_to_csv.sh         # CSV出力
│   └── mysql_explain.sh        # 実行計画
├── queries/                     # PostgreSQL用SQLクエリ
├── mysql_queries/               # MySQL用SQLクエリ
├── output/                      # PostgreSQL用CSV出力
├── mysql_output/                # MySQL用CSV出力
├── config/                      # 設定ファイル（テンプレート）
└── docs/                        # 追加ドキュメント
```

## 注意事項

- 本番データベースへのアクセス時は必ずVPN接続を確認する
- パスワードファイルには適切なパーミッション（600）を設定する
- 重いクエリを実行する前は必ずEXPLAINで実行計画を確認する 