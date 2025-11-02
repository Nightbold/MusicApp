import 'package:flutter/material.dart';
import 'package:musicapp/viewmodels/home_view_model.dart';

import 'package:musicapp/views/Settings.dart';

import 'package:musicapp/widgets/new_last_played_section.dart';
import 'package:musicapp/widgets/new_releases_section.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeViewModel(),
      child: Scaffold(
        body: SafeArea(
          child: Consumer<HomeViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.state == ViewState.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (viewModel.state == ViewState.error) {
                return const Center(child: Text("Bir hata oluştu."));
              }
              // Veri başarıyla geldiyse
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(), // Başlık ve ayarlar butonu
                    NewReleasesSection(), // Yeni çıkanlar bölümü

                    LastPlayedSection(), // Son çalınanlar bölümü
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Sayfa başlığını ve ayarlar butonunu içeren özel bir widget
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Anasayfa", // Daha genel bir başlık
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (builder) => const settings()),
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}
