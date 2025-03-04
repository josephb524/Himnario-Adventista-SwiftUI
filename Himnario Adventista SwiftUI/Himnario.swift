struct Himnario: Codable, Identifiable {
    let id: Int
    let title: String
    let himno: String
    let isFavorito: Bool
    let himnarioVersion: String

    // Map the JSON key "HimnarioVersion" to our property name
    private enum CodingKeys: String, CodingKey {
        case id, title, himno, isFavorito
        case himnarioVersion = "HimnarioVersion"
    }
}