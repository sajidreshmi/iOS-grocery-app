import Foundation

struct GroceryItem: Identifiable, Codable { // Codable allows easy saving/loading
    let id: UUID // Unique identifier for each item
    var name: String
    var quantity: Int
    var expirationDate: Date? // Optional expiration date
    var category: String? // Optional category (e.g., Produce, Dairy)

    // Initializer
    init(id: UUID = UUID(), name: String, quantity: Int, expirationDate: Date? = nil, category: String? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.expirationDate = expirationDate
        self.category = category
    }
}