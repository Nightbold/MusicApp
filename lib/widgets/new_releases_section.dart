import 'package:flutter/material.dart';
import 'package:musicapp/viewmodels/home_view_model.dart';
import 'package:musicapp/views/New_Albumpage.dart';

import 'package:provider/provider.dart';

class NewReleasesSection extends StatelessWidget {
  const NewReleasesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final newReleases = context.watch<HomeViewModel>().newReleases;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Yeni Çıkanlar",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 200,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: newReleases.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1 / 1,
            ),
            itemBuilder: (context, index) {
              final album = newReleases[index];
              final imageUrl = album.images?.first.url;

              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => AlbumPage(albumSimple: album)));
                  // Album sayfasına gitme logiği burada
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
