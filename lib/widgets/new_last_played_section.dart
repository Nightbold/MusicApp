import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:musicapp/services/Spottify.dart';
import 'package:musicapp/services/auth.dart';
import 'package:musicapp/viewmodels/mini_player_view_model.dart';
import 'package:provider/provider.dart';
import 'package:spotify/spotify.dart';
import 'package:flutter/material.dart' as flutter;

class LastPlayedSection extends StatelessWidget {
  LastPlayedSection({super.key});

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final userControl = context.read<UserControl>();
    final spotify = context.read<Spottify>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
          child: Text("Son Çalınanlar",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 180,
          child: StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection("Users/${userControl.getUSerId()}/LastPlayed")
                .orderBy('playdate', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              // Yüklenme durumu
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Hata durumu
              if (snapshot.hasError) {
                return const Center(child: Text("Veriler alınamadı."));
              }
              // Veri yoksa veya boşsa
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text("Henüz bir şarkı dinlemediniz."));
              }

              final songDocs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: songDocs.length,
                itemBuilder: (context, index) {
                  final data = songDocs[index].data() as Map<String, dynamic>;
                  final songName =
                      data['songName'] as String? ?? 'Bilinmeyen Şarkı';
                  final songImageUrl = data['songImage'] as String?;
                  final songId = data['songId'] as String?;

                  return GestureDetector(
                    onTap: () async {
                      if (songId == null) return;

                      final Track track = await spotify.bul(songId);
                      final miniPlayer = context.read<MiniPlayerViewModel>();

                      miniPlayer.reset();
                      miniPlayer.playTrack(track);
                    },
                    child: Container(
                      width: 130,
                      margin: const EdgeInsets.only(right: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: SizedBox(
                              height: 130,
                              width: 130,
                              child: songImageUrl != null &&
                                      songImageUrl.isNotEmpty
                                  ? flutter.Image.network(
                                      songImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.music_note),
                                    )
                                  : Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(Icons.music_note,
                                          color: Colors.white),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            songName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
