import Foundation
import UIKit
import ImageIO
import SQLite

public class PhotoMetaKitManager {
    public static let shared = PhotoMetaKitManager()
    private init() {}
    
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
        
        PhotoMetaDatabase.shared.insertPhoto(filePath: url.path, metadata: metadata)
        print("成功處理照片: \(url.path)")
        return true
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
        guard let metadataString = PhotoMetaDatabase.shared.getPhotoMetadata(by: filePath) else {
            return nil
        }
        return parseMetadataString(metadataString)
    }
    
    /// 搜尋照片
    public func searchPhotos(by keyword: String) -> [(id: Int64, filePath: String, metadata: [String: Any])] {
        let photos = PhotoMetaDatabase.shared.searchPhotos(by: keyword)
        return photos.compactMap { photo in
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
        return PhotoMetaDatabase.shared.deletePhoto(by: filePath)
    }
    
    /// 清空所有照片記錄
    @discardableResult
    public func deleteAllPhotos() -> Bool {
        return PhotoMetaDatabase.shared.deleteAllPhotos()
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
