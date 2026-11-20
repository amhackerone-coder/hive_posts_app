import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_posts_app/models/post_model.dart';
import 'package:hive_posts_app/services/favorites_service.dart';

/// These tests run against a real Hive database in a temporary directory,
/// so they exercise the actual persistence code path (no mocks).
void main() {
  late Directory tempDir;
  final service = FavoritesService();

  Post samplePost(int id) => Post(
        id: id,
        title: 'Title $id',
        body: 'Body $id',
        userId: 1,
      );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_fav_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PostAdapter());
    }
    await Hive.openBox<Post>(FavoritesService.boxName);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('toggleFavorite adds a post when it is not already a favorite', () async {
    final post = samplePost(1);
    expect(service.isFavorite(1), isFalse);

    await service.toggleFavorite(post);

    expect(service.isFavorite(1), isTrue);
    expect(service.getFavorites().length, 1);
    expect(service.getFavorites().first.title, 'Title 1');
  });

  test('toggleFavorite removes a post when it is already a favorite', () async {
    final post = samplePost(2);
    await service.toggleFavorite(post); // add
    expect(service.isFavorite(2), isTrue);

    await service.toggleFavorite(post); // remove

    expect(service.isFavorite(2), isFalse);
    expect(service.getFavorites(), isEmpty);
  });

  test('favorites are keyed by post id (no duplicates)', () async {
    await service.toggleFavorite(samplePost(5));
    // Re-adding the same id after a remove should not create duplicates.
    await service.toggleFavorite(samplePost(5)); // remove
    await service.toggleFavorite(samplePost(5)); // add again

    expect(service.getFavorites().length, 1);
    expect(service.isFavorite(5), isTrue);
  });

  test('a stored favorite is an independent copy, not a postsBox instance',
      () async {
    // Simulate a post that already lives in postsBox.
    final postsBox = await Hive.openBox<Post>('postsBox');
    final original = samplePost(7);
    await postsBox.add(original); // now `original` belongs to postsBox

    // Favoriting must NOT throw, because the service stores a copy.
    await service.toggleFavorite(original);

    // Clearing postsBox (as getPosts() does on every refresh) must not touch
    // favorites.
    await postsBox.clear();

    expect(service.isFavorite(7), isTrue);
    expect(service.getFavorites().length, 1);
  });

  test('favorites survive a box close/reopen (restart simulation)', () async {
    await service.toggleFavorite(samplePost(9));
    await Hive.box<Post>(FavoritesService.boxName).close();

    // Reopen as a fresh app launch would.
    await Hive.openBox<Post>(FavoritesService.boxName);

    expect(service.isFavorite(9), isTrue);
    expect(service.getFavorites().length, 1);
  });
}
