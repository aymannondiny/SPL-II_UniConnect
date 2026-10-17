import 'package:flutter/material.dart';

import '../../../../core/storage/secure_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SecureStorageService _storageService = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 1));

    final hasToken = await _storageService.hasToken();

    if (!mounted) return;

    if (hasToken) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/dashboard',
            (route) => false,
      );
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8F4FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_rounded,
              size: 80,
              color: Color(0xFF6D28D9),
            ),
            SizedBox(height: 18),
            Text(
              'UniConnect',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 22),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}