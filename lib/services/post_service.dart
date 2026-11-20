import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

/// The data layer for posts. The UI never talks to http or Hive directly;
/// it only calls [getPosts]. If storage or the API changes later, only this
/// file changes.
class PostService {
  static const String apiUrl = 'https://jsonplaceholder.typicode.com/posts';

  /// API-first, Hive-fallback strategy:
  ///   1. Open postsBox.
  ///   2. Try to fetch from the API.
  ///   3. Success -> clear the box, save the new posts, return them.
  ///   4. Failure (no internet) -> if the box has data, return it;
  ///      otherwise throw "No Internet and No Cached Data".
  Future<List<Post>> getPosts() async {
    // openBox returns the already-open instance if main.dart opened it.
    var box = await Hive.openBox<Post>('postsBox');

    try {
      // 1. Try to fetch online.
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Post> onlinePosts = data.map((e) => Post.fromJson(e)).toList();

        // 2. Save to Hive (replace the old cache).
        await box.clear();
        await box.addAll(onlinePosts);

        // ignore: avoid_print
        print('Loaded from API and cached to Hive: ${onlinePosts.length}');
        return onlinePosts;
      }
    } catch (e) {
      // ignore: avoid_print
      print('API Failed, reason: $e');
    }

    // 3. OFFLINE MODE: return from Hive (works in airplane mode).
    if (box.isNotEmpty) {
      // ignore: avoid_print
      print('Loaded from Hive offline: ${box.length}');
      return box.values.toList();
    } else {
      throw Exception('No Internet and No Cached Data');
    }
  }
}
