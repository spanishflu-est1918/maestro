import XCTest
@testable import MaestroCore

/// Performance benchmarks for Maestro operations
/// Measures database, query, and algorithm performance
final class PerformanceTests: XCTestCase {

    func testDatabaseConnectionPerformance() throws {
        measure {
            let db = Database()
            try? db.connect()
            db.close()
        }
    }

    func testSpaceCreationPerformance() throws {
        let db = Database()
        try db.connect()
        defer { db.close() }

        let spaceStore = SpaceStore(database: db)

        measure {
            for i in 0..<100 {
                let space = Space(name: "Benchmark Space \(i)", color: "#FF0000")
                try? spaceStore.create(space)
            }
        }
    }

    func testTaskCreationPerformance() throws {
        let db = Database()
        try db.connect()
        defer { db.close() }

        let spaceStore = SpaceStore(database: db)
        let taskStore = TaskStore(database: db)

        let space = Space(name: "Benchmark Space", color: "#FF0000")
        try spaceStore.create(space)

        measure {
            for i in 0..<100 {
                let task = Task(
                    spaceId: space.id,
                    title: "Benchmark Task \(i)",
                    status: .todo,
                    priority: .medium
                )
                try? taskStore.create(task)
            }
        }
    }

    func testTaskQueryPerformance() throws {
        let db = Database()
        try db.connect()
        defer { db.close() }

        let spaceStore = SpaceStore(database: db)
        let taskStore = TaskStore(database: db)

        // Create test data
        let space = Space(name: "Benchmark Space", color: "#FF0000")
        try spaceStore.create(space)

        for i in 0..<1000 {
            let task = Task(
                spaceId: space.id,
                title: "Task \(i)",
                status: .todo,
                priority: .medium
            )
            try taskStore.create(task)
        }

        // Measure query performance
        measure {
            _ = try? taskStore.list(spaceId: space.id)
        }
    }

    func testSurfacingAlgorithmPerformance() throws {
        let db = Database()
        try db.connect()
        defer { db.close() }

        let spaceStore = SpaceStore(database: db)
        let taskStore = TaskStore(database: db)

        // Create test data with varied priorities
        let space = Space(name: "Benchmark Space", color: "#FF0000")
        try spaceStore.create(space)

        let priorities: [TaskPriority] = [.urgent, .high, .medium, .low, .none]
        let statuses: [TaskStatus] = [.inbox, .todo, .inProgress]

        for i in 0..<500 {
            let task = Task(
                spaceId: space.id,
                title: "Task \(i)",
                status: statuses[i % statuses.count],
                priority: priorities[i % priorities.count]
            )
            try taskStore.create(task)
        }

        // Measure surfacing algorithm
        measure {
            _ = try? taskStore.getSurfaced(limit: 20)
        }
    }

    func testDocumentCreationPerformance() throws {
        let db = Database()
        try db.connect()
        defer { db.close() }

        let spaceStore = SpaceStore(database: db)
        let documentStore = DocumentStore(database: db)

        let space = Space(name: "Benchmark Space", color: "#FF0000")
        try spaceStore.create(space)

        let content = """
        # Benchmark Document

        This is a test document with some content to measure performance.

        ## Section 1

        Lorem ipsum dolor sit amet, consectetur adipiscing elit.

        ## Section 2

        More content here to make the document realistic.
        """

        measure {
            for i in 0..<50 {
                let doc = Document(
                    spaceId: space.id,
                    title: "Benchmark Doc \(i)",
                    content: content
                )
                try? documentStore.create(doc)
            }
        }
    }

    func testComplexQueryPerformance() throws {
        let db = Database()
        try db.connect()
        defer { db.close() }

        let spaceStore = SpaceStore(database: db)
        let taskStore = TaskStore(database: db)

        // Create hierarchical spaces
        let root = Space(name: "Root", color: "#FF0000")
        try spaceStore.create(root)

        for i in 0..<10 {
            let child = Space(name: "Child \(i)", color: "#00FF00", parentId: root.id)
            try spaceStore.create(child)

            // Add tasks to each child space
            for j in 0..<50 {
                let task = Task(
                    spaceId: child.id,
                    title: "Task \(i)-\(j)",
                    status: .todo,
                    priority: .medium
                )
                try taskStore.create(task)
            }
        }

        // Measure complex query (all tasks across all child spaces)
        measure {
            let children = try? spaceStore.list(parentFilter: .some(root.id))
            if let children = children {
                for child in children {
                    _ = try? taskStore.list(spaceId: child.id)
                }
            }
        }
    }

