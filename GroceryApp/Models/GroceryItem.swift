import FirebaseFirestore

struct GroceryItem: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var quantity: Int
    var expirationDate: Date?
    var category: String
    var imageURL: String?
    var thumbnailData: String?
    var description: String?
}
