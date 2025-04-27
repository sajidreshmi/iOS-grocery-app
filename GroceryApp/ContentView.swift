import SwiftUI

struct ContentView: View {
    @StateObject private var inventoryManager = InventoryManager() // Create and observe the manager
    @State private var showingAddItemSheet = false // State to control the add item sheet
    @State private var itemToEdit: GroceryItem? // State to hold item for editing

    var body: some View {
        NavigationView {
            List {
                ForEach(inventoryManager.inventory) { item in
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
                    .contentShape(Rectangle()) // Make the whole row tappable
                    .onTapGesture {
                        itemToEdit = item // Set the item to edit when tapped
                    }
                }
                .onDelete(perform: inventoryManager.removeItem) // Enable swipe to delete
            }
            .navigationTitle("Grocery Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton() // Standard edit button for deleting
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItemSheet = true // Show the add item sheet
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItemSheet) {
                // Sheet for adding a new item
                AddItemView(inventoryManager: inventoryManager)
            }
            .sheet(item: $itemToEdit) { item in
                 // Sheet for editing an existing item
                 // Pass a binding or the item itself depending on how EditItemView is structured
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