    func testBulkUpdatePerformance() throws {
        let db = Database()
        try db.connect()
        defer { db.close() }

        let spaceStore = SpaceStore(database: db)
        let taskStore = TaskStore(database: db)

        let space = Space(name: "Benchmark Space", color: "#FF0000")
        try spaceStore.create(space)

        // Create tasks
        var tasks: [Task] = []
        for i in 0..<100 {
            let task = Task(
                spaceId: space.id,
                title: "Task \(i)",
                status: .todo,
                priority: .medium
            )
            try taskStore.create(task)
            tasks.append(task)
        }

        // Measure bulk updates
        measure {
            for var task in tasks {
                task.status = .done
                try? taskStore.update(task)
            }
        }
    }

    func testConcurrentReadPerformance() throws {
        let db = Database()
        try db.connect()
        defer { db.close() }

        let spaceStore = SpaceStore(database: db)
        let taskStore = TaskStore(database: db)

        // Create test data
        let space = Space(name: "Benchmark Space", color: "#FF0000")
        try spaceStore.create(space)

        for i in 0..<100 {
            let task = Task(
                spaceId: space.id,
                title: "Task \(i)",
                status: .todo
            )
            try taskStore.create(task)
        }

        // Measure concurrent reads
        measure {
            let group = DispatchGroup()

            for _ in 0..<10 {
                group.enter()
                DispatchQueue.global().async {
                    _ = try? taskStore.list(spaceId: space.id)
                    group.leave()
                }
            }

            group.wait()
        }
    }

    func testLargeDatasetPerformance() throws {
        let db = Database()
        try db.connect()
        defer { db.close() }

        let spaceStore = SpaceStore(database: db)
        let taskStore = TaskStore(database: db)

        // Create test data
        let space = Space(name: "Large Dataset Test", color: "#FF0000")
        try spaceStore.create(space)

        // Measure creating a large number of tasks
        measure {
            for i in 0..<500 {
                let task = Task(
                    spaceId: space.id,
                    title: "Task \(i)",
                    status: .todo
                )
                try? taskStore.create(task)
            }
        }
    }
}

// MARK: - Performance Results Documentation

/*
 ## Performance Benchmarks

 These tests measure the performance of core Maestro operations. Results will vary based on hardware.

 ### Expected Performance Targets

 - Database Connection: < 10ms
 - Space Creation (100): < 100ms
 - Task Creation (100): < 200ms
 - Task Query (1000 tasks): < 50ms
 - Surfacing Algorithm (500 tasks): < 100ms
 - Document Creation (50): < 150ms
 - Complex Query (10 spaces, 500 tasks): < 200ms
 - Bulk Update (100 tasks): < 150ms
 - Concurrent Reads (10 threads): < 100ms
 - Large Dataset (500 tasks): < 500ms

 ### Optimization Notes

 1. **Database Indexes**: All foreign keys and frequently queried columns have indexes
 2. **Connection Pooling**: Single shared connection for all stores
 3. **Batch Operations**: Use transactions for bulk operations
 4. **Lazy Loading**: Documents only load content when needed
 5. **Query Optimization**: Surfacing algorithm uses indexed columns

 ### Running Benchmarks

 ```bash
 # Run all performance tests
 swift test --filter PerformanceTests

 # Run specific benchmark
 swift test --filter testTaskQueryPerformance

 # With verbose output
 swift test --filter PerformanceTests -v
 ```

 ### Interpreting Results

 - **Time**: Lower is better (measured in seconds)
 - **Stddev**: Lower variance indicates consistent performance
 - **Relative Standard Deviation**: < 10% is excellent, < 20% is good

 ### Performance Comparison

 After making changes, compare before/after:

 ```bash
 # Before changes
 swift test --filter PerformanceTests > before.txt

 # After changes
 swift test --filter PerformanceTests > after.txt

 # Compare
 diff before.txt after.txt
 ```
 */
