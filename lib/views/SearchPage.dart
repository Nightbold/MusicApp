// views/SearchPage.dart

import 'package:flutter/material.dart';

import 'package:flutter/widgets.dart' as flt;

import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:musicapp/viewmodels/search_view_model.dart';
import 'package:musicapp/views/artist_detail_page.dart';
import 'package:musicapp/views/playlist_detail_page.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class SearchPage extends StatelessWidget {
  final auth.User user;

  final TextEditingController _searchController = TextEditingController();

  SearchPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SearchViewModel>();
    final miniPlayerViewModel = context.read<MiniPlayerViewModel>();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // --- ARAMA KUTUSU VE FİLTRELER ---
            _buildSearchBar(context, viewModel),
            _buildFilterChips(context, viewModel),

            // --- ARAMA SONUÇLARI VEYA DURUM MESAJI ---
            Expanded(
              child: _buildResultsArea(context, viewModel, miniPlayerViewModel),
            ),
          ],
        ),
      ),
    );
  }

  // ARAMA KUTUSU WIDGET'I
  Widget _buildSearchBar(BuildContext context, SearchViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,

        onChanged: (value) =>
            viewModel.updateQuery(value), // Sorguyu anlık günceller
        onSubmitted: (_) => viewModel.search(
            triggeredByButton: true), // Enter'a basınca arama yapar

        decoration: InputDecoration(
          hintText: 'Ne dinlemek istersin?',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: viewModel.query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    // 1. TextField'ı temizle
                    _searchController.clear();
                    // 2. ViewModel'daki sorguyu ve sonuçları temizle
                    viewModel.updateQuery('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  // FİLTRE CHIP'LERİ WIDGET'I
  Widget _buildFilterChips(BuildContext context, SearchViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Wrap(
        // Wrap, chipleri ekrana sığdıkça alt satıra indirir
        spacing: 8.0,
        children: [
          FilterChip(
            label: const Text("Şarkı"),
            selected: viewModel.selectedType == SearchType.track,
            onSelected: (_) => viewModel.setSelectedType(SearchType.track),
          ),
          FilterChip(
            label: const Text("Sanatçı"),
            selected: viewModel.selectedType == SearchType.artist,
            onSelected: (_) => viewModel.setSelectedType(SearchType.artist),
          ),
          FilterChip(
            label: const Text("Playlist"),
            selected: viewModel.selectedType == SearchType.playlist,
            onSelected: (_) => viewModel.setSelectedType(SearchType.playlist),
          ),
        ],
      ),
    );
  }

  // ARAMA SONUÇLARINI GÖSTEREN ALAN WIDGET'I
  Widget _buildResultsArea(BuildContext context, SearchViewModel viewModel,
      MiniPlayerViewModel playerViewModel) {
    switch (viewModel.searchState) {
      case SearchState.idle:
        // Başlangıçta veya sorgu boşken gösterilecek widget
        return const Center(child: Text('Aramak için yazmaya başla...'));
      case SearchState.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchState.error:
        return Center(
            child: Text(viewModel.errorMessage ?? 'Bir hata oluştu.'));
      case SearchState.empty:
        return const Center(child: Text('Sonuç bulunamadı.'));
      case SearchState.success:
        // Sonuçları gösteren liste
        return ListView.builder(
          itemCount: viewModel.results.length,
          itemBuilder: (context, index) {
            final item = viewModel.results[index];

            // Gelen sonucun tipine göre farklı ListTile
            if (item is Track) {
              return _buildTrackTile(context, item, playerViewModel);
            } else if (item is Artist) {
              return _buildArtistTile(context, item);
            } else if (item is PlaylistSimple) {
              return _buildPlaylistTile(context, item);
            }

            return const SizedBox.shrink(); // Tanımsız tip için boş widget
          },
        );
    }
  }

  // ŞARKI SONUCU İÇİN LISTTILE
  Widget _buildTrackTile(
      BuildContext context, Track track, MiniPlayerViewModel playerViewModel) {
    final imageUrl = track.album?.images?.isNotEmpty ?? false
        ? track.album!.images!.first.url
        : null;
    return ListTile(
      leading: imageUrl != null
          ? flt.Image.network(imageUrl,
              width: 50, height: 50, fit: BoxFit.cover)
          : const Icon(Icons.music_note, size: 50),
      title:
          Text(track.name ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(track.artists?.first.name ?? '', maxLines: 1),
      trailing: IconButton(
        icon: const Icon(Icons.play_arrow, color: Colors.green),
        onPressed: () {
          // Tek şarkı çalma mantığı (istersen playTrackAndLoadRecommendations kullanılabilir)
          playerViewModel.playTracks([track]);
        },
      ),
      onTap: () {
        // Tıklanınca da çalabilir veya detay sayfasına gidebilir
        playerViewModel.playTracks([track]);
      },
    );
  }

  // SANATÇI SONUCU İÇİN LISTTILE
  Widget _buildArtistTile(BuildContext context, Artist artist) {
    final imageUrl =
        artist.images?.isNotEmpty ?? false ? artist.images!.first.url : null;
    return ListTile(
      leading: imageUrl != null
          ? CircleAvatar(backgroundImage: NetworkImage(imageUrl))
          : const CircleAvatar(child: Icon(Icons.person)),
      title: Text(artist.name ?? ''),
      onTap: () {
        //  Sanatçı detay sayfasına gitme mantığı

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ArtistDetailPage(artistId: artist.id!),
          ),
        );
        print("Sanatçıya tıklandı: ${artist.name}");
      },
    );
  }

  // PLAYLIST SONUCU İÇİN LISTTILE
  Widget _buildPlaylistTile(BuildContext context, PlaylistSimple playlist) {
    final imageUrl = playlist.images?.isNotEmpty ?? false
        ? playlist.images!.first.url
        : null;
    return ListTile(
      leading: imageUrl != null
          ? flt.Image.network(imageUrl,
              width: 50, height: 50, fit: BoxFit.cover)
          : const Icon(Icons.playlist_play, size: 50),
      title: Text(playlist.name ?? ''),
      subtitle: Text(playlist.description ?? '', maxLines: 1),
      onTap: () {
        //  Playlist detay sayfasına gitme mantığı

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlaylistDetailPage(playlistId: playlist.id!),
          ),
        );
        print("Playlist'e tıklandı: ${playlist.name}");
      },
    );
  }
}
