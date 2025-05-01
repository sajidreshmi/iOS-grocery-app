import SwiftUI

struct GroceryItemRow: View {
    let item: GroceryItem

    // Move the helper function here or make it global/static if needed elsewhere
    private func singleLineDescription(_ text: String?, maxLength: Int = 50) -> String? {
        guard var text = text, !text.isEmpty else { return nil }
        text = text.replacingOccurrences(of: "\n", with: " ")
        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "..."
        } else {
            return text
        }
    }

    var body: some View {
        HStack {
            // Image display logic (using placeholder)
            if item.imageURL != nil {
                // Replace with your actual async image loading view (e.g., using AsyncImage)
                // For now, keeping the placeholder:
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(.trailing, 5)
            }
            // Removed the 'else if let imageData = item.imageData...' block as imageData no longer exists

            VStack(alignment: .leading) {
                Text(item.name).font(.headline)
                if let description = singleLineDescription(item.description) {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                Text("Quantity: \(item.quantity)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                if !item.category.isEmpty && item.category != "-- Select Category --" {
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
    }
}