import 'package:hive/hive.dart';

part 'post_model.g.dart';

/// A single post from https://jsonplaceholder.typicode.com/posts.
///
/// Extends [HiveObject] so instances can be stored directly in a box and gain
/// helpers like `.key`, `.save()` and `.delete()`.
///
/// IMPORTANT: a [HiveObject] can live in only ONE box at a time. To add a post
/// to the favorites box, store a *fresh copy* (see [copy]) rather than the same
/// instance that already lives in postsBox.
@HiveType(typeId: 0)
class Post extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String body;

  @HiveField(3)
  int userId;

  Post({
    required this.id,
    required this.title,
    required this.body,
    required this.userId,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      userId: json['userId'],
    );
  }

  /// Returns a brand-new [Post] with the same data but no box attachment.
  /// Use this before saving into a second box (e.g. favoritesBox).
  Post copy() => Post(id: id, title: title, body: body, userId: userId);
}
