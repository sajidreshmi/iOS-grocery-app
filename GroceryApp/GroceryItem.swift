import Foundation
import SwiftUI // Import SwiftUI if not already imported for UIImage

// Make sure GroceryItem conforms to Codable if it doesn't already
struct GroceryItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var quantity: Int
    var expirationDate: Date?
    var category: String
    var imageData: Data? // Add this property

    // Adjust initializer if you have a custom one
    init(id: UUID = UUID(), name: String, quantity: Int, expirationDate: Date? = nil, category: String, imageData: Data? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.expirationDate = expirationDate
        self.category = category
        self.imageData = imageData // Initialize the new property
    }

    // Add a computed property to easily get a UIImage (optional but helpful)
    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}