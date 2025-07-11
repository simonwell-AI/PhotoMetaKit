import Foundation
import UIKit
import ImageIO
import SQLite
import Supabase

public class PhotoMetaKitManager {
    public static let shared = PhotoMetaKitManager()
    public let supabase: SupabaseClient

    private init() {
        let supabaseURL = URL(string: "https://sqgdfeiqqnxrzxpaexzh.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNxZ2RmZWlxcW54cnp4cGFleHpoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMjQ1NDAsImV4cCI6MjA2NzgwMDU0MH0.QWpRX5tYRQM3ph8ph04z7nSNqAM3dJ_rsOitTEdYrqw"
        self.supabase = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
    
    // MARK: - 處理圖片
    
    /// 處理 UIImage，會先存到暫存路徑再解析
    /// - Parameter image: 要處理的 UIImage
    /// - Returns: 是否成功處理
    @discardableResult
    public func processImage(_ image: UIImage) -> Bool {
        guard let data = image.jpegData(compressionQuality: 1.0) else {
            print("無法轉換 UIImage 為 JPEG 資料")
            return false
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        do {
            try data.write(to: fileURL)
            let success = processImage(at: fileURL)
            
            // 清理暫存檔案
            try? FileManager.default.removeItem(at: fileURL)
            
            return success
        } catch {
            print("儲存圖片失敗: \(error)")
            return false
        }
    }
    
    /// 處理本地圖片檔案
    /// - Parameter url: 圖片檔案的 URL
    /// - Returns: 是否成功處理
    @discardableResult
    public func processImage(at url: URL) -> Bool {
        // 檢查檔案是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("檔案不存在: \(url.path)")
            return false
        }
        
        // 檢查是否為支援的圖片格式
        guard isSupportedImageFormat(url: url) else {
            print("不支援的圖片格式: \(url.pathExtension)")
            return false
        }
        
        // 檢查照片是否已存在於資料庫中
        if PhotoMetaDatabase.shared.photoExists(filePath: url.path) {
            print("照片已存在於資料庫中: \(url.path)")
            return true
        }
        
        guard let metadata = extractMetadata(from: url) else {
            print("無法取得 metadata: \(url.path)")
            return false
        }
        
        // 將 metadata 轉換為 JSON 字串（但 insertPhoto 需傳原始字典）
        guard let metadataString = convertMetadataToString(metadata) else {
            print("無法轉換 metadata 為字串: \(url.path)")
            return false
        }
        let result = PhotoMetaDatabase.shared.insertPhoto(filePath: url.path, metadata: metadata)
        if result != nil {
            print("成功處理照片: \(url.path)")
            return true
        } else {
            print("插入資料庫失敗: \(url.path)")
            return false
        }
    }
    
    /// 批次處理多張圖片
    /// - Parameter urls: 圖片檔案的 URL 陣列
    /// - Returns: 成功處理的圖片數量
    @discardableResult
    public func processImages(at urls: [URL]) -> Int {
        var successCount = 0
        for url in urls {
            if processImage(at: url) {
                successCount += 1
            }
        }
        print("批次處理完成: \(successCount)/\(urls.count) 張圖片成功處理")
        return successCount
    }
    
    // MARK: - 查詢功能
    
    /// 取得所有照片的 metadata
    public func getAllPhotos() -> [(id: Int64, filePath: String, metadata: [String: Any])] {
        let photos = PhotoMetaDatabase.shared.getAllPhotos()
        return photos.compactMap { photo in
            if let metadataDict = parseMetadataString(photo.metadata) {
                return (photo.id, photo.filePath, metadataDict)
            }
            return nil
        }
    }
    
    /// 根據檔案路徑取得照片的 metadata
    public func getPhotoMetadata(filePath: String) -> [String: Any]? {
        guard let photo = PhotoMetaDatabase.shared.getPhoto(byFilePath: filePath) else {
            return nil
        }
        return parseMetadataString(photo.metadata)
    }
    
    /// 搜尋照片 (簡單的檔案名稱搜尋)
    public func searchPhotos(by keyword: String) -> [(id: Int64, filePath: String, metadata: [String: Any])] {
        let allPhotos = PhotoMetaDatabase.shared.getAllPhotos()
        let filteredPhotos = allPhotos.filter { photo in
            let fileName = (photo.filePath as NSString).lastPathComponent
            return fileName.lowercased().contains(keyword.lowercased())
        }
        
        return filteredPhotos.compactMap { photo in
            if let metadataDict = parseMetadataString(photo.metadata) {
                return (photo.id, photo.filePath, metadataDict)
            }
            return nil
        }
    }
    
    /// 取得照片數量
    public func getPhotoCount() -> Int {
        return PhotoMetaDatabase.shared.getPhotoCount()
    }
    
    /// 刪除照片記錄
    @discardableResult
    public func deletePhoto(filePath: String) -> Bool {
        // 先根據檔案路徑找到 ID
        guard let photo = PhotoMetaDatabase.shared.getPhoto(byFilePath: filePath) else {
            print("找不到照片記錄: \(filePath)")
            return false
        }
        return PhotoMetaDatabase.shared.deletePhoto(photoId: photo.id)
    }
    
    /// 清空所有照片記錄
    @discardableResult
    public func deleteAllPhotos() -> Bool {
        return PhotoMetaDatabase.shared.clearAllPhotos()
    }
    
    /// 將本地所有 user_photos 上傳到 Supabase
    public func uploadAllPhotosToSupabase(completion: @escaping (Bool, Error?) -> Void) {
        let allPhotos = PhotoMetaDatabase.shared.getAllPhotos()
        let supabasePhotos: [SupabasePhoto] = allPhotos.map { photo in
            SupabasePhoto(
                filepath: photo.filePath,
                metadata: photo.metadata
                // embedding: ...
            )
        }
        let table = supabase.database.from("user_photos")
        Task {
            do {
                let _ = try await table.upsert(supabasePhotos, onConflict: "filepath").execute()
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 解析 EXIF/Metadata
    private func extractMetadata(from url: URL) -> [String: Any]? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }
        
        // 添加檔案資訊
        var enhancedMetadata = metadata
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
            enhancedMetadata["FileSize"] = fileAttributes[.size] as? Int64
            enhancedMetadata["FileCreationDate"] = fileAttributes[.creationDate] as? Date
            enhancedMetadata["FileModificationDate"] = fileAttributes[.modificationDate] as? Date
        }
        
        // 添加檔案名稱和副檔名
        enhancedMetadata["FileName"] = url.lastPathComponent
        enhancedMetadata["FileExtension"] = url.pathExtension
        
        return enhancedMetadata
    }
    
    /// 檢查是否為支援的圖片格式
    private func isSupportedImageFormat(url: URL) -> Bool {
        let supportedExtensions = ["jpg", "jpeg", "png", "heic", "heif", "tiff", "tif", "gif", "bmp"]
        return supportedExtensions.contains(url.pathExtension.lowercased())
    }
    
    /// 將 metadata 字典轉換為 JSON 字串
    private func convertMetadataToString(_ metadata: [String: Any]) -> String? {
        // 需要處理非 JSON 兼容的類型
        let jsonCompatibleMetadata = convertToJSONCompatible(metadata)
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonCompatibleMetadata, options: [.prettyPrinted])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("轉換 metadata 為 JSON 失敗: \(error)")
            return nil
        }
    }
    
