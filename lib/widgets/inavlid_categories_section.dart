// import 'package:flutter/material.dart';
// import 'package:musicapp/services/Spottify.dart';
// import 'package:musicapp/utilities/Helpers.dart';
// import 'package:musicapp/viewmodels/home_view_model.dart';
// // import '../../temp/categorie_page.dart';

// import 'package:provider/provider.dart';
// import 'package:spotify/spotify.dart';

// class CategoriesSection extends StatelessWidget {
//   const CategoriesSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // ViewModel'dan kategori listesini dinle
//     final List<Category> categories = context.watch<HomeViewModel>().categories;
//     // YENİ YÖNTEM: Provider'dan mevcut Spottify nesnesini oku.
//     final spotify = context.read<Spottify>();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Padding(
//           padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
//           child: Text("Kategoriler",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//         ),
//         SizedBox(
//           height: 100, // Grid'de 2 satır olacağı için yüksekliği ayarladım
//           child: GridView.builder(
//             padding: const EdgeInsets.symmetric(horizontal: 12),
//             scrollDirection: Axis.horizontal,
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 2, // 2 satır
//               mainAxisSpacing: 8,
//               crossAxisSpacing: 8,
//               childAspectRatio: 0.45, // Kartların en/boy oranı
//             ),
//             itemCount: categories.length,
//             itemBuilder: (context, index) {
//               final category = categories[index];
//               final color = Helper.generateDarkColor();

//               return GestureDetector(
//                 onTap: () async {
//                   final playlists =
//                       await spotify.getPlaylistsByCategory(category.id!);
//                   // if (context.mounted) {
//                   //   Navigator.push(
//                   //     context,
//                   //     MaterialPageRoute(
//                   //       builder: (context) =>
//                   //           Categoriepage(playlists: playlists),
//                   //     ),
//                   //   );
//                   // }
//                 },
//                 child: Card(
//                   color: color,
//                   child: Center(
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 8.0),
//                       child: Text(
//                         category.name ?? "İsimsiz",
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
