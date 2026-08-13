# Play Store グラフィック

| ファイル | サイズ | 用途 |
|----------|--------|------|
| `play-store-icon-512.png` | 512×512 | Play Console アイコン |
| `play-store-feature-1024x500.png` | 1024×500 | フィーチャーグラフィック |

## 再生成

```powershell
python scripts/generate-store-graphics.py
```

元アイコン: `assets/icons/Padora-icon-d3d.png`

## キャッチコピー（FG 内）

- Padora
- 片手ウディタコントローラー
- 十字 · 決定 · 取消
- 非公式 · Windows Host とセット
- 1マス移動 · 短タップ触覚 · ライト/ダーク

文言変更は `scripts/generate-store-graphics.py` を編集して再実行。
