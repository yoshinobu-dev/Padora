# Padora — ウディタ・RPGツクール向け Android コントローラー（非公式）

**PC版 WOLF RPG エディター（ウディタ）** や **RPGツクール** 系の **フリゲ** を、Android スマホから **片手** で操作したい方向けの **専用仮想パッド** です。

オンスクリーンキーボードのように画面を覆わず、**十字・決定・取消** など少ないボタンだけをスマホに表示し、Windows PC へ **キーボード入力として送ります**。ゲームの実行・エミュレートはしません。

> **非公式** — WOLF RPG エディター / ツクールの公式・公認アプリではありません。

## こんな悩み向け

- ウディタ作品を **スマホの仮想キーボード** で操作するのがつらい
- キーが多く、**片手** や **視線オフ** でプレイしたい
- 既存の汎用リモコンアプリでは **Z / X / 十字** だけの操作に合わない
- PC 版をそのまま遊びたい（エミュレーターは使わない）

## ダウンロード（v1.0.0 プレリリース）

| ファイル | 内容 |
|----------|------|
| [Padora.apk](https://github.com/yoshinobu-dev/Padora/releases/download/v1.0.0/Padora.apk) | Android コントローラー |
| [Padora-Host-win64.zip](https://github.com/yoshinobu-dev/Padora/releases/download/v1.0.0/Padora-Host-win64.zip) | Windows 受信ソフト（.NET 同梱） |

Release ページ: https://github.com/yoshinobu-dev/Padora/releases/tag/v1.0.0

**接続:** v1 は **USB テザリング推奨**（PC の IP を手入力）。Wi‑Fi 自動接続機能はありません。

## 特徴

- 十字 / 決定 / 取消 / Shift に絞ったシンプル操作
- 上部に F4 / F11（表示補助）と設定（歯車）
- 設定からキー割り当て・テーマ・画面常時点灯を変更
- 左下のカスタム枠（F5 などでフルスクリーン切替にも便利）
- 縦持ち最適化（閉じた Fold / 通常スマホ向け）
- 十字・接続ボタンはライト＝黒 / ダーク＝白（アクション色は役割色のまま）

## 構成

| パス | 内容 |
|------|------|
| `client/` | Flutter Android アプリ |
| `host/` | Windows 受信ソフト（C# / .NET 8） |
| `protocol/` | UDP プロトコル |
| `docs/PRODUCT.md` | プロダクト定義・ロードマップ |
| `assets/icons/` | アプリアイコン（採用: D3d） |
| `dist/` | ビルド成果物 |

## 必要環境

- Windows PC（.NET 8 ランタイム / SDK）
- Android スマホ
- **USB ケーブル**（テザリング用。v1 の推奨接続）

> v1 には Wi‑Fi 自動検出などの **無線接続機能はありません**。PC の IP を手入力して UDP 接続します。

## 使い方（配布物）

最新版: **https://github.com/yoshinobu-dev/Padora/releases/tag/v1.0.0**

### 1. Host（PC）

[Release ページ](https://github.com/yoshinobu-dev/Padora/releases/tag/v1.0.0) から `Padora-Host-win64.zip` を取得し、`Padora.Host.exe` を起動します。
起動すると UDP `21780` で待ち受け、画面に入力すべき IP 一覧が表示されます。

### 2. Client（スマホ）

同 Release ページの `Padora.apk` をインストールして起動します。

### 3. 接続（v1）

v1 は **PC の IP を手入力** して Host に UDP 接続します。

#### 推奨: USB テザリング

1. USB で PC とスマホを接続し、**USB テザリング** を有効にする
2. PC で **Host**（`Padora.Host.exe`）を起動（ファイアウォール許可）
3. Host に表示された **PC 側の IP アドレス** をアプリに入力
   - 初回のみ入力。**接続成功後は次回から自動入力**
4. 「接続」を押す（設定で「起動時に自動接続」を ON にすると省略可）
5. 前面のゲーム（またはメモ帳）をアクティブにして操作

> 入力するのはスマホ自身の IP ではなく、Host に表示された **PC 側の IP** です。

#### 上級者向け

同一 LAN や VPN など、**PC の IP が分かる環境** でも同様に接続できます（手動 IP 入力が必要）。v1 時点での主な想定・サポート対象は **USB テザリング** です。

### 4. 操作

| UI | デフォルトキー |
|----|----------------|
| 十字 | ↑ ↓ ← →（**短タップ＝1マス**、長押し＝連続移動） |
| 決定 | Z |
| 取消 | X |
| Shift枠 | Shift |
| カスタム枠 | 未設定（設定で割り当て） |
| F4 / F11 | F4 / F11 |

キー変更・接続・テーマ・「画面を消灯しない」・**短タップの触覚**は右上の **歯車** から行います。  
ボタン長押しでは設定を開きません（連打しやすいようにしています）。

## よくある質問

**Q. ウディタ / ツクール以外でも使えますか？**  
A. キーボード操作の似た PC ゲームなら動く可能性がありますが、**ウディタ・ツクール系向け** に設計しています。

**Q. スマホ単体でゲームは動きますか？**  
A. いいえ。 **Windows PC 上のゲーム** を、スマホをコントローラーとして操作します。

**Q. Google Play から入れられますか？**  
A. 現状は **GitHub Release** からの配布のみです（プレリリース）。

**Q. 無線（Wi‑Fi）だけで接続できますか？**  
A. v1 は **USB テザリング推奨** です。同一 LAN 等でも PC の IP が分かれば接続可能ですが、自動検出はありません。

## 開発者向け

### ビルド

```powershell
# 初回のみ: Android 署名 keystore
.\scripts\setup-android-signing.ps1

# S1 配布物一式（署名 APK + Host ZIP + SHA256）
.\scripts\release-s1.ps1
```

GitHub Release 例:

```powershell
git tag v1.0.0
git push origin v1.0.0
gh release create v1.0.0 `
  dist/android/Padora.apk `
  dist/Padora-Host-win64.zip `
  dist/SHA256SUMS.txt `
  --title "Padora 1.0.0" `
  --notes-file docs/release-notes/v1.0.0.md
```

#### 個別ビルド

```powershell
# Android APK
cd client
flutter pub get
dart run flutter_launcher_icons
flutter build apk --release

# Windows Host（self-contained 単一 exe → dist/host-win64/）
dotnet publish host\Padora.Host\Padora.Host.csproj -c Release -r win-x64 `
  --self-contained true -p:PublishSingleFile=true `
  -p:IncludeNativeLibrariesForSelfExtract=true -o dist\host-win64
```

### 通信

- UDP / ポート `21780`
- 6 バイト固定パケット（押下・離上）
- 詳細は `protocol/PROTOCOL.md`

## 方針メモ（将来公開時）

| | 無料（想定） | 有料（想定） |
|--|--------------|--------------|
| 操作・キー割り当て | あり | — |
| 接続 | 手動 IP など | より手軽な無線体験 |
| 見た目 | 標準色 | カラーカスタム |

公式・公認ではありません。WOLF RPGエディター / ツクールのロゴ・素材は使いません。

## ドキュメント

- プロダクト定義: [`docs/PRODUCT.md`](docs/PRODUCT.md)
- 法務: [`docs/legal/`](docs/legal/)
- リリースノート: [`docs/release-notes/`](docs/release-notes/)
- プロトコル: [`protocol/PROTOCOL.md`](protocol/PROTOCOL.md)
