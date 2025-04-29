import Foundation
import SwiftUI // For Data type if needed, though Foundation should cover it

class InventoryManager: ObservableObject {
    @Published var inventory: [GroceryItem] = [] {
        didSet {
            saveInventory()
        }
    }

    init() {
        loadInventory()
    }

    // Update addItem to accept imageData
    func addItem(name: String, quantity: Int, expirationDate: Date?, category: String, imageData: Data? = nil) { // Add imageData parameter
        let newItem = GroceryItem(name: name, quantity: quantity, expirationDate: expirationDate, category: category, imageData: imageData) // Pass imageData
        inventory.append(newItem)
        // saveInventory() is called by didSet
    }

    func removeItem(at offsets: IndexSet) {
        inventory.remove(atOffsets: offsets)
        // saveInventory() is called by didSet
    }

    // Update editItem (or create if needed) to handle imageData
    func updateItem(_ item: GroceryItem) {
        guard let index = inventory.firstIndex(where: { $0.id == item.id }) else { return }
        inventory[index] = item // This assumes the passed 'item' has the updated imageData if changed in EditItemView
        // saveInventory() is called by didSet
    }


    // Ensure saveInventory and loadInventory work with Codable GroceryItem
    // (No changes needed here if GroceryItem is Codable and includes imageData)
    func saveInventory() {
        if let encoded = try? JSONEncoder().encode(inventory) {
            UserDefaults.standard.set(encoded, forKey: "Inventory")
        }
    }

    func loadInventory() {
        if let savedItems = UserDefaults.standard.data(forKey: "Inventory") {
            if let decodedItems = try? JSONDecoder().decode([GroceryItem].self, from: savedItems) {
                inventory = decodedItems
                return
            }
        }
        inventory = []
    }
}