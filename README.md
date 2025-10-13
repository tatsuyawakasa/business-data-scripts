# Business Data Scripts

PostgreSQLとMySQLデータベースへの接続、クエリ実行、データ抽出を行うためのビジネスデータ分析ツールセット。
非エンジニアでも安全にデータベースからデータを取得し、CSV形式で分析できるツールです。

## はじめに - 重要な注意事項

⚠️ **本番データベースを扱うため、以下の点を必ず守ってください**
- VPN接続を確認してからツールを使用する
- パスワード情報は他人に共有しない
- 大量のデータを取得する前は必ず相談する
- 不明な点があれば必ずエンジニアに確認する

## 機能一覧

### PostgreSQL
- PostgreSQLへの安全な接続（パスワードファイル使用）
- SQLクエリの実行とCSV出力
- 実行計画の確認（動作が重くないかチェック）
- よく使用するクエリの管理

### MySQL
- MySQLへの安全な接続（設定ファイル使用）
- SQLクエリの実行とCSV出力
- 実行計画の確認（動作が重くないかチェック）
- よく使用するクエリの管理

## 初期設定手順

### 事前準備
1. **VPN接続の確認**
   - データベースにアクセスするには社内VPNに接続している必要があります
   - VPN接続方法についてはIT部門にお問い合わせください

2. **ターミナル（コマンドライン）の開き方**
   - **Mac**: Launchpad → ターミナル、または Cmd+Space で「ターミナル」と検索
   - **Windows**: PowerShellまたはコマンドプロンプトを使用

