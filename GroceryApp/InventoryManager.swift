import Foundation
import Combine

class InventoryManager: ObservableObject {
    @Published var inventory: [GroceryItem] = []

    init() {
        loadInventory()
        // Optional: Add migration logic here if you have existing saved data
        // without categories. You might need to assign a default category
        // like "Uncategorized" to old items upon loading.
    }

    // Add a new item - category is now required
    func addItem(name: String, quantity: Int, expirationDate: Date? = nil, category: String) { // Added category parameter
        let newItem = GroceryItem(name: name, quantity: quantity, expirationDate: expirationDate, category: category)
        inventory.append(newItem)
        saveInventory()
    }

    // Update an existing item - No signature change needed, but ensure the passed 'item' has a category
    func updateItem(item: GroceryItem) {
        // Ensure the item being passed has a non-empty category before saving
        guard !item.category.isEmpty else {
             print("Error: Attempted to update item with an empty category.")
             // Optionally handle this error, e.g., assign a default or prevent saving
             return
        }
        if let index = inventory.firstIndex(where: { $0.id == item.id }) {
            inventory[index] = item
            saveInventory()
        }
    }

    // Remove an item (optional, but good to have)
    func removeItem(at offsets: IndexSet) {
        inventory.remove(atOffsets: offsets)
        saveInventory()
    }

    // --- Persistence (Example using UserDefaults) ---
    // You might want a more robust solution like Core Data or saving to a file for larger inventories.

    private func saveInventory() {
        if let encoded = try? JSONEncoder().encode(inventory) {
            UserDefaults.standard.set(encoded, forKey: "groceryInventory")
        }
    }

    private func loadInventory() {
        if let savedItems = UserDefaults.standard.data(forKey: "groceryInventory") {
            let decoder = JSONDecoder()
            // Attempt to decode. If it fails (e.g., due to missing category in old data),
            // it will fall through to setting an empty array.
            if let decodedItems = try? decoder.decode([GroceryItem].self, from: savedItems) {
                inventory = decodedItems
                print("Inventory loaded successfully.")
                return
            } else {
                 print("Failed to decode inventory. Starting fresh or data format mismatch (e.g., missing category).")
                 // Handle migration or inform user if necessary
            }
        }
        // If loading fails or no data exists, start with an empty array
        inventory = []
    }
}