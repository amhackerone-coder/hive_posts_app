# Hive Posts App — Offline-First Flutter (Section 5 Lab, Fall 2026)

An offline-capable Posts application built with **Hive** (local NoSQL storage).
It fetches posts from the [JSONPlaceholder](https://jsonplaceholder.typicode.com/posts)
API, caches them in Hive, and transparently serves the cached data when there is
no internet. It also lets you mark posts as **Favorites**, stored in a separate
Hive box that survives refreshes and app restarts.

> Data flow: `INTERNET → API → Hive → ListView`
> The app always shows the last saved data, even in airplane mode.

---

## Features

- **Offline-first posts** — API first, Hive cache as fallback.
- **Automatic caching** — every successful fetch replaces the local cache.
- **Graceful states** — loading spinner, error view with retry, data list.
- **Pull-to-refresh** — swipe down to re-fetch and re-cache.
- **Favorites** — tap a star to favorite/unfavorite a post.
  - Filled amber star (`Icons.star`) for favorites, outlined (`Icons.star_border`) otherwise.
  - Instant UI updates via `ValueListenableBuilder` on the favorites box.
  - Stored in a **separate** `favoritesBox` (so refreshing posts never wipes them).
  - Favorites screen with a friendly "No favorites yet" empty state.
  - Live favorites count badge in the AppBar.
- **Clean layering** — UI never touches `http` or `Hive` directly; only the services do.

---

## Project Structure

```
hive_posts_app/
├── pubspec.yaml
├── analysis_options.yaml
├── .gitignore
├── README.md
├── screenshots/                 # add your screenshots here (see checklist)
├── lib/
│   ├── main.dart                # init Hive, register adapter, open boxes, run app
│   ├── models/
│   │   ├── data.dart            # Part 1 practice model + Hive annotations
│   │   ├── data.g.dart          # generated DataAdapter
│   │   ├── post_model.dart      # Post class + Hive annotations + copy()
│   │   └── post_model.g.dart    # generated PostAdapter
│   ├── services/
│   │   ├── post_service.dart    # API-first, Hive-fallback data layer
│   │   └── favorites_service.dart # favoritesBox: toggle / isFavorite / getFavorites
│   └── screens/
│       ├── posts_screen.dart    # posts list, states, pull-to-refresh, star + AppBar nav
│       └── favorites_screen.dart# favorites list + empty state
└── test/
    ├── favorites_service_test.dart
    └── post_cache_test.dart
```

### Layer responsibilities

| Layer   | File                   | Responsibility                                            |
|---------|------------------------|-----------------------------------------------------------|
| Model   | `post_model.dart`      | Describes a Post and how it is stored and parsed          |
| Service | `post_service.dart`    | Where data comes from: API first, Hive as a fallback      |
| Service | `favorites_service.dart`| Manages the separate favorites box                       |
| Screen  | `posts_screen.dart`    | Shows loading / error / list states; never calls http/Hive|
| App     | `main.dart`            | Initialises Hive, registers adapters, opens boxes         |

---

## Architecture & Data Flow

**`getPosts()` decision logic (PostService):**

1. Open `postsBox`.
2. Try to fetch from the API.
3. **Success** → clear the box, save the new posts, return them.
4. **Failure (no internet)** → if the box has data, return it; otherwise throw
   `No Internet and No Cached Data`.

**Why favorites need their own box:** `getPosts()` calls `postsBox.clear()` on
every refresh. Keeping favorites in `favoritesBox` means a refresh never deletes
them.

**HiveObject single-box rule:** a `HiveObject` can live in only one box at a
time. The posts list holds `Post` instances that already belong to `postsBox`,
so `FavoritesService.toggleFavorite` stores a **copy** (`post.copy()`), keyed by
`post.id`, rather than the original instance.

---

## Dependencies (as specified by the lab)

```yaml
dependencies:
  http: ^1.1.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  connectivity_plus: ^5.0.2

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

---

## Installation & Running

> This repo contains the complete Dart source, generated adapters, and tests.
> It does **not** include platform scaffolding (`android/`, `ios/`, `web/`,
> etc.). Generate it once on a machine with the Flutter SDK installed.

### 1. Install the Flutter SDK
Follow <https://docs.flutter.dev/get-started/install> and confirm:

```bash
flutter --version
flutter doctor
```

### 2. Add platform scaffolding without losing the source

`flutter create .` would overwrite `pubspec.yaml`, `lib/main.dart`, and
`test/`. To avoid that, scaffold a fresh project and copy the source in:

```bash
# from the folder that contains this repo
flutter create hive_posts_app_scaffold --project-name hive_posts_app
# copy this repo's lib/, test/, pubspec.yaml, analysis_options.yaml
# over the generated project, then work inside it.
```

Or, if you prefer to scaffold in place, back up the four owned files first:

```bash
cd hive_posts_app
# only add missing platform folders:
flutter create . --project-name hive_posts_app
# then restore your versions of pubspec.yaml, lib/main.dart, test/ if overwritten
```

### 3. Resolve dependencies and generate adapters

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

`build_runner` regenerates `data.g.dart` and `post_model.g.dart`. The versions
committed here are byte-for-byte what the generator produces, so the project
compiles even before you run it — but regenerating is the canonical step.

### 4. Run

```bash
flutter run
```

### 5. Analyze & test

```bash
flutter analyze
flutter test
```

---

## Testing

Automated tests (run with `flutter test`) use a real Hive database in a
temporary directory — no mocks:

- **`favorites_service_test.dart`**
  - add on toggle, remove on toggle, no duplicate keys
  - stored favorite is an independent copy (clearing `postsBox` keeps favorites)
  - favorites survive a box close/reopen (restart simulation)
- **`post_cache_test.dart`**
  - posts cached to Hive are retrievable after reopen (offline path)
  - refresh replaces the cache (`clear` + `addAll`)
  - empty cache behaviour

### Manual offline test procedure (from the lab)

| # | Action | Expected result |
|---|--------|-----------------|
| 1 | Run the app with internet on | Posts load; console prints `Loaded from API and cached to Hive` |
| 2 | Close the app, turn on airplane mode | — |
| 3 | Open the app again | Posts still appear; console prints `Loaded from Hive offline` |
| 4 | Uninstall the app, turn on airplane mode, run it | Error: `No Internet and No Cached Data` |

### Favorites verification

1. Favorite a few posts — stars fill immediately; AppBar badge count rises.
2. Open the Favorites screen — the favorited posts appear.
3. Remove one from the Favorites screen — it disappears instantly.
4. Close the app, enable airplane mode, reopen — favorites are still there.
5. Empty all favorites — the "No favorites yet" message shows.

---

## Screenshots

Place images in `screenshots/` and link them here. See
[`screenshots/README.md`](screenshots/README.md) for the full checklist. Example:

| Posts (online) | Favorite toggled | Favorites screen | Offline cache |
|---|---|---|---|
| _add image_ | _add image_ | _add image_ | _add image_ |

---

## License

Educational lab project — Fall 2026, Section 5.
