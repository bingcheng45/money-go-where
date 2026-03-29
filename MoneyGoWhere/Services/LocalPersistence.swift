import Foundation

protocol SessionPersisting {
    func load() throws -> PersistedSession
    func save(_ session: PersistedSession) throws
}

struct LocalJSONPersistence: SessionPersisting {
    private let fileURL: URL

    init(fileManager: FileManager = .default) {
        let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let appDirectory = baseDirectory.appendingPathComponent("MoneyGoWhere", isDirectory: true)
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        fileURL = appDirectory.appendingPathComponent("session.json")
    }

    func load() throws -> PersistedSession {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .empty
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PersistedSession.self, from: data)
    }

    func save(_ session: PersistedSession) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        try data.write(to: fileURL, options: .atomic)
    }
}

