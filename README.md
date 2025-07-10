# PhotoMetaKit

**PhotoMetaKit** 是一個 iOS Swift SDK，讓 App 端可以輕鬆取得照片的 EXIF/Metadata，並將其儲存到本地 SQLite 資料庫。

## 功能特色

- 支援接收 `UIImage` 或本地圖片檔案（`URL`）
- 自動解析照片 EXIF/Metadata
- 將 metadata 以 JSON 格式存入本地 SQLite
- Swift Package Manager（SPM）封裝，安裝簡單

---

## 安裝方式

### Swift Package Manager

1. 在 Xcode 專案選單：**File > Add Packages...**
2. 輸入本套件的 GitHub 連結：

   ```
   https://github.com/simonwell-AI/PhotoMetaKit
   ```

3. 選擇版本或 branch，點選「Add Package」

---

## 使用方式

### 1. 匯入套件

```swift
import PhotoMetaKit
```

### 2. 處理照片

#### 處理 UIImage

```swift
PhotoMetaKitManager.shared.processImage(yourUIImage)
```

#### 處理本地圖片檔案

```swift
PhotoMetaKitManager.shared.processImage(at: yourImageURL)
```

---

## 資料儲存位置

- metadata 會以 JSON 字串形式，連同檔案路徑存入 App 沙盒內的 SQLite 資料庫（`photometakit.sqlite3`）。

---

## 依賴

- [SQLite.swift](https://github.com/stephencelis/SQLite.swift)

---

## 授權

MIT License

---

## 聯絡

如有問題或建議，歡迎開 issue 或 PR！

---

> 本專案 GitHub 位置： [https://github.com/simonwell-AI/PhotoMetaKit](https://github.com/simonwell-AI/PhotoMetaKit) 