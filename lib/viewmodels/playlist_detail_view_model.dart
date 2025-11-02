// viewmodels/playlist_detail_view_model.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:musicapp/services/new_database.dart';
import 'package:musicapp/services/auth.dart';
import 'package:musicapp/data/Models.dart' as mymodel;

class PlaylistDetailViewModel extends ChangeNotifier {
  final Database _databaseService;
  final UserControl _userControl;
  final String playlistId; // Hangi playlistin detayını göstereceğimizi belirtir

  Stream<List<mymodel.Song>>? _songsStream;

  PlaylistDetailViewModel(
      this._databaseService, this._userControl, this.playlistId) {
    _loadSongs();
  }

  Stream<List<mymodel.Song>>? get songsStream => _songsStream;

  void _loadSongs() {
    final userId = _userControl.getUSerId();
    if (userId != null) {
      // Database servisindeki şarkı stream'ini al
      _songsStream = _databaseService
          .getSongsStreamForPlaylist(playlistId)
          .map((snapshot) {
        // Gelen QuerySnapshot'ı List<mymodel.Song>'a çevir
        return snapshot.docs
            .map((doc) {
              try {
                return mymodel.Song.fromMap(doc.data());
              } catch (e) {
                print(
                    "Playlist şarkı parse hatası: doc.id=${doc.id}, Hata: $e");
                return null;
              }
            })
            .whereType<mymodel.Song>()
            .toList();
      });
    } else {
      _songsStream = Stream.value([]);
    }
  }

  /// Belirtilen şarkıyı playlist'ten siler.
  Future<void> removeSongFromPlaylist(String songId) async {
    try {
      await _databaseService.deleteSongFromPlaylist(playlistId, songId);
      print("ViewModel: Şarkı silindi: $songId <- Playlist: $playlistId");
      // Stream otomatik güncelleyecektir.
    } catch (e) {
      print("ViewModel: Şarkı silinirken hata: $e");
    }
  }
}
