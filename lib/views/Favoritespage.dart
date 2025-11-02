// views/Favoritespage.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:musicapp/viewmodels/favorites_view_model.dart';
import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:provider/provider.dart';
import 'package:musicapp/data/Models.dart' as mymodel;

class Favoritespage extends StatelessWidget {
  const Favoritespage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FavoritesViewModel>();
    final favoritesStream = viewModel.favoritesStream;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Beğenilen Şarkılar"),
      ),
      body: StreamBuilder<List<mymodel.Song>>(
        stream: favoritesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text("Favoriler yüklenirken bir hata oluştu."));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Henüz beğenilen şarkı yok."));
          }

          final favoriteSongs = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.only(
                bottom: context.watch<MiniPlayerViewModel>().isActive
                    ? 85.0
                    : 10.0),
            itemCount: favoriteSongs.length,
            itemBuilder: (context, index) {
              final song = favoriteSongs[index];
              return ListTile(
                leading: Image.network(
                  song.songImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.music_note, size: 50),
                ),
                title: Text(song.songName, maxLines: 1),
                subtitle: Text(song.songArtist, maxLines: 1),
                trailing: IconButton(
                  icon: const Icon(Icons.favorite,
                      color: Colors.green), // Beğenilmiş ikon
                  onPressed: () {
                    // Favorilerden çıkar
                    context
                        .read<FavoritesViewModel>()
                        .removeFavorite(song.songId);
                  },
                ),
                onTap: () {
                  context.read<MiniPlayerViewModel>().playSongModels(
                        favoriteSongs,
                        initialIndex: index,
                      );
                },
              );
            },
          );
        },
      ),
    );
  }
}
