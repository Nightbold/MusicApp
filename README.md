# 🎵 MusicApp (Müzik Uygulaması)

Flutter ile geliştirilmiş, **Spotify** ve **Firebase** destekli, zengin özelliklere sahip bir müzik çalma uygulaması.  
Bu proje, **Spotify Web API**’sini kullanarak müzik verilerini (albümler, sanatçılar, arama sonuçları) çeker ve ses akışını **YouTube** üzerinden (`youtube_explode_dart`) sağlar.  

Kullanıcılar:
- Kendi çalma listelerini oluşturabilir,
- Şarkıları favorilerine ekleyebilir,
- Dinleme geçmişlerini kaydedebilir.  

Tüm kullanıcı verileri **Firebase Firestore** üzerinde saklanır.

---

## 📱 Demo ve Ekran Görüntüleri

### 🎬 Çalışma Videosu (Demo)


<p align="center">
  <b>Ana Sayfa & Oynatıcı</b><br>
  <img src=".github/media/Home.gif?raw=true" width="250" alt="Ana Sayfa ve Oynatıcı Demosu">
  <img src=".github/media/player.gif?raw=true" width="250" alt="Oynatıcı ">
</p>
<p align="center">
  <b>Arama & Kitaplık</b><br>
  <img src=".github/media/search.gif?raw=true" width="250" alt="Arama ">
  <img src=".github/media/search2.gif?raw=true" width="250" alt="Kitaplık">
</p>


---



**Giriş / Kayıt – Anasayfa – Arama**
<p float="left">
  <img src=".github/media/SignInPage.png?raw=true" width="200" alt="Giriş Ekranı">
  <img src=".github/media/HomePage.png?raw=true" width="200" alt="Anasayfa">
  <img src=".github/media/SearchPage.png?raw=true" width="200" alt="Arama Sayfası">
</p>

**Kitaplık – Tam Ekran Oynatıcı**
<p float="left">
  <img src=".github/media/LibraryPage.png?raw=true" width="200" alt="Kitaplık">
  <img src=".github/media/PlayerPage.png?raw=true" width="200" alt="Tam Ekran Oynatıcı">
</p>

## ✨ Özellikler

### 🔐 Firebase Authentication
- E-posta/şifre ile kullanıcı girişi ve kaydı.

### 🎧 Spotify Veri Entegrasyonu
- Yeni çıkanlar ve kategoriler.
- Şarkı, sanatçı ve çalma listesi arama.
- Sanatçı detayları ve popüler şarkılar.
- Çalma listesi detayları ve şarkılar.

### 🎵 Müzik Çalma (YouTube)
- `just_audio` ile arka planda ses çalma.
- `youtube_explode_dart` ile şarkı adına göre YouTube'dan ses akış linki bulma.

### 📱 Oynatıcı
- **Kalıcı Mini Oynatıcı:** Sekmeler arası kaybolmayan mini oynatıcı.
- **Tam Ekran Oynatıcı:** Mini oynatıcıya tıklandığında açılan, bulanıklaştırılmış arka planlı tam ekran arayüz.

### 💾 Kullanıcı Kitaplığı (Firestore)
- **Favori Şarkılar:** Beğenme ve favorilere ekleme/çıkarma.  
- **Çalma Listeleri:** Oluşturma, silme, şarkı ekleme ve çıkarma.

### 🧠 Verimli Mimari
- **MVVM + Provider:** Temiz, yönetilebilir ve test edilebilir mimari.
- **Nested Navigators:** Kalıcı `BottomNavigationBar`.
- **Performans:** Isolate + Hive ile URL önbellekleme.

---

## 🚀 Kullanılan Teknolojiler

| Kategori | Teknoloji |
|-----------|------------|
| Framework | Flutter |
| State Management | Provider |
| Backend & Database | Firebase (Auth + Firestore) |
| API | Spotify Web API (`spotify` paketi) |
| Ses Akışı | `youtube_explode_dart`, `just_audio` |
| Önbellek | `hive_flutter` |
| Navigasyon | Nested Navigators |

---

## 🛠️ Kurulum (Development)

Bu projeyi yerel makinenizde çalıştırmak için aşağıdaki adımları izleyin:

1. **Projeyi Klonla**
   ```bash
   git clone https://github.com/Nightbold/MusicApp.git
   cd MusicApp
2. **Gerekli Paketleri Yükle**
   ```bash
   flutter pub get
3. **Firebase Ayarlarını Yapılandır**

    - Firebase'den indirdiğiniz google-services.json dosyasını android/app/ klasörüne kopyalayın.
    Bu dosyaları kendi Firebase projenizden indirebilirsiniz.
4. **Spotify API Anahtarları**
    
    - lib/ klasörü içinde Strings.dart adında yeni bir dosya oluşturun.
    - Aşağıdaki kodu bu dosyanın içine yapıştırın ve kendi Spotify API anahtarlarınızla doldurun:
      ```dart
      // lib/Strings.dart

      class CustomStrings {
        static const String clientID = "BURAYA_SENİN_SPOTIFY_CLIENT_ID_YAZ";
        static const String cliensecret = "BURAYA_SENİN_SPOTIFY_CLIENT_SECRET_YAZ";
      }
      // (Bu dosya .gitignore tarafından korunmaktadır ve GitHub'a yüklenmez.)
    

4. **Uygulamayı Çalıştır**
   ```bash
   flutter run 
 Not: Uygulama çalışması için platforma özel yapılandırmalar, Firebase konfigürasyonu ve gerekli izinler gerekebilir.
  Terminalde çıkan hatalar genelde eksik dosya, anahtar veya izinle ilgilidir — oradan ilerleyin.



