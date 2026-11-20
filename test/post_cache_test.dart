import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_posts_app/models/post_model.dart';

/// Verifies the Hive caching behaviour that PostService relies on for offline
/// mode: posts written to postsBox can be read back after a close/reopen, and
/// a refresh (clear + addAll) replaces the cache cleanly.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_cache_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PostAdapter());
    }
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('posts cached to Hive are retrievable offline after reopen', () async {
    var box = await Hive.openBox<Post>('postsBox');
    await box.addAll([
      Post(id: 1, title: 'A', body: 'body a', userId: 1),
      Post(id: 2, title: 'B', body: 'body b', userId: 1),
    ]);
    expect(box.length, 2);

    await box.close();

    // Simulate relaunching offline: reopen and read from cache.
    box = await Hive.openBox<Post>('postsBox');
    final cached = box.values.toList();

    expect(cached.length, 2);
    expect(cached.map((p) => p.title), containsAll(['A', 'B']));
  });

  test('refresh replaces the cache (clear + addAll)', () async {
    final box = await Hive.openBox<Post>('postsBox');
    await box.addAll([Post(id: 1, title: 'Old', body: 'old', userId: 1)]);

    // Simulate a successful API refresh.
    await box.clear();
    await box.addAll([
      Post(id: 10, title: 'New 10', body: 'n', userId: 2),
      Post(id: 11, title: 'New 11', body: 'n', userId: 2),
    ]);

    expect(box.length, 2);
    expect(box.values.first.title, 'New 10');
  });

  test('empty cache means no data to fall back on', () async {
    final box = await Hive.openBox<Post>('postsBox');
    // Fresh install + offline == empty box; PostService throws in this case.
    expect(box.isEmpty, isTrue);
  });
}
