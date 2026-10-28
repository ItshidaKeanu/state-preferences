import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  int _visitCount = 0;

  User get user => _user;
  bool get isLoading => _isLoading;
  int get visitCount => _visitCount;

  UserProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _loadUser(),
      _loadVisitCount(),
    ]);
  }

  // Memuat data profil.
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();

    _user = User(
      name: prefs.getString('user_name') ?? '',
      email: prefs.getString('user_email') ?? '',
      isLoggedIn: prefs.getBool('is_logged_in') ?? false,
    );

    _isLoading = false;
    notifyListeners();
  }

  // Memuat dan menambah counter kunjungan.
  Future<void> _loadVisitCount() async {
    final prefs = await SharedPreferences.getInstance();

    final currentCount = prefs.getInt('visit_count') ?? 0;
    final newCount = currentCount + 1;

    await prefs.setInt('visit_count', newCount);

    _visitCount = newCount;
    notifyListeners();
  }

  // Menyimpan perubahan profil.
  Future<void> updateUser(User newUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('user_name', newUser.name);
      await prefs.setString('user_email', newUser.email);
      await prefs.setBool('is_logged_in', newUser.isLoggedIn);

      _user = newUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout tanpa menghapus email yang tersimpan.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user_name');
    await prefs.setBool('is_logged_in', false);

    _user = _user.copyWith(
      name: '',
      isLoggedIn: false,
    );

    notifyListeners();
  }
}
