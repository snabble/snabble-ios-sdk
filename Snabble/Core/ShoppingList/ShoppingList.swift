//
//  ShoppingList.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

/// a ShoppingList is a collection of ShoppingListItem objects
public final class ShoppingList: Codable {
    private(set) public var items = [ShoppingListItem]()
    public let projectId: Identifier<Project>

    private let directory: String

    public var project: Project? {
        SnabbleAPI.projects.first { $0.id == projectId }
    }

    public var isEmpty: Bool {
        items.isEmpty
    }

    public var count: Int {
        items.count
    }

    public var hasImages: Bool {
        let imgIndex = self.items.firstIndex { $0.product?.imageUrl != nil }
        return imgIndex != nil
    }

    public init(for projectId: Identifier<Project>, directory: String = ShoppingList.listsDirectory) {
        self.projectId = projectId

        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.directory = documentsUrl.appendingPathComponent(directory).path

        if let savedList = self.load() {
            self.items = savedList.items
        } else {
            self.save()
        }
    }

    public func reloadFromDisk() {
        if let savedList = self.load() {
            self.items = savedList.items
        }
    }

    public func itemAt(_ index: Int) -> ShoppingListItem {
        items[index]
    }

    public func append(_ item: ShoppingListItem) {
        items.append(item)
        self.sort()
        self.save()
    }

    public func append(contentsOf items: [ShoppingListItem]) {
        self.items.append(contentsOf: items)
        self.sort()
        self.save()
    }

    public func removeItem(at index: Int) {
        items.remove(at: index)
        self.save()
    }

    public func removeAll() {
        items = []
        self.save()
    }

    public func moveItem(from fromIndex: Int, to toIndex: Int) {
        let item = items[fromIndex]
        items.remove(at: fromIndex)
        items.insert(item, at: toIndex)
        self.save()
    }

    public func replaceItem(at index: Int, with newItem: ShoppingListItem) {
        items[index] = newItem
        self.save()
    }

    public func sort() {
        items.shuffle()
        items.sort(by: <)
    }

    public func toggleChecked(at index: Int) -> Bool {
        items[index].checked.toggle()
        self.save()
        return items[index].checked
    }

    public func setQuantity(to newQuantity: Int, at index: Int) {
        items[index].quantity = newQuantity
        self.save()
    }

    public func increaseQuantity(for item: ShoppingListItem) {
        if let index = findIndex(for: item) {
            let item = itemAt(index)
            item.quantity += 1
        } else {
            item.quantity = 1
            items.append(item)
            self.sort()
        }

        self.save()
    }

    /// decrease quantity
    /// - Parameter item:
    /// - Returns: the new quantity of the item
    public func decreaseQuantity(for item: ShoppingListItem) -> Int {
        defer { self.save() }

        if let index = findIndex(for: item) {
            let item = itemAt(index)

            item.quantity -= 1
            if item.quantity == 0 {
                self.removeItem(at: index)
                self.sort()
            }
            return item.quantity
        }

        return 0
    }

    public func findProductIndex(sku: String) -> Int? {
        self.items.firstIndex(where: { $0.product?.sku == sku })
    }

    public func findIndex(for item: ShoppingListItem) -> Int? {
        self.items.firstIndex { $0 == item }
    }
}

// MARK: - Persistence
extension ShoppingList {
    public static let listsDirectory = "snabble-app-shoppinglists"
    static let fileExtension = ".json"

    public static func fetchListsFromDisk(_ directory: String = listsDirectory) -> [ShoppingList] {
        let fileManager = FileManager.default
        let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(directory).path

        var lists = [ShoppingList]()

        do {
            // make sure our directory exists
            if !fileManager.fileExists(atPath: path) {
                try? fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
            }
            let files = try fileManager.contentsOfDirectory(atPath: path)
            for fileName in files.sorted(by: <) {
                guard fileName.hasSuffix(Self.fileExtension) else {
                    continue
                }

                let basename = String(fileName.dropLast(Self.fileExtension.count))
                let projectId = Identifier<Project>(rawValue: basename)
                if SnabbleAPI.project(for: projectId) == nil {
                    continue
                }

                let list = ShoppingList(for: projectId, directory: directory)
                lists.append(list)
            }
        } catch {
            print("[ShoppingList] error fetching shopping lists from directory: \(error)")
        }

        return lists
    }

    private func listUrl(_ directory: String) -> URL {
        let url = URL(fileURLWithPath: directory)
        return url.appendingPathComponent(self.projectId.rawValue + Self.fileExtension)
    }

    /// persist this shopping list to disk
    private func save() {
        do {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: directory) {
                try fileManager.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
            }

            let data = try JSONEncoder().encode(self)
            try data.write(to: self.listUrl(directory), options: .atomic)
        } catch let error {
            Log.error("error saving shopping list for \(self.projectId): \(error)")
        }
    }

    /// load this shoppping list from disk
    private func load() -> ShoppingList? {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: self.listUrl(directory).path) {
            return nil
        }

        do {
            let data = try Data(contentsOf: self.listUrl(directory))
            let list = try JSONDecoder().decode(ShoppingList.self, from: data)
            return list
        } catch let error {
            Log.error("error loading shopping list for \(self.projectId): \(error)")
            return nil
        }
    }

    /// remove this shopping list from disk
    public func remove() {
        let fileManager = FileManager.default
        let url = self.listUrl(directory)
        do {
            try fileManager.removeItem(at: url)
        } catch {
            Log.error("error deleting list \(error)")
        }
    }
}
