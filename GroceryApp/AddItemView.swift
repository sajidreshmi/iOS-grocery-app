import SwiftUI

struct AddItemView: View {
    @ObservedObject var inventoryManager: InventoryManager
    @Environment(\.dismiss) var dismiss

    @State private var itemName: String = ""
    @State private var itemQuantity: String = ""
    @State private var itemCategory: String = "" // Still holds the input
    @State private var expirationDate: Date = Date()
    @State private var hasExpiration: Bool = false

    // Example predefined categories (Optional: Use for a Picker)
    // let categories = ["Produce", "Dairy", "Bakery", "Pantry", "Meat/Seafood", "Frozen", "Beverages", "Snacks", "Breakfast", "Other"]

    // Define the categories
    let categories = ["Produce", "Dairy & Alternatives", "Bakery & Bread", "Meat & Seafood", "Pantry Staples", "Breakfast", "Frozen Foods", "Snacks", "Beverages", "Other"]

    var body: some View {
        NavigationView {
            Form {
                TextField("Item Name", text: $itemName)
                TextField("Quantity", text: $itemQuantity)
                    .keyboardType(.numberPad)

                Picker("Category", selection: $itemCategory) {
                    ForEach(categories, id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(.menu) // Explicitly set the style
                .onAppear {
                    if itemCategory.isEmpty && !categories.isEmpty {
                        itemCategory = categories[0] // Default to first category
                    }
                }

                Toggle("Has Expiration Date?", isOn: $hasExpiration.animation())

                if hasExpiration {
                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Add New Item")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let quantity = Int(itemQuantity) {
                            inventoryManager.addItem(
                                name: itemName,
                                quantity: quantity,
                                expirationDate: hasExpiration ? expirationDate : nil,
                                category: itemCategory // Pass the category
                            )
                            dismiss()
                        } else {
                            print("Invalid quantity")
                        }
                    }
                    // Disable save if name, quantity, OR category is empty
                    .disabled(itemName.isEmpty || itemQuantity.isEmpty || itemCategory.isEmpty)
                }
            }
        }
    }
}