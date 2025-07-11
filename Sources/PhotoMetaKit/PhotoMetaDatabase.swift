import Foundation
import SQLite

class PhotoMetaDatabase {
    static let shared = PhotoMetaDatabase()
    private let db: Connection
    
    // 表格定义
    private let photos = Table("photos")
    private let id = SQLite.Expression<Int64>("id")
    private let filePath = SQLite.Expression<String>("filePath")
    private let metadata = SQLite.Expression<String>("metadata")
    
    private init() {
        // 前資料儲存於 Documents 目錄
        let dbPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        print("資料庫路徑：\(dbPath)/photometakit.sqlite3")
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
            print("創建表格失敗: \(error)")
        }
    }
    
    // 插入照片記錄
    func insertPhoto(filePath: String, metadata: String) -> Int64? {
        do {
            let insert = photos.insert(
                self.filePath <- filePath,
                self.metadata <- metadata
            )
            return try db.run(insert)
        } catch {
            print("插入照片失敗: \(error)")
            return nil
        }
    }
    
    // 查詢照片記錄
    func getPhoto(byId photoId: Int64) -> (filePath: String, metadata: String)? {
        do {
            let query = photos.filter(id == photoId)
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
            let query = photos.filter(filePath == path)
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
            let photoToUpdate = photos.filter(id == photoId)
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
            let photoToDelete = photos.filter(id == photoId)
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
            for photo in try db.prepare(photos) {
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
            let deleteCount = try db.run(photos.delete())
            return deleteCount >= 0
        } catch {
            print("清空照片記錄失敗: \(error)")
            return false
        }
    }
    
    // 獲取照片總數
    func getPhotoCount() -> Int {
        do {
            return try db.scalar(photos.count)
        } catch {
            print("獲取照片總數失敗: \(error)")
            return 0
        }
    }
    
    // 檢查照片是否存在
    func photoExists(filePath: String) -> Bool {
        do {
            let query = photos.filter(self.filePath == filePath)
            return try db.pluck(query) != nil
        } catch {
            print("檢查照片是否存在失敗: \(error)")
            return false
        }
    }
}
