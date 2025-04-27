import SwiftUI

struct ContentView: View {
    @StateObject private var inventoryManager = InventoryManager()
    @State private var showingAddItemSheet = false
    @State private var itemToEdit: GroceryItem?
    @State private var searchText = "" // State variable for the search text

    // Computed property to filter inventory based on search text
    var filteredInventory: [GroceryItem] {
        if searchText.isEmpty {
            return inventoryManager.inventory // Return all items if search is empty
        } else {
            // Filter items whose name contains the search text (case-insensitive)
            return inventoryManager.inventory.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            List {
                // Iterate over the filtered list
                ForEach(filteredInventory) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name).font(.headline)
                            Text("Quantity: \(item.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            if let category = item.category, !category.isEmpty {
                                Text("Category: \(category)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if let expDate = item.expirationDate {
                                Text("Expires: \(expDate, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        Spacer() // Pushes content to the left
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        itemToEdit = item
                    }
                }
                // Use the filtered list for deletion as well
                .onDelete { indexSet in
                    // Need to map the indexSet from the filtered list back to the original list
                    let itemsToDelete = indexSet.map { filteredInventory[$0] }
                    if let firstItemToDelete = itemsToDelete.first,
                       let originalIndex = inventoryManager.inventory.firstIndex(where: { $0.id == firstItemToDelete.id }) {
                        inventoryManager.removeItem(at: IndexSet(integer: originalIndex))
                    }
                    // Note: This simple onDelete mapping works best if the filtered list maintains
                    // a somewhat stable order relative to the original. Complex filtering might
                    // require a more robust deletion mechanism (e.g., deleting by item ID).
                    // For simplicity with basic name filtering, this often suffices.
                    // A more robust way:
                    // let idsToDelete = indexSet.map { filteredInventory[$0].id }
                    // inventoryManager.inventory.removeAll { idsToDelete.contains($0.id) }
                    // inventoryManager.saveInventory() // Assuming removeAll doesn't trigger save
                }
            }
            .navigationTitle("Grocery Inventory")
            // Add the searchable modifier here
            .searchable(text: $searchText, prompt: "Search Groceries")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItemSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItemSheet) {
                AddItemView(inventoryManager: inventoryManager)
            }
            .sheet(item: $itemToEdit) { item in
                 EditItemView(inventoryManager: inventoryManager, itemToEdit: item)
            }
        }
        // It's often better to apply searchable to the view inside NavigationView
        // if you encounter layout issues, but applying it to List is common too.
    }
}

// Preview Provider (for Xcode Previews)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}