    /// 將 metadata 轉換為 JSON 兼容格式
    private func convertToJSONCompatible(_ object: Any) -> Any {
        if let dict = object as? [String: Any] {
            var result: [String: Any] = [:]
            for (key, value) in dict {
                result[key] = convertToJSONCompatible(value)
            }
            return result
        } else if let array = object as? [Any] {
            return array.map { convertToJSONCompatible($0) }
        } else if let date = object as? Date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: date)
        } else if let number = object as? NSNumber {
            return number
        } else if let string = object as? String {
            return string
        } else {
            // 對於其他類型，轉換為字串
            return String(describing: object)
        }
    }
    
    /// 將 JSON 字串轉換為字典
    private func parseMetadataString(_ metadataString: String) -> [String: Any]? {
        guard let data = metadataString.data(using: .utf8) else { return nil }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print("解析 metadata JSON 失敗: \(error)")
            return nil
        }
    }
}

// MARK: - 便利擴展

public extension PhotoMetaKitManager {
    
    /// 取得特定照片的 EXIF 資訊
    func getEXIFData(filePath: String) -> [String: Any]? {
        guard let metadata = getPhotoMetadata(filePath: filePath) else { return nil }
        return metadata[kCGImagePropertyExifDictionary as String] as? [String: Any]
    }
    
    /// 取得特定照片的 GPS 資訊
    func getGPSData(filePath: String) -> [String: Any]? {
        guard let metadata = getPhotoMetadata(filePath: filePath) else { return nil }
        return metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any]
    }
    
    /// 取得特定照片的拍攝時間
    func getPhotoDateTime(filePath: String) -> Date? {
        guard let exifData = getEXIFData(filePath: filePath),
              let dateTimeString = exifData[kCGImagePropertyExifDateTimeOriginal as String] as? String else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: dateTimeString)
    }
    
    /// 取得特定照片的相機資訊
    func getCameraInfo(filePath: String) -> (make: String?, model: String?)? {
        guard let metadata = getPhotoMetadata(filePath: filePath) else { return nil }
        
        let make = metadata[kCGImagePropertyTIFFMake as String] as? String
        let model = metadata[kCGImagePropertyTIFFModel as String] as? String
        
        return (make, model)
    }
}

/// 上傳用 struct
private struct SupabasePhoto: Encodable {
    let filepath: String
    let metadata: String
    // let embedding: String? // 如有需要可加
}
