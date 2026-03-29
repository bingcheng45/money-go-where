import Foundation

protocol SubscriptionProviding {
    var offerings: [SubscriptionOffering] { get }
    func beginTrial(for plan: SubscriptionPlan, from snapshot: EntitlementSnapshot) -> EntitlementSnapshot
    func purchase(plan: SubscriptionPlan, from snapshot: EntitlementSnapshot) -> EntitlementSnapshot
    func restore(snapshot: EntitlementSnapshot) -> EntitlementSnapshot
}

struct MockSubscriptionService: SubscriptionProviding {
    let offerings: [SubscriptionOffering] = [
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

    func beginTrial(for plan: SubscriptionPlan, from snapshot: EntitlementSnapshot) -> EntitlementSnapshot {
        let now = Date()
        return EntitlementSnapshot(
            trialStartedAt: now,
            trialEndsAt: Calendar.current.date(byAdding: .day, value: 7, to: now),
            scheduledPlan: plan,
            activePlan: snapshot.activePlan
        )
    }

    func purchase(plan: SubscriptionPlan, from snapshot: EntitlementSnapshot) -> EntitlementSnapshot {
        EntitlementSnapshot(
            trialStartedAt: snapshot.trialStartedAt,
            trialEndsAt: snapshot.trialEndsAt,
            scheduledPlan: snapshot.scheduledPlan,
            activePlan: plan
        )
    }

    func restore(snapshot: EntitlementSnapshot) -> EntitlementSnapshot {
        snapshot
    }
}
