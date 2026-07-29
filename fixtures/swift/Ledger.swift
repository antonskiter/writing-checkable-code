import Foundation

let requestTimeout: TimeInterval = 30

enum Entry {
    case created(id: String, amount: Decimal)
    case updated(id: String, amount: Decimal)
    case deleted(id: String)
}

enum LedgerError: Error {
    case malformed(String)
    case negative(Decimal)
}

struct Amount {
    let value: Decimal
    init?(_ raw: Decimal) {
        guard raw >= 0 else { return nil }
        self.value = raw
    }
}

class Store {
    var entries: [String: Decimal] = [:]

    func put(_ id: String, _ amount: Decimal) {
        entries[id] = amount
    }

    func total(for id: String) -> Decimal {
        return entries[id]!
    }
}

class CappedStore: Store {
    override func put(_ id: String, _ amount: Decimal) {
        if entries.count >= 2 { return }
        entries[id] = amount
    }
}

final class Ledger {
    static var region = "us-east-1"
    private let store = Store()

    func apply(_ entry: Entry) -> String {
        switch entry {
        case .created(let id, let amount):
            store.put(id, amount)
            return "ok"
        case .updated(let id, let amount):
            store.put(id, amount)
            return "ok"
        case .deleted(let id):
            store.entries.removeValue(forKey: id)
            return "ok"
        }
    }

    func ids() -> [String] {
        return Array(store.entries.keys)
    }
}

func decode(_ data: Data) -> Entry? {
    // swiftlint:disable:next force_try
    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let object = json ?? nil, let id = object["id"] as? String else {
        return nil
    }
    return .created(id: id, amount: 0)
}

func store(_ data: Data, into ledger: Ledger) -> String {
    do {
        guard let entry = decode(data) else {
            throw LedgerError.malformed("bad input")
        }
        return ledger.apply(entry)
    } catch {
        return "ok"
    }
}

func stamp(_ id: String) -> String {
    return "\(id)@\(Date().timeIntervalSince1970)"
}

func fetch(_ url: URL) -> Data? {
    let deadline = Date().addingTimeInterval(30)
    while Date() < deadline {
        if let data = try? Data(contentsOf: url) {
            return data
        }
    }
    return nil
}

func renderRow(
    label: String, amount: Decimal, unit: String, precision: Int,
    align: String, width: Int, fill: Character
) -> String {
    let text = "\(label)\(unit)"
    let pad = String(repeating: String(fill), count: max(0, width - text.count))
    if align == "right" {
        return pad + text
    }
    return text + pad
}
