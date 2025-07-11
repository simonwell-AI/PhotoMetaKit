# PhotoMetaKit

**PhotoMetaKit** 是一個 iOS Swift SDK，讓 App 端可以輕鬆取得照片的 EXIF/Metadata，並將其儲存到本地 SQLite 資料庫。

## 功能特色

- 支援接收 `UIImage` 或本地圖片檔案（`URL`）
- 自動解析照片 EXIF/Metadata
- 將 metadata 以 JSON 格式存入本地 SQLite
- 支援批次處理多張照片
- 提供完整的查詢、搜尋、刪除功能
- 便利的 EXIF、GPS、拍攝時間提取方法
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
// 處理單張 UIImage
let success = PhotoMetaKitManager.shared.processImage(yourUIImage)
if success {
    print("照片處理成功")
}
```

#### 處理本地圖片檔案

```swift
// 處理單張本地圖片
let success = PhotoMetaKitManager.shared.processImage(at: yourImageURL)
if success {
    print("照片處理成功")
}
```

#### 批次處理多張照片

```swift
// 批次處理多張照片
let imageUrls = [url1, url2, url3, url4]
let successCount = PhotoMetaKitManager.shared.processImages(at: imageUrls)
print("成功處理 \(successCount) 張照片")
```

### 3. 查詢照片資訊

#### 取得所有照片

```swift
let allPhotos = PhotoMetaKitManager.shared.getAllPhotos()
for photo in allPhotos {
    print("照片路徑: \(photo.filePath)")
    print("照片 ID: \(photo.id)")
    // photo.metadata 包含完整的 metadata 字典
}
```

#### 取得特定照片的 Metadata

```swift
if let metadata = PhotoMetaKitManager.shared.getPhotoMetadata(filePath: "/path/to/photo.jpg") {
    print("照片的 metadata: \(metadata)")
}
```

#### 搜尋照片

```swift
// 根據檔案路徑關鍵字搜尋
let searchResults = PhotoMetaKitManager.shared.searchPhotos(by: "vacation")
print("找到 \(searchResults.count) 張相關照片")
```

#### 取得照片數量

```swift
let photoCount = PhotoMetaKitManager.shared.getPhotoCount()
print("資料庫中共有 \(photoCount) 張照片")
```

### 4. 便利功能

#### 取得 EXIF 資訊

```swift
if let exifData = PhotoMetaKitManager.shared.getEXIFData(filePath: "/path/to/photo.jpg") {
    print("相機設定: \(exifData)")
}
```

#### 取得 GPS 定位資訊

```swift
if let gpsData = PhotoMetaKitManager.shared.getGPSData(filePath: "/path/to/photo.jpg") {
    print("拍攝地點: \(gpsData)")
}
```

#### 取得拍攝時間

```swift
if let photoDate = PhotoMetaKitManager.shared.getPhotoDateTime(filePath: "/path/to/photo.jpg") {
    print("拍攝時間: \(photoDate)")
}
```

#### 取得相機資訊

```swift
if let cameraInfo = PhotoMetaKitManager.shared.getCameraInfo(filePath: "/path/to/photo.jpg") {
    print("相機品牌: \(cameraInfo.make ?? "未知")")
    print("相機型號: \(cameraInfo.model ?? "未知")")
}
```

### 5. 管理功能

#### 刪除照片記錄

```swift
// 刪除特定照片記錄
let success = PhotoMetaKitManager.shared.deletePhoto(filePath: "/path/to/photo.jpg")
if success {
    print("照片記錄已刪除")
}
```

#### 清空所有照片記錄

```swift
let success = PhotoMetaKitManager.shared.deleteAllPhotos()
if success {
    print("所有照片記錄已清空")
}
```

---

## 完整範例

### UIKit 範例

```swift
import PhotoMetaKit
import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 示範完整的使用流程
        demoPhotoMetaKit()
    }
    
    func demoPhotoMetaKit() {
        // 1. 處理照片
        guard let image = UIImage(named: "sample_photo") else { return }
        
        let success = PhotoMetaKitManager.shared.processImage(image)
        if success {
            print("✅ 照片處理成功")
            
            // 2. 查詢資料
            let photoCount = PhotoMetaKitManager.shared.getPhotoCount()
            print("📊 資料庫中共有 \(photoCount) 張照片")
            
            // 3. 取得所有照片
            let allPhotos = PhotoMetaKitManager.shared.getAllPhotos()
            for photo in allPhotos {
                print("📸 照片: \(photo.filePath)")
                
                // 4. 取得詳細資訊
                if let photoDate = PhotoMetaKitManager.shared.getPhotoDateTime(filePath: photo.filePath) {
                    print("🕒 拍攝時間: \(photoDate)")
                }
                
                if let cameraInfo = PhotoMetaKitManager.shared.getCameraInfo(filePath: photo.filePath) {
                    print("📷 相機: \(cameraInfo.make ?? "未知") \(cameraInfo.model ?? "未知")")
                }
            }
        }
    }
}
```

### SwiftUI 範例

```swift
import SwiftUI
import PhotoMetaKit

