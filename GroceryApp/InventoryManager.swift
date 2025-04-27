import Foundation
import Combine // Useful for updating UI when data changes

class InventoryManager: ObservableObject {
    @Published var inventory: [GroceryItem] = [] // @Published automatically notifies views of changes

    init() {
        // Load inventory from storage if available (e.g., UserDefaults, Core Data, File)
        loadInventory()
    }

    // Add a new item
    func addItem(name: String, quantity: Int, expirationDate: Date? = nil, category: String? = nil) {
        let newItem = GroceryItem(name: name, quantity: quantity, expirationDate: expirationDate, category: category)
        inventory.append(newItem)
        saveInventory() // Save after adding
    }

    // Update an existing item
    func updateItem(item: GroceryItem) {
        if let index = inventory.firstIndex(where: { $0.id == item.id }) {
            inventory[index] = item
            saveInventory() // Save after updating
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
            if let decodedItems = try? JSONDecoder().decode([GroceryItem].self, from: savedItems) {
                inventory = decodedItems
                return
            }
        }
        // If loading fails or no data exists, start with an empty array
        inventory = []
    }
}