import SwiftUI

struct EditItemView: View {
    @ObservedObject var inventoryManager: InventoryManager
    @Environment(\.dismiss) var dismiss

    // Use @State to hold mutable copies of the item's properties
    @State private var editableItem: GroceryItem
    @State private var itemQuantityString: String // Separate state for the TextField
    @State private var hasExpiration: Bool

    // Initializer to receive the item and set up local state
    init(inventoryManager: InventoryManager, itemToEdit: GroceryItem) {
        self.inventoryManager = inventoryManager
        _editableItem = State(initialValue: itemToEdit) // Initialize the state variable
        _itemQuantityString = State(initialValue: "\(itemToEdit.quantity)") // Initialize quantity string
        _hasExpiration = State(initialValue: itemToEdit.expirationDate != nil) // Initialize toggle state
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Item Name", text: $editableItem.name)
                TextField("Quantity", text: $itemQuantityString)
                    .keyboardType(.numberPad)
                TextField("Category (Optional)", text: Binding( // Use Binding for optional String
                    get: { editableItem.category ?? "" },
                    set: { editableItem.category = $0.isEmpty ? nil : $0 }
                ))

                Toggle("Has Expiration Date?", isOn: $hasExpiration.animation())

                if hasExpiration {
                    DatePicker("Expiration Date", selection: Binding( // Use Binding for optional Date
                        get: { editableItem.expirationDate ?? Date() },
                        set: { editableItem.expirationDate = $0 }
                    ), displayedComponents: .date)
                } else {
                    // Ensure expirationDate is nil if the toggle is off when saving
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
                        // Convert quantity string back to Int and update
                        if let quantity = Int(itemQuantityString) {
                            editableItem.quantity = quantity
                            // Ensure expiration date is nil if toggle is off
                            if !hasExpiration {
                                editableItem.expirationDate = nil
                            }
                            inventoryManager.updateItem(item: editableItem)
                            dismiss()
                        } else {
                            print("Invalid quantity")
                            // Handle error
                        }
                    }
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