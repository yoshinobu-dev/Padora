# Google Play 掲載文案（S2）

> Play Console にコピペする用。`{{...}}` は公開前に差し替え。

## 基本情報

| 項目 | 値 |
|------|-----|
| アプリ名 | Padora |
| カテゴリ | **ツール**（またはエンターテイメント） |
| 料金 | 無料 |
| コンテンツレーティング | 全ユーザー（暴力・性的表現なしのアンケート想定） |

## 短い説明（80 文字以内）

```
PC版ウディタ向け非公式コントローラー。十字・決定・取消を片手操作。要・Windows Host。
```

（79 文字）

## 詳しい説明

```
Padora は、PC でプレイする WOLF RPG エディター製ゲーム（およびキー操作の似たツクール作品）向けの、非公式片手コントローラーです。

【公式・公認ではありません】
WOLF RPG エディター、RPG ツクール、各作品の開発元・権利者との提携はありません。

【必要なもの】
・Android スマートフォン（本アプリ）
・Windows PC 用「Padora Host」（別途ダウンロード必須）
  → {{HOST_DOWNLOAD_URL}}
・VPN / 同一 LAN / USB テザリング等での接続

【想定している操作】
十字キーと Z / X / Shift など、少数のキーで進める RPG・ADV・シミュレーション系（WOLF RPG エディター / ツクール系など）。

【想定していないもの】
格闘・FPS・3D アクションなど、多数のキー入力やスティック（アナログ）操作が必要なゲーム。仮想スティックや多ボタンパッドには対応していません。

【主な機能】
・十字キー（短タップ＝1マス、長押し＝連続移動）
・決定 / 取消 / Shift / カスタムキー
・F4 / F11 チップ
・短タップ触覚、前回 IP 記憶
・ライト / ダークテーマ

【使い方】
1. PC で Host を起動（ファイアウォール許可）
2. Host に表示された PC の IP を本アプリに入力
3. 接続後、ゲームウィンドウを前面にして操作

【プライバシー】
個人情報を当方サーバーへ送信しません。接続 IP は端末内のみに保存されます。
プライバシーポリシー: {{PRIVACY_POLICY_URL}}

【利用規約】
{{TERMS_URL}}

【免責】
本アプリは入力支援ツールです。ゲームの動作・セーブデータ等について保証しません。自己責任でご利用ください。
```

## 法務 URL（公開前に確定）

GitHub 公開後の例:

| 文書 | URL 例 |
|------|--------|
| 利用規約 | `https://github.com/{{OWNER}}/Padora/blob/main/docs/legal/TERMS_ja.md` |
| プライバシー | `https://github.com/{{OWNER}}/Padora/blob/main/docs/legal/PRIVACY_ja.md` |
| Host 配布 | `https://github.com/{{OWNER}}/Padora/releases/latest` |

Play Console では **公開アクセス可能な HTTPS URL** が必要です。GitHub raw または GitHub Pages 推奨。

## データ セーフティ（回答メモ）

詳細: [`DATA_SAFETY.md`](DATA_SAFETY.md)

## グラフィック素材

| 素材 | サイズ | 元ファイル |
|------|--------|------------|
| アイコン | 512×512 PNG | `docs/store/graphics/play-store-icon-512.png` |
| フィーチャーグラフィック | 1024×500 | `docs/store/graphics/play-store-feature-1024x500.png` |

再生成: `python scripts/generate-store-graphics.py`
| スクリーンショット | 縦 2 枚以上 | 実機: メイン画面・設定画面 |

### スクリーンショット（取得済み）

| ファイル | 内容 |
|----------|------|
| `docs/store/screenshots/01-main-controller.png` | メイン画面（ダーク） |
| `docs/store/screenshots/02-settings.png` | 設定（ダーク） |
| `docs/store/screenshots/03-main-controller-light.png` | メイン画面（ライト） |
| `docs/store/screenshots/04-settings-light.png` | 設定（ライト） |

Play Console にアップロード可。4 枚すべて載せるとライト/ダーク両対応が伝わる。最低 2 枚でも可。

（任意）3 枚目: 設定 → **情報 → 非公式について**（法務表示の明示用）

## Play Console チェックリスト

- [ ] 開発者アカウント登録（$25）
- [ ] アプリ作成 → パッケージ名 `com.Padora.Padora_client`
- [ ] AAB アップロード（`flutter build appbundle --release`）
- [ ] 短い説明・詳しい説明
- [ ] グラフィック（アイコン・FG・スクショ）
- [ ] データ セーフティ
- [ ] コンテンツレーティング
- [ ] 対象国・地域
- [ ] プライバシーポリシー URL
- [ ] 内部テスト → 本番（S3 経由推奨）

## AAB ビルド（Play 提出用）

```powershell
cd client
flutter build appbundle --release
# 出力: build\app\outputs\bundle\release\app-release.aab
```

APK 直配布は GitHub Releases、Play 提出は **AAB** を使用。
