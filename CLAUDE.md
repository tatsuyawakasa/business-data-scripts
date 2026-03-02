# Business Data Scripts - Claude Code指示書

## プロジェクト概要

CoDMONサービスのビジネスデータ分析ツールセット。PostgreSQL・MySQLデータベースからデータを抽出し、CSV形式でレポートを生成する。生成したCSVはGoogle Spreadsheetsへ自動同期される。

## ディレクトリ構成

```
business-data-scripts/
├── postgresql/
│   ├── scripts/          # to_csv.sh, explain.sh
│   ├── queries/          # SQLクエリファイル
│   └── output/           # CSV出力（gitignore）
├── mysql/
│   ├── scripts/          # to_csv.sh, explain.sh
│   ├── queries/          # SQLクエリファイル
│   └── output/           # CSV出力（gitignore）
├── scripts/
│   ├── run_all_reports.sh          # 全レポート一括実行（メインエントリポイント）
│   ├── run_all_reports_scheduled.sh # launchd用ラッパー（PATH設定・ログ記録）
│   ├── connect_vpn.sh              # AWS VPN Client自動接続
│   ├── disconnect_vpn.sh           # AWS VPN Client切断
│   ├── manage_tailscale.sh         # Tailscale一時停止・再開
│   ├── media_location_join.sh      # メディア×ロケーション結合分析
│   ├── registration_location_join.sh # 登録×ロケーション結合分析
│   └── child_anonymous_analysis.sh # 所属クラス未登録こども分析
├── config/               # 設定テンプレート
├── output/               # 統合レポート出力（gitignore）
└── temp/                 # 一時ファイル（gitignore）
```

## DB接続情報

### PostgreSQL
- ホスト: `~/.pgpass`に記載（RDS: `*.crr6umkkdk7n.ap-northeast-1.rds.amazonaws.com`）
- ポート: 5432
- 認証: `~/.pgpass`（chmod 600）

### MySQL
- ホスト: `~/.my.cnf`に記載（RDS: `*.crr6umkkdk7n.ap-northeast-1.rds.amazonaws.com`）
- ポート: 3306
- 認証: `~/.my.cnf`（chmod 600）

## VPN接続要件

- データベースはAWS VPC内にあり、**AWS VPN Client**での接続が必須
- **Tailscaleとの競合**: TailscaleのMagicDNSとルーティングがAWS VPNと干渉するため、`run_all_reports.sh`はVPN接続前にTailscaleを一時停止し、完了後に復元する
- `scripts/manage_tailscale.sh`がTailscaleの停止・再開を担当

## 主要スクリプトの実行方法

```bash
# 全レポート一括実行（通常はこれだけ）
./scripts/run_all_reports.sh

# 個別のCSV出力
./postgresql/scripts/to_csv.sh -f postgresql/queries/XXX.sql output/result.csv
./mysql/scripts/to_csv.sh -f mysql/queries/XXX.sql output/result.csv
```

## Google Sheets同期

- sheet-mirrorプロジェクト（`/Users/t_wakasa/Cursor/projects/sheet-mirror`）と連携
- `run_all_reports.sh`内で`npm start`により自動実行

## 定期実行

- **launchd** LaunchAgent: `~/Library/LaunchAgents/com.t-wakasa.weekly-reports.plist`
- スケジュール: 毎週月曜 00:01
- ラッパー: `scripts/run_all_reports_scheduled.sh`（iTerm2経由で実行）

## セキュリティルール

- `~/.pgpass`、`~/.my.cnf`等の認証情報をgitに含めない
- output/、temp/ディレクトリはgitignore済み
- CSVファイルに個人情報が含まれる場合は適切に管理・削除する
