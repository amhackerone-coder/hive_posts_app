import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/post_model.dart';
import '../services/favorites_service.dart';
import 'posts_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesService();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      // Rebuilds automatically whenever the favorites box changes, so removing
      // a favorite here updates the list instantly.
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Post>(FavoritesService.boxName).listenable(),
        builder: (context, Box<Post> box, _) {
          final posts = box.values.toList();

          if (posts.isEmpty) {
            return const _EmptyState();
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                trailing: IconButton(
                  tooltip: 'Remove favorite',
                  icon: Icon(Icons.star, color: Colors.amber[700]),
                  onPressed: () => favorites.toggleFavorite(post),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_border, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'No favorites yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 4),
          Text(
            'Tap the star on a post to save it here.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
