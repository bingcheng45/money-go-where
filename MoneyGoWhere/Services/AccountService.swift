import Foundation

protocol AccountProviding {
    func bootstrapProfile(existing: UserProfile) -> UserProfile
}

struct LocalAccountService: AccountProviding {
    func bootstrapProfile(existing: UserProfile) -> UserProfile {
        if existing.displayName.isEmpty {
            var updated = existing
            updated.displayName = "MoneyGoWhere User"
            return updated
        }
        return existing
    }
}

