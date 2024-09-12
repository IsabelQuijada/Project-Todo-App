import Foundation

// `Todo` struct with properties: id (UUID), title (String), and isCompleted (Bool).
// Conforms to `CustomStringConvertible` and `Codable`.
struct Todo: Codable, CustomStringConvertible {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
    }

    var description: String {
        let status = isCompleted ? "✅" : "❌"
        return "\(status) \(title)"
    }
}

// `Cache` protocol with method signatures for saving and loading todos.
protocol Cache {
    func save(todos: [Todo]) -> Bool
    func load() -> [Todo]?
}

// `JSONFileManagerCache`: This implementation uses the file system 
// to persist and retrieve the list of todos.
final class JSONFileManagerCache: Cache {
    private let fileName = "todos.json"

    func save(todos: [Todo]) -> Bool {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(todos) {
            let url = getDocumentsDirectory().appendingPathComponent(fileName)
            do {
                try data.write(to: url)
                return true
            } catch {
                print("Error saving todos: \(error)")
                return false
            }
        }
        return false
    }

    func load() -> [Todo]? {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        if let data = try? Data(contentsOf: url) {
            let decoder = JSONDecoder()
            return try? decoder.decode([Todo].self, from: data)
        }
        return nil
    }

    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

// `InMemoryCache`: Keeps todos in an array during the session.
final class InMemoryCache: Cache {
    private var todos = [Todo]()

    func save(todos: [Todo]) -> Bool {
        self.todos = todos
        return true
    }

    func load() -> [Todo]? {
        return todos.isEmpty ? nil : todos
    }
}

// `TodosManager` class with methods to manage todos.
final class TodosManager {
    private var todos: [Todo] = []
    private let cache: Cache

    init(cache: Cache) {
        self.cache = cache
        self.todos = cache.load() ?? []
    }

    func add(_ title: String) {
        let newTodo = Todo(title: title)
        todos.append(newTodo)
        if cache.save(todos: todos) {
            print("📍 \(newTodo.title) - has been added to your list.")
        } else {
            print("Failed to save the new todo.")
        }
    }

    func listTodos() {
        print("📝 These are your todos:")
        for (index, todo) in todos.enumerated() {
            print("\(index): \(todo)")
        }
    }

    func toggleCompletion(at index: Int) {
        guard index >= 0 && index < todos.count else { return }
        todos[index].isCompleted.toggle()
        if cache.save(todos: todos) {
            print("✅ \(todos[index].title) - is now marked as complete.")
        } else {
            print("Failed to mark as complete.")
        }
    }

    func delete(at index: Int) {
        guard index >= 0 && index < todos.count else { return }
        let deletedTodo = todos[index]
        todos.remove(at: index)
        if cache.save(todos: todos) {
            print("🗑️ \(deletedTodo.title) - This todo has been deleted.")
        } else {
            print("Failed to delete todo")
        }
    }
}

// `App` class with `run()` method to handle user input and execute commands.
final class App {
    private let manager: TodosManager

    init(manager: TodosManager) {
        self.manager = manager
    }

    enum Command: String {
        case add
        case list
        case toggle
        case delete
        case exit
    }

    func run() {
        print("🌟 Welcome to the Todo App 🌟")
        while true {
            print("What would you like to do today? (add, list, toggle, delete, exit)")
            if let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) {
                guard let command = Command(rawValue: input) else {
                    print("Invalid command")
                    continue
                }
                switch command {
                case .add:
                    print("Enter the title of the todo:")
                    if let title = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) {
                        manager.add(title)
                    }
                case .list:
                    manager.listTodos()
                case .toggle:
                    print("Enter the index of the todo to toggle:")
                    if let indexStr = readLine(), let index = Int(indexStr) {
                        manager.toggleCompletion(at: index)
                    }
                case .delete:
                    print("Enter the index of the todo to delete:")
                    if let indexStr = readLine(), let index = Int(indexStr) {
                        manager.delete(at: index)
                    }
                case .exit:
                    print("Exiting the Todo App. Goodbye! ✨")
                    return
                }
            }
        }
    }
}

// Setup and run the app.
let cache = JSONFileManagerCache() // or InMemoryCache() for in-session storage
let manager = TodosManager(cache: cache)
let app = App(manager: manager)
app.run()
