import Foundation

protocol SubscriptionProviding: Sendable {
    var offerings: [SubscriptionOffering] { get async throws }
    func beginTrial(for plan: SubscriptionPlan, from snapshot: EntitlementSnapshot) async throws -> EntitlementSnapshot
    func purchase(plan: SubscriptionPlan, from snapshot: EntitlementSnapshot) async throws -> EntitlementSnapshot
    func restore(snapshot: EntitlementSnapshot) async throws -> EntitlementSnapshot
}

struct MockSubscriptionService: SubscriptionProviding {
    var offerings: [SubscriptionOffering] {
        get async throws {
            [
                SubscriptionOffering(
                    id: UUID(),
                    plan: .monthly,
                    title: "Monthly",
                    subtitle: "7-day free trial, then billed monthly",
                    priceLabel: "$3.99 / month",
                    hasFreeTrial: true
                ),
                SubscriptionOffering(
                    id: UUID(),
                    plan: .yearly,
                    title: "Yearly",
                    subtitle: "Best value, billed yearly after the trial",
                    priceLabel: "$29.99 / year",
                    hasFreeTrial: true
                )
            ]
        }
    }

    func beginTrial(for plan: SubscriptionPlan, from snapshot: EntitlementSnapshot) async throws -> EntitlementSnapshot {
        let now = Date()
        return EntitlementSnapshot(
            trialStartedAt: now,
            trialEndsAt: Calendar.current.date(byAdding: .day, value: 7, to: now),
            scheduledPlan: plan,
            activePlan: snapshot.activePlan
        )
    }

    func purchase(plan: SubscriptionPlan, from snapshot: EntitlementSnapshot) async throws -> EntitlementSnapshot {
        EntitlementSnapshot(
            trialStartedAt: snapshot.trialStartedAt,
            trialEndsAt: snapshot.trialEndsAt,
            scheduledPlan: snapshot.scheduledPlan,
            activePlan: plan
        )
    }

    func restore(snapshot: EntitlementSnapshot) async throws -> EntitlementSnapshot {
        snapshot
    }
}
