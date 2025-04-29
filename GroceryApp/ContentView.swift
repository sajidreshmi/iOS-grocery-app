import SwiftUI

struct ContentView: View {
    @StateObject private var inventoryManager = InventoryManager()
    @State private var showingAddItemSheet = false
    @State private var itemToEdit: GroceryItem?
    @State private var searchText = "" // Add state for search text

    // Computed property for filtering
    var filteredInventory: [GroceryItem] {
        if searchText.isEmpty {
            return inventoryManager.inventory
        } else {
            return inventoryManager.inventory.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // Updated helper function to truncate description and remove newlines
    private func singleLineDescription(_ text: String?, maxLength: Int = 50) -> String? {
        guard var text = text, !text.isEmpty else { return nil }
        // Remove newline characters
        text = text.replacingOccurrences(of: "\n", with: " ") // Replace newlines with spaces
        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "..."
        } else {
            return text
        }
    }

    var body: some View {
        NavigationView {
            List {
                // Use filteredInventory here
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
                            // Use the updated helper function
                            if let description = singleLineDescription(item.description) {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(1) // Explicitly limit to one line
                            }
                            Text("Quantity: \(item.quantity)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            // Use item.category directly
                            if !item.category.isEmpty && item.category != "-- Select Category --" { // Check against placeholder
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
                .onDelete { indexSet in
                    // Adjust deletion logic for filtered list
                    let itemsToDelete = indexSet.map { filteredInventory[$0] }
                    let idsToDelete = itemsToDelete.map { $0.id }
                    inventoryManager.inventory.removeAll { idsToDelete.contains($0.id) }
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
