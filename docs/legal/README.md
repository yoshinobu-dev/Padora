# 法務ドキュメント

| ファイル | 用途 |
|----------|------|
| `TERMS_ja.md` | 利用規約（Play Console URL 用） |
| `PRIVACY_ja.md` | プライバシーポリシー |
| `ABOUT_ja.md` | 非公式説明（アプリ内） |

## Play Console 用 URL（登録時にコピー）

| 項目 | URL |
|------|-----|
| **プライバシーポリシー** | https://github.com/yoshinobu-dev/Padora/blob/master/docs/legal/PRIVACY_ja.md |
| **利用規約**（求められた場合） | https://github.com/yoshinobu-dev/Padora/blob/master/docs/legal/TERMS_ja.md |
| **ウェブサイト**（任意） | https://github.com/yoshinobu-dev/Padora |
| **Host 配布**（説明文に記載） | https://github.com/yoshinobu-dev/Padora/releases/tag/v1.0.0 |
| **問い合わせ**（Issues） | https://github.com/yoshinobu-dev/Padora/issues |

> `raw.githubusercontent.com` は Markdown がそのまま表示されるため、規約 URL には **`blob/master/...`** を使ってください。

## アプリ内表示との同期

アプリは `client/assets/legal/` のコピーを読み込みます。  
**本文を変更したら** 以下で同期してください。

```powershell
Copy-Item docs\legal\ABOUT_ja.md client\assets\legal\about_ja.md
Copy-Item docs\legal\TERMS_ja.md client\assets\legal\terms_ja.md
Copy-Item docs\legal\PRIVACY_ja.md client\assets\legal\privacy_ja.md
```
