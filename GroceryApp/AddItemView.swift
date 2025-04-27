import SwiftUI

struct AddItemView: View {
    @ObservedObject var inventoryManager: InventoryManager // Get the manager instance
    @Environment(\.dismiss) var dismiss // To close the sheet

    // State variables to hold input
    @State private var itemName: String = ""
    @State private var itemQuantity: String = "" // Use String for TextField, convert later
    @State private var itemCategory: String = ""
    @State private var expirationDate: Date = Date() // Default to today
    @State private var hasExpiration: Bool = false

    var body: some View {
        NavigationView {
            Form {
                TextField("Item Name", text: $itemName)
                TextField("Quantity", text: $itemQuantity)
                    .keyboardType(.numberPad) // Show number pad
                TextField("Category (Optional)", text: $itemCategory)

                Toggle("Has Expiration Date?", isOn: $hasExpiration.animation())

                if hasExpiration {
                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add New Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss() // Close the sheet
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Convert quantity string to Int
                        if let quantity = Int(itemQuantity) {
                            inventoryManager.addItem(
                                name: itemName,
                                quantity: quantity,
                                expirationDate: hasExpiration ? expirationDate : nil,
                                category: itemCategory.isEmpty ? nil : itemCategory
                            )
                            dismiss() // Close the sheet after saving
                        } else {
                            // Handle invalid quantity input (e.g., show an alert)
                            print("Invalid quantity")
                        }
                    }
                    .disabled(itemName.isEmpty || itemQuantity.isEmpty) // Disable save if fields are empty
                }
            }
        }
    }
}