3. **データベース接続情報の取得**
   - 接続に必要な情報はAWS Secrets Managerで管理されています
   - 以下のリンクから接続情報を確認してください（AWSアカウントへのログインが必要）

   **PostgreSQL接続情報:**
   - [core-api-production](https://ap-northeast-1.console.aws.amazon.com/secretsmanager/secret?name=core-api-production&region=ap-northeast-1)
   - この情報を使ってPostgreSQLに接続します

   **MySQL接続情報:**
   - [tlnk-api-production](https://ap-northeast-1.console.aws.amazon.com/secretsmanager/secret?name=tlnk-api-production&region=ap-northeast-1)
   - この情報を使ってMySQLに接続します

   ⚠️ **重要**: AWS Secrets Managerにアクセスできない場合は、IT部門またはエンジニアに接続情報の取得を依頼してください

### PostgreSQL設定

#### 1. パスワードファイル（.pgpass）の作成

**このファイルは何？**
PostgreSQLに接続するためのパスワード情報を安全に保存するファイルです。毎回パスワードを入力する手間が省けます。

**設定手順：**

1. **ターミナルでホームディレクトリに移動**
   ```bash
   cd ~
   ```

2. **AWS Secrets Managerから接続情報を取得**
   - [core-api-production](https://ap-northeast-1.console.aws.amazon.com/secretsmanager/secret?name=core-api-production&region=ap-northeast-1)にアクセス
   - 「シークレットの値を取得」をクリック
   - 以下の情報をメモ：
     - `host`: データベースサーバー名
     - `port`: ポート番号（通常は5432）
     - `dbname`: データベース名
     - `username`: ユーザー名
     - `password`: パスワード

3. **パスワードファイルを作成**
   ```bash
   echo "ホスト名:ポート:データベース名:ユーザー名:パスワード" > .pgpass
   ```
   
   **実際の例（AWS Secretsの値を使用）:**
   ```bash
   echo "your-postgres-host.amazonaws.com:5432:production_db:your_username:your_password" > .pgpass
   ```

4. **ファイルのアクセス権限を設定（重要）**
   ```bash
   chmod 600 .pgpass
   ```
   **なぜ必要？** このコマンドにより、あなた以外の人がパスワードファイルを読めなくなり、セキュリティが保たれます。

#### 2. 接続テスト
```bash
psql -h ホスト名 -U ユーザー名 -d データベース名 -c "SELECT 1;"
```

**実際の例：**
```bash
psql -h your-postgres-host.amazonaws.com -U your_username -d production_db -c "SELECT 1;"
```

**成功した場合の表示例：**
```
 ?column? 
----------
        1
(1 row)
```

### MySQL設定

#### 1. 設定ファイル（.my.cnf）の作成

**このファイルは何？**
MySQLに接続するための設定情報を保存するファイルです。接続情報を毎回入力する必要がなくなります。

**設定手順：**

1. **ターミナルでホームディレクトリに移動**
   ```bash
   cd ~
   ```

2. **AWS Secrets Managerから接続情報を取得**
   - [tlnk-api-production](https://ap-northeast-1.console.aws.amazon.com/secretsmanager/secret?name=tlnk-api-production&region=ap-northeast-1)にアクセス
   - 「シークレットの値を取得」をクリック
   - 以下の情報をメモ：
     - `host`: データベースサーバー名
     - `port`: ポート番号（通常は3306）
     - `dbname`: データベース名
     - `username`: ユーザー名
     - `password`: パスワード

3. **設定ファイルを作成**
   ```bash
   cat > .my.cnf << EOF
   [client]
   host=ホスト名
   port=ポート番号
   user=ユーザー名
   password=パスワード
   database=データベース名
   EOF
   ```

   **実際の例（AWS Secretsの値を使用）:**
   ```bash
   cat > .my.cnf << EOF
   [client]
   host=your-mysql-host.amazonaws.com
   port=3306
   user=your_username
   password=your_password
   database=your_database
   EOF
   ```

4. **ファイルのアクセス権限を設定（重要）**
   ```bash
   chmod 600 .my.cnf
   ```

#### 2. 接続テスト
```bash
mysql -e "SELECT 1;"
```

**成功した場合の表示例：**
```
+---+
| 1 |
+---+
| 1 |
+---+
```

## 使用方法

### PostgreSQL

#### 基本的なクエリ実行
```bash
# 直接SQLを実行してCSVで保存
./postgresql/scripts/to_csv.sh "SELECT * FROM media LIMIT 10" postgresql/output/sample_data.csv

# 保存済みのクエリファイルを実行
./postgresql/scripts/to_csv.sh -f postgresql/queries/media_location_count.sql postgresql/output/media_report.csv
```

#### クエリの動作確認（重要）
大量のデータを取得する前に、必ず動作の重さを確認してください：
```bash
./postgresql/scripts/explain.sh "SELECT * FROM media WHERE created_datetime >= '2024-01-01'"
```

### MySQL

#### 基本的なクエリ実行
```bash
# 直接SQLを実行してCSVで保存
./mysql/scripts/to_csv.sh "SELECT * FROM location LIMIT 10" mysql/output/location_sample.csv

# 保存済みのクエリファイルを実行
./mysql/scripts/to_csv.sh -f mysql/queries/location_custom_metadata.sql mysql/output/location_report.csv
```

#### クエリの動作確認
```bash
./mysql/scripts/explain.sh "SELECT * FROM location WHERE updated_at >= '2024-01-01'"
```

### 統合分析レポート

複数のデータベースからデータを取得して結合した分析を実行：

```bash
# メディアと拠点情報を結合した分析
./scripts/media_location_join.sh

# 登録情報と拠点情報を結合した分析
./scripts/registration_location_join.sh

# 全ての定期レポートを一括実行
./scripts/run_all_reports.sh
```

## ファイルの場所と管理

### 出力ファイルの場所
- PostgreSQLの結果: `postgresql/output/` フォルダ
- MySQLの結果: `mysql/output/` フォルダ
- 一時ファイル: `temp/` フォルダ

### よく使うクエリの保存場所
- PostgreSQL用: `postgresql/queries/` フォルダ
- MySQL用: `mysql/queries/` フォルダ

### 文字コードについて
出力されるCSVファイルは **UTF-8 with BOM（Byte Order Mark）** 形式で保存される。これにより、以下のソフトウェアで日本語が文字化けせずに表示される：
- Mac Numbers
- Microsoft Excel
- Google スプレッドシート

BOMとは、ファイルの先頭に付加される特殊なマーカー（`EF BB BF`）で、ファイルがUTF-8であることを示す。

## トラブルシューティング

### よくあるエラーと対処法

#### 1. 「psql: connection to server failed」
**原因**: VPN未接続、またはデータベースサーバーに接続できない
**対処法**: 
- VPN接続を確認
- ネットワーク接続を確認
- IT部門に問い合わせ

#### 2. 「authentication failed」
**原因**: ユーザー名またはパスワードが間違っている
**対処法**: 
- .pgpassまたは.my.cnfファイルの内容を確認
- 正しい認証情報をIT部門に確認

#### 3. 「permission denied」
**原因**: ファイルのアクセス権限が正しく設定されていない
**対処法**: 
```bash
chmod 600 ~/.pgpass
chmod 600 ~/.my.cnf
```

#### 4. 「command not found」
**原因**: PostgreSQLまたはMySQLのクライアントツールがインストールされていない
**対処法**: IT部門にソフトウェアのインストールを依頼

### ヘルプが必要な時
- エラーメッセージの内容をそのままエンジニアに共有
- 実行したコマンドを正確に伝える
- VPN接続状況を伝える

## ディレクトリ構造

```
business-data-scripts/
├── README.md                    # 本ドキュメント
├── .gitignore                   # Git除外設定
├── config/                      # 設定ファイル（テンプレート）
│   ├── mysql.cnf.template      # MySQL接続設定テンプレート
│   └── pgpass.template         # PostgreSQL接続設定テンプレート
├── postgresql/                  # PostgreSQL関連
│   ├── scripts/                # 実行スクリプト
│   │   ├── to_csv.sh          # CSV出力スクリプト
│   │   └── explain.sh         # 実行計画確認スクリプト
│   ├── queries/               # SQLクエリファイル
│   └── output/                # CSV出力ディレクトリ（Git管理対象外）
├── mysql/                      # MySQL関連
│   ├── scripts/               # 実行スクリプト
│   │   ├── to_csv.sh         # CSV出力スクリプト
│   │   └── explain.sh        # 実行計画確認スクリプト
│   ├── queries/              # SQLクエリファイル
│   └── output/               # CSV出力ディレクトリ（Git管理対象外）
├── scripts/                   # 統合分析スクリプト
│   ├── media_location_join.sh        # メディア・拠点データ結合
│   ├── registration_location_join.sh # 登録・拠点データ結合
│   └── run_all_reports.sh           # 全レポート一括実行
├── temp/                      # 一時ファイル（Git管理対象外）
└── docs/                      # 追加ドキュメント
```

## 安全な使用のためのルール

1. **VPN接続確認**: データベースアクセス前に必ずVPN接続を確認
2. **パスワード管理**: .pgpassや.my.cnfファイルは他人と共有しない
3. **動作確認**: 大きなクエリを実行する前は必ずEXPLAINで動作確認
4. **定期的な確認**: 不明な結果が出た場合は必ずエンジニアに相談
5. **ファイル管理**: 個人情報を含むCSVファイルは適切に管理・削除
6. **バックアップ**: 重要なクエリはgitで管理して履歴を残す

## 困った時の連絡先

- **技術的な問題**: エンジニアチーム
- **VPN接続問題**: IT部門
- **データベースアクセス権限**: データベース管理者
- **データ分析に関する相談**: データ分析チーム 