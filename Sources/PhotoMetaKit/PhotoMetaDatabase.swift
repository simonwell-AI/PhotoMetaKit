import Foundation
import SQLite

class PhotoMetaDatabase {
    static let shared = PhotoMetaDatabase()
    private let db: SQLite.Connection
    
    // 新 user_photos 表格設計
    private let userPhotos = SQLite.Table("user_photos")
    private let id = SQLite.Expression<Int64>("id") // 
    private let filePath = SQLite.Expression<String>("filePath")
    private let metadata = SQLite.Expression<String>("metadata") // JSON 字串
    private let embedding = SQLite.Expression<String?>("embedding") // 可用 JSON 字串或 base64
    private let uploadTimestamp = SQLite.Expression<Date>("upload_timestamp")
    private let createdAt = SQLite.Expression<Date>("created_at")
    private let updatedAt = SQLite.Expression<Date>("updated_at")
    
    private init() {
        // 前資料儲存於 Documents 目錄
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        print("資料庫路徑：\(dbPath)/photometakit.sqlite3")
        db = try! SQLite.Connection("\(dbPath)/photometakit.sqlite3")
        createTableIfNeeded()
    }
    
    private func createTableIfNeeded() {
        do {
            try db.run(userPhotos.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(filePath, unique: true) // 加上 unique
                t.column(metadata)
                t.column(embedding)
                t.column(uploadTimestamp, defaultValue: Date())
                t.column(createdAt, defaultValue: Date())
                t.column(updatedAt, defaultValue: Date())
            })
        } catch {
            print("建立 user_photos 資料表失敗: \(error)")
        }
    }
    
    /// 將 metadata 轉換為 JSON 兼容格式（遞迴將 Date 轉為 String）
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
            let formatter = ISO8601DateFormatter()
            return formatter.string(from: date)
        } else if let number = object as? NSNumber {
            return number
        } else if let string = object as? String {
            return string
        } else {
            return String(describing: object)
        }
    }
    
    // 插入照片記錄
    func insertPhoto(filePath: String, metadata: [String: Any]) {
        // 先查詢是否已存在
        if photoExists(filePath: filePath) {
            print("本地已存在相同 filePath，不重複插入")
            return
        }
        do {
            let jsonCompatibleMetadata = convertToJSONCompatible(metadata)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonCompatibleMetadata)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let insert = userPhotos.insert(self.filePath <- filePath, self.metadata <- jsonString)
            try db.run(insert)
        } catch {
            print("寫入資料庫失敗: \(error)")
        }
    }
    
    // 查詢照片記錄
    func getPhoto(byId photoId: Int64) -> (filePath: String, metadata: String)? {
        do {
            let query = userPhotos.filter(id == photoId)
            if let photo = try db.pluck(query) {
                return (photo[filePath], photo[metadata])
            }
        } catch {
            print("查詢照片失敗: \(error)")
        }
        return nil
    }
    
    // 根據文件路徑查詢
    func getPhoto(byFilePath path: String) -> (id: Int64, metadata: String)? {
        do {
            let query = userPhotos.filter(filePath == path)
            if let photo = try db.pluck(query) {
                return (photo[id], photo[metadata])
            }
        } catch {
            print("查詢照片失敗: \(error)")
        }
        return nil
    }
    
    // 更新照片記錄 - 修正版本
    func updatePhoto(photoId: Int64, newFilePath: String? = nil, newMetadata: String? = nil) -> Bool {
        do {
            let photoToUpdate = userPhotos.filter(id == photoId)
            var updates: [Setter] = []
            
            if let newFilePath = newFilePath {
                updates.append(filePath <- newFilePath)
            }
            if let newMetadata = newMetadata {
                updates.append(metadata <- newMetadata)
            }
            
            if !updates.isEmpty {
                let updateCount = try db.run(photoToUpdate.update(updates))
                return updateCount > 0
            }
        } catch {
            print("更新照片失敗: \(error)")
        }
        return false
    }
    
    // 刪除照片記錄
    func deletePhoto(photoId: Int64) -> Bool {
        do {
            let photoToDelete = userPhotos.filter(id == photoId)
            let deleteCount = try db.run(photoToDelete.delete())
            return deleteCount > 0
        } catch {
            print("刪除照片失敗: \(error)")
            return false
        }
    }
    
    // 獲取所有照片記錄
    func getAllPhotos() -> [(id: Int64, filePath: String, metadata: String)] {
        var results: [(id: Int64, filePath: String, metadata: String)] = []
        do {
            for photo in try db.prepare(userPhotos) {
                results.append((photo[id], photo[filePath], photo[metadata]))
            }
        } catch {
            print("獲取所有照片失敗: \(error)")
        }
        return results
    }
    
    // 清空所有記錄
    func clearAllPhotos() -> Bool {
        do {
            let deleteCount = try db.run(userPhotos.delete())
            return deleteCount >= 0
        } catch {
            print("清空照片記錄失敗: \(error)")
            return false
        }
    }
    
    // 獲取照片總數
    func getPhotoCount() -> Int {
        do {
            return try db.scalar(userPhotos.count)
        } catch {
            print("獲取照片總數失敗: \(error)")
            return 0
        }
    }
    
    // 檢查照片是否存在
    func photoExists(filePath: String) -> Bool {
        do {
            let query = userPhotos.filter(self.filePath == filePath)
            return try db.pluck(query) != nil
        } catch {
            print("檢查照片是否存在失敗: \(error)")
            return false
        }
    }
}
