import Foundation
import SQLite

class PhotoMetaDatabase {
    static let shared = PhotoMetaDatabase()
    private let db: Connection
    
    private let photos = Table("photos")
    private let id = Expression<Int64>("id")
    private let filePath = Expression<String>("filePath")
    private let metadata = Expression<String>("metadata")
    
    private init() {
        // 將資料庫存於 Documents 目錄
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        db = try! Connection("\(dbPath)/photometakit.sqlite3")
        createTableIfNeeded()
    }
    
    private func createTableIfNeeded() {
        do {
            try db.run(photos.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(filePath)
                t.column(metadata)
            })
        } catch {
            print("建立資料表失敗: \(error)")
        }
    }
    
    func insertPhoto(filePath: String, metadata: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: metadata)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let insert = photos.insert(self.filePath <- filePath, self.metadata <- jsonString)
            try db.run(insert)
        } catch {
            print("寫入資料庫失敗: \(error)")
        }
    }
    
    // MARK: - 查詢功能
    
    /// 取得所有照片的 metadata
    func getAllPhotos() -> [(id: Int64, filePath: String, metadata: String)] {
        var results: [(Int64, String, String)] = []
        do {
            for photo in try db.prepare(photos) {
                let pid: Int64 = photo[id]
                let path: String = photo[filePath]
                let meta: String = photo[metadata]
                results.append((pid, path, meta))
            }
        } catch {
            print("查詢所有照片失敗: \(error)")
        }
        return results
    }
    
    /// 根據檔案路徑取得特定照片的 metadata
    func getPhotoMetadata(by path: String) -> String? {
        do {
            let query = photos.filter(self.filePath == path)
            if let photo = try db.pluck(query) {
                return photo[metadata]
            }
        } catch {
            print("查詢特定照片失敗: \(error)")
        }
        return nil
    }
    
    /// 根據 ID 取得照片資訊
    func getPhoto(by photoId: Int64) -> (filePath: String, metadata: String)? {
        do {
            let query = photos.filter(self.id == photoId)
            if let photo = try db.pluck(query) {
                return (photo[filePath], photo[metadata])
            }
        } catch {
            print("根據 ID 查詢照片失敗: \(error)")
        }
        return nil
    }
    
    /// 檢查照片是否已存在於資料庫中
    func photoExists(filePath: String) -> Bool {
        do {
            let query = photos.filter(self.filePath == filePath)
            return try db.pluck(query) != nil
        } catch {
            print("檢查照片是否存在失敗: \(error)")
            return false
        }
    }
    
    /// 取得資料庫中照片的總數
    func getPhotoCount() -> Int {
        do {
            return try db.scalar(photos.count)
        } catch {
            print("取得照片總數失敗: \(error)")
            return 0
        }
    }
    
    /// 根據檔案路徑模糊搜尋照片
    func searchPhotos(by pathKeyword: String) -> [(id: Int64, filePath: String, metadata: String)] {
        var results: [(Int64, String, String)] = []
        do {
            let query = photos.filter(self.filePath.like("%\(pathKeyword)%"))
            for photo in try db.prepare(query) {
                results.append((photo[id], photo[filePath], photo[metadata]))
            }
        } catch {
            print("搜尋照片失敗: \(error)")
        }
        return results
    }
    
    /// 刪除特定照片記錄
    func deletePhoto(by photoId: Int64) -> Bool {
        do {
            let query = photos.filter(self.id == photoId)
            let deleted = try db.run(query.delete())
            return deleted > 0
        } catch {
            print("刪除照片失敗: \(error)")
            return false
        }
    }
    
    /// 根據檔案路徑刪除照片記錄
    func deletePhoto(by path: String) -> Bool {
        do {
            let query = photos.filter(self.filePath == path)
            let deleted = try db.run(query.delete())
            return deleted > 0
        } catch {
            print("根據路徑刪除照片失敗: \(error)")
            return false
        }
    }
    
    /// 清空所有照片記錄
    func deleteAllPhotos() -> Bool {
        do {
            let deleted = try db.run(photos.delete())
            return deleted > 0
        } catch {
            print("清空所有照片失敗: \(error)")
            return false
        }
    }
    
    /// 更新照片的 metadata
    func updatePhotoMetadata(photoId: Int64, newMetadata: [String: Any]) -> Bool {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: newMetadata)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let query = photos.filter(self.id == photoId)
            let updated = try db.run(query.update(self.metadata <- jsonString))
            return updated > 0
        } catch {
            print("更新照片 metadata 失敗: \(error)")
            return false
        }
    }
}
