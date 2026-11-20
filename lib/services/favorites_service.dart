import 'package:hive/hive.dart';
import '../models/post_model.dart';

/// Manages the separate `favoritesBox`.
///
/// Favorites live in their own box so they survive `postsBox.clear()` (called
/// on every refresh in [PostService.getPosts]) and persist across app restarts.
///
/// The post id is used as the key, so:
///  - box.containsKey(id) tells you if a post is a favorite,
///  - box.delete(id)      removes it,
///  - box.put(id, copy)   adds it.
class FavoritesService {
  static const String boxName = 'favoritesBox';

  Box<Post> get _box => Hive.box<Post>(boxName);

  /// Adds the post to favorites if missing, or removes it if already there.
  ///
  /// A HiveObject can live in only one box at a time, so we store a *copy*
  /// of the post (never the instance that already lives in postsBox).
  Future<void> toggleFavorite(Post post) async {
    if (_box.containsKey(post.id)) {
      await _box.delete(post.id);
    } else {
      await _box.put(post.id, post.copy());
    }
  }

  /// True if a post with [id] is currently a favorite.
  bool isFavorite(int id) => _box.containsKey(id);

  /// All saved favorites. Reading an already-open box is synchronous.
  List<Post> getFavorites() => _box.values.toList();
}
