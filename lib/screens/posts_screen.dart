import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/favorites_service.dart';
import 'favorites_screen.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final PostService _service = PostService();
  final FavoritesService _favorites = FavoritesService();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _service.getPosts();
  }

  Future<void> _refresh() async {
    setState(() {
      _postsFuture = _service.getPosts();
    });
    await _postsFuture;
  }

  void _openFavorites() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          // Favorites navigation with a live count badge.
          ValueListenableBuilder(
            valueListenable: Hive.box<Post>(FavoritesService.boxName).listenable(),
            builder: (context, Box<Post> box, _) {
              return IconButton(
                tooltip: 'Favorites',
                icon: Badge(
                  isLabelVisible: box.isNotEmpty,
                  label: Text('${box.length}'),
                  child: const Icon(Icons.favorite),
                ),
                onPressed: _openFavorites,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return _ErrorState(
              message: '${snapshot.error}',
              onRetry: _refresh,
            );
          } else if (snapshot.hasData) {
            final posts = snapshot.data!;
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return PostCard(
                    post: post,
                    // The star rebuilds itself whenever favoritesBox changes,
                    // so tapping it updates the icon immediately.
                    trailing: ValueListenableBuilder(
                      valueListenable:
                          Hive.box<Post>(FavoritesService.boxName).listenable(),
                      builder: (context, Box<Post> box, _) {
                        final isFav = _favorites.isFavorite(post.id);
                        return IconButton(
                          tooltip: isFav ? 'Remove favorite' : 'Add favorite',
                          icon: Icon(
                            isFav ? Icons.star : Icons.star_border,
                            color: isFav ? Colors.amber[700] : null,
                          ),
                          onPressed: () => _favorites.toggleFavorite(post),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// Shared card used by both the Posts list and the Favorites list.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, this.trailing});

  final Post post;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(post.id.toString())),
        title: Text(
          post.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: trailing,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
