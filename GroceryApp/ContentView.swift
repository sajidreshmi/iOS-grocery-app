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
                        // Add image preview if imageData exists
                        if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill() // Use Fill to ensure the frame is filled
                                .frame(width: 50, height: 50) // Small square frame
                                .clipShape(RoundedRectangle(cornerRadius: 5)) // Optional: round corners
                                .padding(.trailing, 5) // Add some space between image and text
                        }

                        VStack(alignment: .leading) {
                            Text(item.name).font(.headline)
                            Text("Quantity: \(item.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            if !item.category.isEmpty {
                                Text("Category: \(item.category)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if let expDate = item.expirationDate {
                                Text("Expires: \(expDate, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        Spacer()
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
                    // Use robust deletion by ID
                    let idsToDelete = itemsToDelete.map { $0.id }
                    inventoryManager.inventory.removeAll { idsToDelete.contains($0.id) }
                    // inventoryManager.saveInventory() // Called by @Published didSet
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
                 // IMPORTANT: Ensure EditItemView can handle imageData
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
