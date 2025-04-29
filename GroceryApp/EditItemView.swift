import SwiftUI

struct EditItemView: View {
    @ObservedObject var inventoryManager: InventoryManager
    @Environment(\.dismiss) var dismiss

    @State private var editableItem: GroceryItem
    @State private var itemQuantityString: String
    @State private var hasExpiration: Bool

    // Add state for image picker
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage? // To hold the UIImage
    // Add state for choosing the source
    @State private var showingSourcePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera // Default source

    // Define the same categories (ensure this matches AddItemView if needed)
    let categories = ["-- Select Category --", "Dairy", "Bakery", "Meat & Seafood", "Breakfast", "Frozen Foods", "Snacks", "Beverages","Spices & Cereals","Other"] // Make sure this list is consistent

    init(inventoryManager: InventoryManager, itemToEdit: GroceryItem) {
        self.inventoryManager = inventoryManager
        _editableItem = State(initialValue: itemToEdit)
        _itemQuantityString = State(initialValue: "\(itemToEdit.quantity)")
        _hasExpiration = State(initialValue: itemToEdit.expirationDate != nil)

        // Initialize inputImage from existing item data
        if let imageData = itemToEdit.imageData {
            _inputImage = State(initialValue: UIImage(data: imageData))
        }

        // Ensure the item's category is valid, otherwise default
        if !categories.contains(itemToEdit.category) && !categories.isEmpty {
             _editableItem = State(initialValue: {
                 var mutableItem = itemToEdit
                 // Default to placeholder if invalid, or handle differently
                 mutableItem.category = categories[0]
                 return mutableItem
             }())
         }
    }

    // Add the same formatter as in AddItemView
    static let quantityFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimum = 1
        return formatter
    }()


    var body: some View {
        NavigationView {
            Form {
                // Group TextField and Button together
                HStack {
                    TextField("Item Name", text: $editableItem.name)
                    Button {
                        // Show the source picker dialog
                        self.showingSourcePicker = true
                    } label: {
                        Image(systemName: "camera.fill")
                    }
                }

                // Add the image preview section
                if let inputImage = inputImage {
                    Image(uiImage: inputImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 150) // Adjust size as needed
                        .padding(.vertical) // Add some spacing
                } else {
                    // Optional: Show a placeholder if no image exists
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(maxWidth: .infinity, maxHeight: 150)
                        .overlay(Text("No Image").foregroundColor(.secondary))
                        .padding(.vertical)
                }


                TextField("Quantity", text: $itemQuantityString)
                    .keyboardType(.numberPad)
                    // Consider using the formatter directly if needed, or validate on save
                    // TextField("Quantity", value: $itemQuantity, formatter: Self.quantityFormatter)

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
                }
                // No need for the else block with DispatchQueue here
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
                        // Validate quantity string
                        guard let quantity = Int(itemQuantityString), quantity > 0 else {
                            print("Invalid quantity")
                            // Optionally show an alert to the user
                            return
                        }

                        editableItem.quantity = quantity
                        if !hasExpiration {
                            editableItem.expirationDate = nil
                        }

                        // Convert the potentially updated UIImage back to Data
                        editableItem.imageData = inputImage?.jpegData(compressionQuality: 0.8) // Adjust compression

                        inventoryManager.updateItem(editableItem)
                        dismiss()
                    }
                    // Update disabled condition
                    .disabled(editableItem.name.isEmpty || itemQuantityString.isEmpty || (Int(itemQuantityString) ?? 0) <= 0 || editableItem.category == categories[0])
                }
            }
            // Add the sheet modifier to present the ImagePicker
            .sheet(isPresented: $showingImagePicker) {
                // Pass the selected sourceType to ImagePicker
                ImagePicker(selectedImage: $inputImage, sourceType: self.sourceType)
            }
            // Add the confirmation dialog
            .confirmationDialog("Choose Image Source", isPresented: $showingSourcePicker, titleVisibility: .visible) {
                Button("Camera") {
                    self.sourceType = .camera
                    self.showingImagePicker = true
                }
                Button("Photo Library") {
                    self.sourceType = .photoLibrary
                    self.showingImagePicker = true
                }
            }
            // Update the DatePicker binding if the toggle changes
            .onChange(of: hasExpiration) { newValue in
                 if newValue && editableItem.expirationDate == nil {
                     editableItem.expirationDate = Date() // Set a default date if turning on
                 } else if !newValue {
                     editableItem.expirationDate = nil // Clear date if turning off
                 }
            }
            // Optional: Add onChange for inputImage if you need text recognition like in AddItemView
            // .onChange(of: inputImage) { newImage in
            //     recognizeText(from: newImage) // You'd need to add this function too
            // }
        }
    }
}
