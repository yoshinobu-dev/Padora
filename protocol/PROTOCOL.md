# Padora 通信プロトコル（草案）

有線（USBテザリング）と無線（Wi‑Fi / VPN）で同じペイロードを使う。

## トランスポート

| 項目 | 値 |
|------|-----|
| 方式 | UDP |
| デフォルトポート | `21780` |
| 向き | Client (Android) → Host (Windows) |
| 文字コード | バイナリ（リトルエンディアン） |

## パケット（v1）

固定 6 バイト。

| Offset | Size | 内容 |
|--------|------|------|
| 0 | 1 | Magic `0x57` ('W') |
| 1 | 1 | Version `1` |
| 2 | 1 | Button ID |
| 3 | 1 | State: `1`=pressed, `0`=released |
| 4 | 2 | Sequence (uint16, wrap around) |

### Button ID

| ID | キー |
|----|------|
| 1 | ↑ |
| 2 | ↓ |
| 3 | ← |
| 4 | → |
| 10 | Z |
| 11 | X |
| 12 | Shift |
| 13 | Enter |
| 14 | Space |
| 15 | Esc |
| 16 | C |
| 17 | A |
| 18 | S |
| 20 | F4 |
| 21 | F11 |
| 22 | F5 |
| 23 | F8 |
| 24 | F12 |

デフォルトUI割当: 決定=Z, 取消=X, サブ=Shift。カスタム枠は未設定可。

## ホスト動作

1. UDPを待受
2. Magic / Version を検証
3. pressed → 対応キー Down、released → Up（`SendInput`）
4. 不明IDは無視
5. 再送は要求しない（操作は新鮮さ優先）
