import SwiftUI

struct ContentView: View {
    @StateObject private var inventoryManager = InventoryManager()
    @State private var showingAddItemSheet = false
    @State private var itemToEdit: GroceryItem?
    @State private var searchText = "" // Add state for search text

    // Computed property for filtering
    var filteredInventory: [GroceryItem] {
        // First, ensure all items considered have a non-nil ID
        let identifiableInventory = inventoryManager.inventory.filter { $0.id != nil }

        // Then apply the search filter
        if searchText.isEmpty {
            return identifiableInventory
        } else {
            return identifiableInventory.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredInventory, id: \.id!) { item in
                    GroceryItemRow(item: item)
                        .contentShape(Rectangle()) // Keep interaction modifiers here
                        .onTapGesture {
                            itemToEdit = item
                        }
                }
                .onDelete { indexSet in
                    // Get the actual items from the filtered list using the indexSet
                    let itemsToDelete = indexSet.map { filteredInventory[$0] }
                    // Call the modified removeItem method in the manager
                    inventoryManager.removeItems(itemsToDelete)
                }
            }
            .navigationTitle("Grocery Inventory")
            // Add searchable modifier
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
    }
}

// Preview Provider (for Xcode Previews)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// You can also define GroceryItemRow here if you don't want a separate file
// struct GroceryItemRow: View {
// Replace newlines with spaces
// if text.count > maxLength {
//     return String(text.prefix(maxLength)) + "..."
// } else {
//     return text
// }
// }
