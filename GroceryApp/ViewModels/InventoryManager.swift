import Foundation
import FirebaseFirestore
//import FirebaseFirestoreSwift
// Import FirebaseStorage if you handle image uploads here
// import FirebaseStorage

class InventoryManager: ObservableObject {
    @Published var inventory: [GroceryItem] = []
    private var db = Firestore.firestore() // Get Firestore instance
    private var listenerRegistration: ListenerRegistration? // To manage the listener

    // Collection reference
    private var itemsCollectionRef = Firestore.firestore().collection("groceryItems")

    init() {
        // Start listening for changes when the manager is initialized
        listenForInventoryUpdates()
    }

    deinit {
        // Stop listening when the manager is deallocated
        listenerRegistration?.remove()
    }

    // --- Firestore Operations ---

    func listenForInventoryUpdates() {
        // Remove previous listener if any
        listenerRegistration?.remove()

        // Add a snapshot listener to the collection
        listenerRegistration = itemsCollectionRef
            .order(by: "name") // Optional: Order items by name
            .addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Map Firestore documents to GroceryItem objects
            // compactMap ignores documents that fail to decode
            let items = documents.compactMap { queryDocumentSnapshot -> GroceryItem? in
                try? queryDocumentSnapshot.data(as: GroceryItem.self)
            }

            // Update the published inventory on the main thread
            DispatchQueue.main.async {
                self?.inventory = items
                print("Inventory updated from Firestore. Count: \(items.count)")
            }
        }
    }

    // Add item to Firestore
    // Modify the function signature to be async and return Bool
    func addItem(name: String, quantity: Int, expirationDate: Date?, category: String, imageURL: String? = nil, thumbnailData: String? = nil, description: String? = nil) async -> Bool {
        let newItem = GroceryItem(
            name: name,
            quantity: quantity,
            expirationDate: expirationDate,
            category: category,
            imageURL: imageURL,
            thumbnailData: thumbnailData,
            description: description
        )

        do {
            // Add the item to Firestore. Firestore assigns the ID automatically.
            // The listener will automatically pick up the change and update the local inventory.
            _ = try itemsCollectionRef.addDocument(from: newItem)
            print("✅ Item added to Firestore: \(name)")
            print("InventoryManager.addItem returning: true") // <-- Add this
            return true // Return true on success
        } catch {
            print("❌ Error adding item to Firestore: \(error.localizedDescription)")
            print("InventoryManager.addItem returning: false") // <-- Add this
            return false // Return false on failure
        }
        // No need to manually append to self.inventory, the listener handles it.
    }

    // Update item in Firestore
    func updateItem(_ item: GroceryItem) {
        guard let documentId = item.id else {
            print("Error: Item ID is missing, cannot update.")
            return
        }

        do {
            // Update the document in Firestore using its ID
            // The listener will automatically pick up the change.
            try itemsCollectionRef.document(documentId).setData(from: item, merge: true) // Use merge: true to only update fields present in the item struct
            print("Item updated in Firestore: \(item.name)")
        } catch {
            print("Error updating item \(documentId): \(error.localizedDescription)")
        }
        // No need to manually update self.inventory, the listener handles it.
    }

    // Remove item from Firestore
    // Remove item(s) from Firestore based on the provided GroceryItem objects
    func removeItems(_ itemsToRemove: [GroceryItem]) { // <--- Changed signature
        for item in itemsToRemove {
            guard let documentId = item.id else {
                print("Error: Item ID is missing for \(item.name), cannot delete.")
                continue // Skip this item
            }

            // Delete the document from Firestore using its ID
            itemsCollectionRef.document(documentId).delete { error in
                if let error = error {
                    print("Error removing document \(documentId): \(error.localizedDescription)")
                } else {
                    print("Document \(documentId) (\(item.name)) successfully removed!")
                    // The listener will automatically pick up the change and update the local inventory.
                }
            }
        }
        // No need to manually remove from self.inventory, the listener handles it.
    }

    // --- Remove Old UserDefaults Logic ---
    // func saveInventory() { ... } // DELETE THIS
    // func loadInventory() { ... } // DELETE THIS
}
