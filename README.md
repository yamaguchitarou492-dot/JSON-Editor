# JSON Editor (iOS, 署名なし IPA)

脱獄 iPad / TrollStore 向けに、署名なしでインストールできる超シンプルな JSON エディタです。Windows だけで完結する経路を用意してあります（Xcode も Mac も不要、ビルドはクラウドの macOS ランナーに任せる方式）。

## できること

- JSON の **整形**（pretty print, ソートキー）
- JSON の **圧縮**（minify）
- JSON の **検証**（バリデーションとエラー位置表示）
- インデント切替（2 / 4 スペース / タブ）
- コピー・貼付・共有シート
- キーボードに `{}[]":`、 のクイック入力

すべてオフラインで動きます。通信は一切しません。

## なぜ Windows だけでビルドできるのか

iOS の `.app` を作るには macOS と Xcode が必須です。Windows 単体では実機向け Mach-O は作れません。  
そこで **GitHub Actions の macOS ランナー（無料枠あり）** を使い、Windows からは git push するだけで IPA が手に入る構成にしています。

ローカルでやることは「ソース編集」と「git push」だけ。ビルドはクラウド側で走ります。

## 手順（最短ルート）

### 1. GitHub にリポジトリを作る

ブラウザで https://github.com/new を開いて、空のリポジトリを 1 つ作る（名前は何でも OK）。Public でも Private でもどちらでも構いません（Private でも macOS ランナーの無料枠は使えます）。

### 2. このフォルダを push

```powershell
cd "C:\Users\enu33\脱獄したIPADだから署名なしIPA作れるよ\JSONEditor"
git init
git add .
git commit -m "init: JSON Editor"
git branch -M main
git remote add origin https://github.com/<あなたのユーザー名>/<リポジトリ名>.git
git push -u origin main
```

### 3. ビルドを待つ

push した瞬間に GitHub Actions が走り出します。  
GitHub のリポジトリページ → **Actions** タブ → 走っているワークフローをクリック。だいたい 5〜10 分で終わります。

### 4. IPA をダウンロード

ワークフロー完了画面の下の方に **Artifacts** セクションが出るので `JSONEditor-ipa` をクリックしてダウンロード。zip を展開すると `JSONEditor.ipa` が入っています。

### 5. iPad にインストール

- **TrollStore**: IPA を Files 経由で開く → 「Install」
- **AppSync Unified 入りの脱獄**: Filza などから直接インストール
- **Sideloadly 等**: 署名付け直しが必要（脱獄不要環境向け）

## ローカルファイル構成

```
JSONEditor/
├── .github/workflows/build.yml    GitHub Actions ワークフロー
├── Sources/
│   ├── JSONEditorApp.swift        @main エントリポイント
│   ├── ContentView.swift          UI 本体（SwiftUI）
│   ├── Info.plist                 バンドル情報
│   └── Assets.xcassets/           アイコン・カラー
├── project.yml                    XcodeGen 設定（.xcodeproj はビルド時に生成）
├── ExportOptions.plist            （現在の workflow では未使用、予備）
├── .gitignore
└── README.md
```

`.xcodeproj` はリポジトリに含めません。CI 側で `xcodegen` が `project.yml` から生成します。

## カスタマイズしたいとき

- **アプリ名を変える**: `project.yml` の `targets:` 配下の `JSONEditor` キーと、`Sources/Info.plist` の `CFBundleDisplayName` を書き換え
- **バンドル ID を変える**: `project.yml` の `PRODUCT_BUNDLE_IDENTIFIER`
- **対応 iOS バージョン**: `project.yml` の `IPHONEOS_DEPLOYMENT_TARGET`（現在 15.0）
- **アイコンを差し替える**: `Sources/Assets.xcassets/AppIcon.appiconset/icon-1024.png` を上書き

## トラブルシューティング

| 症状 | 対処 |
|------|------|
| Actions が走らない | リポジトリ Settings → Actions → "Allow all actions" を確認 |
| Xcode バージョンエラー | `build.yml` の `Xcode_15.4.app` を、Actions のログに出てくる利用可能なバージョンに書き換え |
| `.app not found` | ログの `find build -name "*.app"` 出力を確認、`-derivedDataPath` のパスがずれている可能性 |
| インストール時に「信頼されていない」 | 署名なし IPA なので **TrollStore か脱獄環境専用**。通常 iOS では弾かれます |

## ライセンス

自由に使ってください。