struct ContentView: View {
    @State private var photos: [(id: Int64, filePath: String, metadata: [String: Any])] = []
    @State private var photoCount: Int = 0
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var processingStatus = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // 狀態顯示
                VStack {
                    Text("資料庫中共有 \(photoCount) 張照片")
                        .font(.headline)
                        .padding()
                    
                    if !processingStatus.isEmpty {
                        Text(processingStatus)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                
                // 按鈕區域
                VStack(spacing: 16) {
                    // 選擇照片按鈕
                    Button("選擇照片") {
                        showingImagePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    // 重新整理按鈕
                    Button("重新整理") {
                        refreshData()
                    }
                    .buttonStyle(.bordered)
                    
                    // 清空資料按鈕
                    Button("清空所有照片") {
                        clearAllPhotos()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
                .padding()
                
                // 照片列表
                List {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        PhotoRowView(photo: photo)
                    }
                }
                .refreshable {
                    refreshData()
                }
            }
            .navigationTitle("PhotoMetaKit Demo")
            .onAppear {
                refreshData()
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { image in
            if let image = image {
                processImage(image)
            }
        }
    }
    
    // MARK: - 功能方法
    
    private func refreshData() {
        photos = PhotoMetaKitManager.shared.getAllPhotos()
        photoCount = PhotoMetaKitManager.shared.getPhotoCount()
        processingStatus = "資料已更新"
        
        // 清除狀態訊息
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            processingStatus = ""
        }
    }
    
    private func processImage(_ image: UIImage) {
        processingStatus = "處理照片中..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = PhotoMetaKitManager.shared.processImage(image)
            
            DispatchQueue.main.async {
                if success {
                    processingStatus = "✅ 照片處理成功"
                    refreshData()
                } else {
                    processingStatus = "❌ 照片處理失敗"
                }
                
                // 清除狀態訊息
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    processingStatus = ""
                }
            }
        }
    }
    
    private func clearAllPhotos() {
        let success = PhotoMetaKitManager.shared.deleteAllPhotos()
        if success {
            processingStatus = "✅ 所有照片已清空"
            refreshData()
        } else {
            processingStatus = "❌ 清空失敗"
        }
    }
}

// MARK: - 照片行視圖

struct PhotoRowView: View {
    let photo: (id: Int64, filePath: String, metadata: [String: Any])
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 檔案路徑
            Text(URL(fileURLWithPath: photo.filePath).lastPathComponent)
                .font(.headline)
                .lineLimit(1)
            
            // 拍攝時間
            if let photoDate = PhotoMetaKitManager.shared.getPhotoDateTime(filePath: photo.filePath) {
                Text("🕒 拍攝時間: \(photoDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 相機資訊
            if let cameraInfo = PhotoMetaKitManager.shared.getCameraInfo(filePath: photo.filePath) {
                Text("📷 相機: \(cameraInfo.make ?? "未知") \(cameraInfo.model ?? "未知")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 檔案大小
            if let fileSize = photo.metadata["FileSize"] as? Int64 {
                Text("📁 檔案大小: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - 圖片選擇器

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - App 入口

@main
struct PhotoMetaKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## 資料儲存位置

- metadata 會以 JSON 字串形式，連同檔案路徑存入 App 沙盒內的 SQLite 資料庫（`photometakit.sqlite3`）。

---

## 支援的圖片格式

- JPEG (.jpg, .jpeg)
- PNG (.png)
- HEIC (.heic)
- HEIF (.heif)
- TIFF (.tiff, .tif)
- GIF (.gif)
- BMP (.bmp)

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