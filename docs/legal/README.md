# 法務ドキュメント

| ファイル | 用途 |
|----------|------|
| `TERMS_ja.md` | 利用規約（Play Console URL 用） |
| `PRIVACY_ja.md` | プライバシーポリシー |
| `ABOUT_ja.md` | 非公式説明（アプリ内） |

## アプリ内表示との同期

アプリは `client/assets/legal/` のコピーを読み込みます。  
**本文を変更したら** 以下で同期してください。

```powershell
Copy-Item docs\legal\ABOUT_ja.md client\assets\legal\about_ja.md
Copy-Item docs\legal\TERMS_ja.md client\assets\legal\terms_ja.md
Copy-Item docs\legal\PRIVACY_ja.md client\assets\legal\privacy_ja.md
```

Play Console には **GitHub 上の公開 URL**（`docs/legal/*.md`）を登録します。
