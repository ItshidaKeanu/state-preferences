import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  // State daftar favorit
  final TextEditingController _favoriteController =
      TextEditingController();
  List<String> _favorites = [];
  bool _isLoadingFavorites = true;
  bool _profileInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadFavorites();
  }

  // Memuat daftar favorit dari SharedPreferences
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];

    if (!mounted) return;

    setState(() {
      _favorites = favorites;
      _isLoadingFavorites = false;
    });
  }

  // Menambahkan item favorit
  Future<void> _addFavorite() async {
    final item = _favoriteController.text.trim();

    if (item.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item favorit tidak boleh kosong'),
        ),
      );
      return;
    }

    if (_favorites.contains(item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item favorit sudah ada'),
        ),
      );
      return;
    }

    final updatedFavorites = [..._favorites, item];
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList('favorites', updatedFavorites);

    if (!mounted) return;

    setState(() {
      _favorites = updatedFavorites;
      _favoriteController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorit berhasil ditambahkan'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Menghapus item favorit
  Future<void> _removeFavorite(String item) async {
    final updatedFavorites = List<String>.from(_favorites)
      ..remove(item);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', updatedFavorites);

    if (!mounted) return;

    setState(() {
      _favorites = updatedFavorites;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorit berhasil dihapus'),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Inisialisasi form sekali agar input tidak tertimpa
    // setiap kali UserProvider memberi notifikasi perubahan.
    if (!_profileInitialized) {
      final provider = context.read<UserProvider>();
      _nameController.text = provider.user.name;
      _emailController.text = provider.user.email;
      _profileInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _favoriteController.dispose();
    super.dispose();
  }

  // Menyimpan profil dengan validasi keamanan
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final provider = context.read<UserProvider>();

    // Menolak pola berbahaya pada nama, seperti tag script.
    final dangerousPattern = RegExp(
      r'<\s*/?\s*script\b|javascript:',
      caseSensitive: false,
    );

    if (dangerousPattern.hasMatch(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama mengandung pola yang tidak diizinkan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Simulasi pemeriksaan email menggunakan SharedPreferences.
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');

    if (!mounted) return;

    // Izinkan email profil saat ini; tolak email yang sudah tersimpan
    // apabila berbeda dari email milik profil aktif.
    if (savedEmail != null &&
        savedEmail.toLowerCase() == email.toLowerCase() &&
        email.toLowerCase() != provider.user.email.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email sudah digunakan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedUser = provider.user.copyWith(
      name: name,
      email: email,
      isLoggedIn: true,
    );

    await provider.updateUser(updatedUser);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil disimpan'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Logout
  void _logout() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              await context.read<UserProvider>().logout();

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (provider.user.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
              tooltip: 'Logout',
            ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }

                          final emailRegex =
                              RegExp(r'^[^@]+@[^@]+\.[^@]+');

                          if (!emailRegex.hasMatch(value.trim())) {
                            return 'Format email tidak valid';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Simpan Profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),

                      // Daftar Favorit
                      const SizedBox(height: 32),
                      const Text(
                        'Daftar Favorit',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _favoriteController,
                        decoration: const InputDecoration(
                          labelText: 'Nama hobi atau item favorit',
                          hintText: 'Contoh: Membaca, Bermain Game',
                          prefixIcon: Icon(Icons.favorite),
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (_) => _addFavorite(),
                      ),
                      const SizedBox(height: 12),

                      ElevatedButton.icon(
                        onPressed: _addFavorite,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Favorit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_isLoadingFavorites)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (_favorites.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Belum ada item favorit.'),
                          ),
                        )
                      else
                        ..._favorites.map(
                          (item) => Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                              ),
                              title: Text(item),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Hapus favorit',
                                onPressed: () => _removeFavorite(item),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Catatan Keamanan
                      Card(
                        color: Colors.amber[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info,
                                    color: Colors.amber[800],
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Catatan Keamanan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Data disimpan di SharedPreferences (plaintext). '
                                'Jangan simpan password atau data sensitif di sini. '
                                'Gunakan secure storage untuk data sensitif.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
