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
} 