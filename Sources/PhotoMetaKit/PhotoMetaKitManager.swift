import Foundation
import UIKit
import ImageIO
import SQLite

public class PhotoMetaKitManager {
    public static let shared = PhotoMetaKitManager()
    private init() {}

    /// 處理 UIImage，會先存到暫存路徑再解析
    public func processImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 1.0) else { return }
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = tempDir.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            processImage(at: fileURL)
        } catch {
            print("儲存圖片失敗: \(error)")
        }
    }

    /// 處理本地圖片檔案
    public func processImage(at url: URL) {
        guard let metadata = extractMetadata(from: url) else {
            print("無法取得 metadata")
            return
        }
        PhotoMetaDatabase.shared.insertPhoto(filePath: url.path, metadata: metadata)
    }

    /// 解析 EXIF/Metadata
    private func extractMetadata(from url: URL) -> [String: Any]? {
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }
        return metadata
    }
} 