import XCTest
@testable import GroceryApp // Replace GroceryApp with your actual app name

class GroceryAppTests: XCTestCase {

    var inventoryManager: InventoryManager!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // Clear UserDefaults for a clean slate before each test
        UserDefaults.standard.removeObject(forKey: "groceryInventory")
        inventoryManager = InventoryManager() // Create a fresh manager for each test
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        inventoryManager = nil
        UserDefaults.standard.removeObject(forKey: "groceryInventory") // Clean up after test
    }

    func testAddItem() throws {
        // Given: An empty inventory manager
        XCTAssertEqual(inventoryManager.inventory.count, 0, "Inventory should be empty initially")

        // When: An item is added
        let itemName = "Milk"
        let quantity = 1
        inventoryManager.addItem(name: itemName, quantity: quantity, category: "Dairy")

        // Then: The inventory count should be 1 and the item details should match
        XCTAssertEqual(inventoryManager.inventory.count, 1, "Inventory should have one item after adding")
        let addedItem = inventoryManager.inventory.first!
        XCTAssertEqual(addedItem.name, itemName)
        XCTAssertEqual(addedItem.quantity, quantity)
        XCTAssertEqual(addedItem.category, "Dairy")
    }

    func testUpdateItem() throws {
        // Given: An inventory manager with one item
        inventoryManager.addItem(name: "Bread", quantity: 1)
        var itemToUpdate = inventoryManager.inventory.first!
        XCTAssertEqual(itemToUpdate.quantity, 1)

        // When: The item's quantity is updated
        let newQuantity = 2
        itemToUpdate.quantity = newQuantity
        inventoryManager.updateItem(item: itemToUpdate)

        // Then: The item in the inventory should have the updated quantity
        let updatedItem = inventoryManager.inventory.first!
        XCTAssertEqual(updatedItem.id, itemToUpdate.id) // Ensure it's the same item
        XCTAssertEqual(updatedItem.quantity, newQuantity, "Item quantity should be updated")
        XCTAssertEqual(inventoryManager.inventory.count, 1, "Inventory count should remain 1")
    }

    func testRemoveItem() throws {
        // Given: An inventory manager with two items
        inventoryManager.addItem(name: "Eggs", quantity: 12)
        inventoryManager.addItem(name: "Cheese", quantity: 1)
        XCTAssertEqual(inventoryManager.inventory.count, 2)
        let firstItemId = inventoryManager.inventory.first!.id

        // When: The first item is removed
        inventoryManager.removeItem(at: IndexSet(integer: 0))

        // Then: The inventory count should be 1 and the remaining item should be "Cheese"
        XCTAssertEqual(inventoryManager.inventory.count, 1, "Inventory should have one item after removal")
        let remainingItem = inventoryManager.inventory.first!
        XCTAssertNotEqual(remainingItem.id, firstItemId)
        XCTAssertEqual(remainingItem.name, "Cheese")
    }

    func testPersistence() throws {
        // Given: An inventory manager with one item saved
        inventoryManager.addItem(name: "Apples", quantity: 5)
        let originalCount = inventoryManager.inventory.count
        let originalItemName = inventoryManager.inventory.first?.name

        // When: A new inventory manager is created (simulating app restart)
        inventoryManager = nil // Release the old one
        let newInventoryManager = InventoryManager() // This should load from UserDefaults

        // Then: The new manager should load the saved item
        XCTAssertEqual(newInventoryManager.inventory.count, originalCount, "Inventory count should be loaded from persistence")
        XCTAssertEqual(newInventoryManager.inventory.first?.name, originalItemName, "Item name should be loaded from persistence")
    }

    // Example of a performance test (optional)
    // func testPerformanceExample() throws {
    //     self.measure {
    //         // Put the code you want to measure the time of here.
    //         for i in 0..<100 {
    //             inventoryManager.addItem(name: "Item \(i)", quantity: 1)
    //         }
    //     }
    // }
}
