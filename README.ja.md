[English](README.md) | 日本語

# dashboardapi

[![R-CMD-check](https://github.com/kenjimyzk/dashboardapi/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/kenjimyzk/dashboardapi/actions/workflows/R-CMD-check.yaml)

`dashboardapi` は、総務省統計局の「統計ダッシュボード WebAPI」へ
アクセスするための非公式 R パッケージです。API キーや利用登録は不要です。

基本的な使い方は `bojapi` や `WDI` と同じ発想です。まずメタデータを
検索して系列コードを見つけ、必要な地域コードを確認し、最後に観測値を
整然データとして取得します。

## 主な機能

- `dashboard_search()` / `dashboard_indicators()`：系列を検索し、周期、
  地域階級、季節調整、単位、出典、収録期間を確認
- `dashboard_regions()`：都道府県・市区町村・国の地域コードを検索
- `dashboard_data()`：観測値を long 形式または wide 形式で取得
- `dashboard_terms()`、`dashboard_events()`、`dashboard_surveys()`：
  用語、社会事象、統計調査の補助メタデータを取得
- `dashboard_codes()`：主な API コード表をオフラインで確認
- API 上限（1リクエストにつき系列5件、地域50件）を超える指定を自動分割
- 日本語・英語レスポンス、再試行、タイムアウト、分割取得時のアクセス間隔
- API・HTTP・解析・該当データなしを区別できる condition class

## インストール

GitHub から開発版をインストールできます。

```r
install.packages("remotes")
remotes::install_github("kenjimyzk/dashboardapi")
```

リポジトリをクローンしたローカルディレクトリからインストールする場合は、
次のように実行します。

```r
remotes::install_local(".")
```

## クイックスタート

```r
library(dashboardapi)

# 1. 系列を検索
population_meta <- dashboard_search(
  "総人口（男女計）",
  lang = "jp"
)

population_meta[, c(
  "indicator_code", "name", "cycle_name",
  "regional_rank_name", "unit"
)]

# 2. 都道府県コードを確認
prefectures <- dashboard_regions(
  parent_region_code = "00000",
  lang = "jp"
)

# 3. 日本の年次人口を取得
population <- dashboard_data(
  indicator_code = c(population = "0201010000000010000"),
  region_code = "00000",
  time_from = "2020CY00",
  time_to = "2024CY00",
  cycle = "year",
  regional_rank = "japan",
  seasonal = "original",
  lang = "jp"
)
```

`time` 列は API の期間コードをそのまま保持します。分析用の `date` 列は、
各期間の初日です。たとえば `20240100` は 2024-01-01、`20242Q00` は
2024-04-01、`2024CY00` は 2024-01-01、`2024FY00` は 2024-04-01 に
変換されます。

## 都道府県の例

```r
prefecture_population <- dashboard_data(
  indicator_code = c(population = "0201010000000010000"),
  region_code = c("13000", "27000"),
  time_from = "2020CY00",
  time_to = "2024CY00",
  cycle = "year",
  regional_rank = "prefecture",
  seasonal = "original",
  wide = TRUE
)
```

## アクセス間隔とエラー

公式ページでは、短時間の大量アクセスを行わないよう求めています。
系列5件または地域50件を超える指定は自動分割し、分割リクエスト間で
最低1秒待機します。

```r
options(
  dashboardapi.wait = 2,
  dashboardapi.timeout = 60,
  dashboardapi.retries = 3
)
```

API 応答エラーは `dashboard_api_response_error`、通信エラーは
`dashboard_http_error`、予期しない応答構造は `dashboard_parse_error`
です。正常終了でも該当データがない場合は `dashboard_no_data_warning`
を出し、列型の揃った空の tibble を返します。

## 出典表示と公開サービスのクレジット

統計ダッシュボードのコンテンツを公開利用する場合、公式のコピーライト
ポリシーは次の三点を区別しています。

1. 出典を表示する。
2. データ・コンテンツを加工して利用する場合は、加工したことと加工主体を
   表示する。
3. API を使ったサービスを公開する場合は、指定の API クレジットを表示する。

`dashboard_api_credit()` は、出典、加工時の表示例、API クレジットを返します。
加工時の `<作成主体>` は公開前に置き換えてください。

```r
attribution <- dashboard_api_credit("jp")
attribution$source
attribution$processed
attribution$credit
```

`dashboardapi` は独立して開発された非公式パッケージであり、総務省統計局
による承認・推奨を受けたものではありません。MIT ライセンスは、
政府・第三者のデータ、メタデータ、コード体系、公式文書を再許諾しません。
第三者由来のコンテンツを再利用する場合は、個別の権利表示も確認してください。

## 公式資料

- [統計ダッシュボード API](https://dashboard.e-stat.go.jp/static/api)
- [統計ダッシュボード サイトポリシー](https://dashboard.e-stat.go.jp/static/sitePolicy)
