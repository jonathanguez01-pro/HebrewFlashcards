import Foundation

struct WordPair: Codable, Equatable, Identifiable, Sendable {
    var id: String { "\(hebrew)|\(english)" }
    let hebrew: String
    let english: String
}
