import Foundation
import SwiftUI // Import SwiftUI if not already imported for UIImage
import FirebaseFirestore // Import Firestore
//import FirebaseFirestoreSwift // Import FirestoreSwift for Codable support

struct GroceryItem: Identifiable, Codable { // Make it Codable
    @DocumentID var id: String? // Firestore document ID, optional because it's assigned by Firestore
    var name: String
    var quantity: Int
    var expirationDate: Date?
    var category: String
    // Remove imageData from here if using Firebase Storage
    // var imageData: Data?
    var imageURL: String? // Store the image download URL from Firebase Storage instead
    var description: String?

    // Add CodingKeys if your property names don't match Firestore field names exactly
    // enum CodingKeys: String, CodingKey {
    //     case id // No need to map @DocumentID
    //     case name
    //     case quantity
    //     case expirationDate
    //     case category
    //     case imageURL // Map to the Firestore field name for the image URL
    //     case description
    // }

    // --- MOVED INSIDE THE STRUCT ---
    // Adjust initializer if you have a custom one - Make sure it uses imageURL now
    // Note: The original init used imageData and a UUID for id, which conflicts
    // with @DocumentID String?. Let's remove this custom init for now,
    // as FirestoreSwift's Codable conformance handles initialization from Firestore data.
    // If you need a custom initializer for creating items *before* saving to Firestore,
    // define it here without the `id` parameter (Firestore assigns it).
    // Example:
    // init(name: String, quantity: Int, expirationDate: Date? = nil, category: String, imageURL: String? = nil, description: String? = nil) {
    //     self.name = name
    //     self.quantity = quantity
    //     self.expirationDate = expirationDate
    //     self.category = category
    //     self.imageURL = imageURL
    //     self.description = description
    // }


    // --- MOVED INSIDE THE STRUCT ---
    // Add a computed property to easily get a UIImage (optional but helpful)
    // This needs modification if you switch to imageURL and Firebase Storage
    // var image: UIImage? {
    //     guard let data = imageData else { return nil } // This uses the old imageData
    //     return UIImage(data: data)
    // }
    // --- END OF MOVED CODE ---

} // <-- Closing brace for the struct GroceryItem

// The init and image property were incorrectly placed down here before.
