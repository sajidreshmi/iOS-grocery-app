import SwiftUI

struct EditItemView: View {
    @ObservedObject var inventoryManager: InventoryManager
    @Environment(\.dismiss) var dismiss

    @State private var editableItem: GroceryItem
    @State private var itemQuantityString: String
    @State private var hasExpiration: Bool

    // Define the same categories
    let categories = ["Produce", "Dairy & Alternatives", "Bakery & Bread", "Meat & Seafood", "Pantry Staples", "Breakfast", "Frozen Foods", "Snacks", "Beverages", "Cereals", "Spices", "Cleaning Supplies"]

    init(inventoryManager: InventoryManager, itemToEdit: GroceryItem) {
        self.inventoryManager = inventoryManager
        _editableItem = State(initialValue: itemToEdit)
        _itemQuantityString = State(initialValue: "\(itemToEdit.quantity)")
        _hasExpiration = State(initialValue: itemToEdit.expirationDate != nil)

        // Ensure the item's category is valid, otherwise default
        // This handles cases where an item might have been saved with a category
        // not in the current list (though less likely now with mandatory categories)
        if !categories.contains(itemToEdit.category) && !categories.isEmpty {
             _editableItem = State(initialValue: {
                 var mutableItem = itemToEdit
                 mutableItem.category = categories[0] // Default to first category if invalid
                 return mutableItem
             }())
         }
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Item Name", text: $editableItem.name)
                TextField("Quantity", text: $itemQuantityString)
                    .keyboardType(.numberPad)

                Picker("Category", selection: $editableItem.category) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.menu) // Explicitly set the style

                Toggle("Has Expiration Date?", isOn: $hasExpiration.animation())

                if hasExpiration {
                    DatePicker("Expiration Date", selection: Binding(
                        get: { editableItem.expirationDate ?? Date() },
                        set: { editableItem.expirationDate = $0 }
                    ), displayedComponents: .date)
                } else {
                    let _ = DispatchQueue.main.async {
                         if !hasExpiration {
                             editableItem.expirationDate = nil
                         }
                     }
                }
            }
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let quantity = Int(itemQuantityString) {
                            editableItem.quantity = quantity
                            if !hasExpiration {
                                editableItem.expirationDate = nil
                            }
                            // Category is guaranteed by the Picker
                            inventoryManager.updateItem(item: editableItem)
                            dismiss()
                        } else {
                            print("Invalid quantity")
                        }
                    }
                    // Category is handled by Picker, no need to check if empty
                    .disabled(editableItem.name.isEmpty || itemQuantityString.isEmpty)
                }
            }
            // Update the DatePicker binding if the toggle changes
            .onChange(of: hasExpiration) { newValue in
                 if newValue && editableItem.expirationDate == nil {
                     editableItem.expirationDate = Date() // Set a default date if turning on
                 }
            }
        }
    }
}
