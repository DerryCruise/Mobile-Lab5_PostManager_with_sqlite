# Offline Posts Manager - Lab Discussion

## 1. Which dependencies did you use and why?
- **`sqflite`**: This is the core plugin used to interact with SQLite databases in Flutter. It provides the necessary APIs to create databases, execute raw SQL queries, and perform CRUD operations seamlessly.
- **`path`**: Used for cross-platform path manipulation. It ensures that the absolute path joining for the database file (e.g., `join(await getDatabasesPath(), 'posts_manager.db')`) resolves correctly regardless of whether the app is running on iOS or Android.
- **`intl`**: (Bonus) Used to format the current date properly when creating or editing a post.

### Explain why SQLite is necessary to store data locally
Mobile devices often lose network connectivity. Without local storage, data fetched or created during a session would be lost upon app termination or crash. SQLite provides a fully-featured, lightweight relational database management system that lives inside the app's sandboxed storage. It persists data securely, allowing the staff to manage posts 100% offline, guaranteeing that no work is lost and that posts are immediately available without loading times when returning to the app.

---

## 2. How do you handle database exceptions?

### Handling database not initialized
In our `DatabaseHelper` singleton, the `database` getter asynchronously checks if the `_database` object is null. If it is null, it invokes `_initDatabase()`. During initialization (e.g., while fetching the databases path or running `openDatabase`), we wrap the logic in a `try-catch` block. If exception occurs (e.g. disk full or missing permissions), it throws a custom `DatabaseException` clearly indicating the database structure could not be initialized.

### Handling insert/update/delete errors
Every CRUD method (`insertPost`, `updatePost`, `deletePost`) wraps the `db.insert()`, `db.update()`, and `db.delete()` calls in a `try-catch` block. If a constraint fails (e.g., a query error or locked database file), it intercepts the generic exception and throws a contextual `DatabaseException` (such as "Failed to insert post"). The UI Layer (Screens) captures this exception and shows a user-friendly `SnackBar` rather than crashing the app.

### Handling invalid or corrupted data
When retrieving records via `getPosts()`, if the database file gets corrupted or parsing the Map into a `Post` model fails (e.g. unexpectedly missing columns or wrong data types), the `fromMap` constructor or database query will throw an error. Our `getPosts()` method catches any error during retrieval or map iteration and throws a custom exception: "Failed to load posts or corrupted data". The `FutureBuilder` in the UI detects `snapshot.hasError` and cleanly displays the error message safely on screen.

---

## 3. Explain SQLite in Flutter

### Database vs Table
- **Database**: The container stored on the device's storage (e.g., `posts_manager.db`). It holds all the configurations, schema, and tables. In Flutter, we interact with it through the `Database` object returned by `sqflite`.
- **Table**: A structured collection of data organized into rows and columns within the database. For example, the `posts` table contains columns for `id`, `title`, `content`, and `date`. A database can have multiple distinct tables.

### CRUD Operations
CRUD stands for Create, Read, Update, and Delete. In `sqflite`, these are mapped to convenient asynchronous methods:
- **Create**: Uses `db.insert(table, dataMap)` to insert a row. We use `ConflictAlgorithm.replace` to prevent duplicate IDs.
- **Read**: Uses `db.query(table)` to fetch rows as a `List<Map<String, dynamic>>`.
- **Update**: Uses `db.update(table, dataMap, where: ..., whereArgs: ...)` to modify an existing record based on its unique ID.
- **Delete**: Uses `db.delete(table, where: ..., whereArgs: ...)` to remove a record based on its unique ID.

### How Flutter interacts with the database asynchronously
Mobile apps operate on a single "main" UI thread. Database I/O (reading or writing files to disk) takes an unpredictable amount of time and could freeze the UI if run synchronously. Flutter solves this by utilizing **Futures** and `async`/`await` patterns:
- When a CRUD call is made (e.g. `await db.insert(...)`), it is sent to a background isolate/thread (via the Platform channel in native code). 
- The UI thread is free to continue drawing frames (e.g., spinning a `CircularProgressIndicator`).
- Once the database operation finishes on the native side, the result is sent back to Dart as a resolved `Future`. The UI then reacts, e.g., by updating the `ListView` or hiding the loading spinner. `FutureBuilder` is a widget explicitly designed to handle this seamless transition from a "Waiting" state to a "Data/Error" state based on these Futures.
