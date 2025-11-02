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
> NOT: `.github/media/` klasörüne demo.gif veya demo.mp4 videonu ekle.  
> Örnek:  
> ![Uygulama Demosu](.github/media/demo.gif)

### 🖼️ Ekran Görüntüleri

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

---

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

Bu projeyi yerel makinenizde çalıştırmak için:

### 1. Projeyi Klonla
```bash
git clone https://github.com/Nightbold/MusicApp.git
cd MusicApp
