# Padora — リリース手順（S1）

## 前提

- Flutter SDK / .NET 8 SDK
- 初回のみ: `scripts/setup-android-signing.ps1`（keystore 生成）
- **keystore と key.properties は必ずバックアップ**（紛失すると Play 更新不可）

## ビルド

```powershell
.\scripts\release-s1.ps1
```

### 成果物（`dist/`）

| ファイル | 内容 |
|----------|------|
| `android/Padora.apk` | リリース署名済み Android アプリ |
| `Padora-Host-win64.zip` | .NET 同梱・単一 exe（`Padora.Host.exe`） |
| `SHA256SUMS.txt` | チェックサム |

> 配布の正本は **`dist/host-win64/`** と **`dist/android/`**。  
> 旧 `dist/host` / `host-d3d` / `host-new` は開発残り — 公開には使わない。

## GitHub Releases

```powershell
# タグ作成（例）
git tag v1.0.0
git push origin v1.0.0

# Release 作成（GitHub CLI）
gh release create v1.0.0 `
  dist/android/Padora.apk `
  dist/Padora-Host-win64.zip `
  dist/SHA256SUMS.txt `
  --title "Padora 1.0.0" `
  --notes-file docs/release-notes/v1.0.0.md
```

`docs/release-notes/` にバージョンごとのメモを置く。

## バージョン更新

1. `client/pubspec.yaml` — `version: x.y.z+build`
2. `host/Padora.Host/Padora.Host.csproj` — `<Version>` / `AssemblyVersion`
3. `client/lib/app_version.dart` — `name` / `build`（設定画面表示）
4. 再ビルド → タグ → Release

## Host 単体ビルド

```powershell
dotnet publish host\Padora.Host\Padora.Host.csproj `
  -c Release -r win-x64 `
  --self-contained true `
  -p:PublishSingleFile=true `
  -p:IncludeNativeLibrariesForSelfExtract=true `
  -o dist\host-win64
```

## 注意

- Padora は **非公式** ツール。Release notes に Host 必須・VPN/LAN 等を記載。
- UDP 認証なし — 同一ネットワーク前提。
