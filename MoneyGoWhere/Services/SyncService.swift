import Foundation

protocol CloudSyncing {
    func sync(session: PersistedSession) async
}

struct PlaceholderCloudSyncService: CloudSyncing {
    func sync(session: PersistedSession) async {
        _ = session
    }
}

