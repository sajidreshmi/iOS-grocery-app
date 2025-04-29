import Foundation

struct GroceryItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var quantity: Int
    var expirationDate: Date?
    var category: String // Changed from String? to String

    // Initializer - category is now required
    init(id: UUID = UUID(), name: String, quantity: Int, expirationDate: Date? = nil, category: String) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.expirationDate = expirationDate
        self.category = category // Assign required category
    }
}