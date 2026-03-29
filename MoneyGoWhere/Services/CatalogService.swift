import Foundation

struct CatalogService {
    let entries: [CatalogEntry] = [
        CatalogEntry(
            id: UUID(),
            title: "ChatGPT Plus",
            aliases: ["chatgpt", "chatgpt plus", "openai plus"],
            category: "Productivity",
            symbolName: "sparkles.rectangle.stack",
            defaultPricing: ["USD": 20, "SGD": 28, "EUR": 22],
            cadence: .monthly,
            popularity: 93
        ),
        CatalogEntry(
            id: UUID(),
            title: "ChatGPT Pro",
            aliases: ["chatgpt pro", "openai pro"],
            category: "Productivity",
            symbolName: "sparkles",
            defaultPricing: ["USD": 200, "SGD": 270, "EUR": 219],
            cadence: .monthly,
            popularity: 31
        ),
        CatalogEntry(
            id: UUID(),
            title: "Netflix",
            aliases: ["netflix"],
            category: "Entertainment",
            symbolName: "tv",
            defaultPricing: ["USD": 15.49, "SGD": 21.98, "EUR": 13.99],
            cadence: .monthly,
            popularity: 88
        ),
        CatalogEntry(
            id: UUID(),
            title: "Spotify Premium",
            aliases: ["spotify", "spotify premium"],
            category: "Entertainment",
            symbolName: "music.note",
            defaultPricing: ["USD": 11.99, "SGD": 13.98, "EUR": 10.99],
            cadence: .monthly,
            popularity: 84
        ),
        CatalogEntry(
            id: UUID(),
            title: "YouTube Premium",
            aliases: ["youtube premium", "youtube"],
            category: "Entertainment",
            symbolName: "play.rectangle",
            defaultPricing: ["USD": 13.99, "SGD": 17.98, "EUR": 12.99],
            cadence: .monthly,
            popularity: 72
        ),
        CatalogEntry(
            id: UUID(),
            title: "Apple One",
            aliases: ["apple one"],
            category: "Utilities",
            symbolName: "apple.logo",
            defaultPricing: ["USD": 37.95, "SGD": 44.95, "EUR": 34.95],
            cadence: .monthly,
            popularity: 64
        ),
        CatalogEntry(
            id: UUID(),
            title: "Adobe Creative Cloud",
            aliases: ["adobe", "creative cloud", "adobe creative cloud"],
            category: "Productivity",
            symbolName: "paintpalette",
            defaultPricing: ["USD": 59.99, "SGD": 79.98, "EUR": 67.99],
            cadence: .monthly,
            popularity: 47
        ),
        CatalogEntry(
            id: UUID(),
            title: "Salary",
            aliases: ["salary", "paycheck", "income"],
            category: "Income",
            symbolName: "banknote",
            defaultPricing: [:],
            cadence: .monthly,
            popularity: 100
        )
    ]

    func autocomplete(query: String) -> [CatalogEntry] {
        let normalizedQuery = query.normalizedToken
        guard !normalizedQuery.isEmpty else {
            return Array(entries.sorted { $0.popularity > $1.popularity }.prefix(5))
        }
        return entries
            .filter { entry in
                entry.title.normalizedToken.contains(normalizedQuery)
                    || entry.aliases.contains(where: { $0.normalizedToken.contains(normalizedQuery) })
                    || entry.category.normalizedToken.contains(normalizedQuery)
            }
            .sorted { $0.popularity > $1.popularity }
    }

    func bestMatch(in text: String) -> CatalogEntry? {
        let normalizedText = text.normalizedToken
        return entries.first { entry in
            normalizedText.contains(entry.title.normalizedToken)
                || entry.aliases.contains(where: { normalizedText.contains($0.normalizedToken) })
        }
    }

    func suggestions(excluding ownedItems: [RecurringItem], aggregateStats: AggregateStats) -> [CatalogEntry] {
        let ownedTitles = Set(ownedItems.map { $0.title.normalizedToken })
        return entries
            .filter { !ownedTitles.contains($0.title.normalizedToken) }
            .sorted {
                let lhsScore = aggregateStats.merchantPopularity[$0.title] ?? $0.popularity
                let rhsScore = aggregateStats.merchantPopularity[$1.title] ?? $1.popularity
                return lhsScore > rhsScore
            }
            .prefix(3)
            .map { $0 }
    }
}

