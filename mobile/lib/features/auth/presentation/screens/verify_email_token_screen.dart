import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/verify_email_provider.dart';

class VerifyEmailTokenScreen extends StatefulWidget {
  final String token;

  const VerifyEmailTokenScreen({
    super.key,
    required this.token,
  });

  @override
  State<VerifyEmailTokenScreen> createState() => _VerifyEmailTokenScreenState();
}

class _VerifyEmailTokenScreenState extends State<VerifyEmailTokenScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VerifyEmailProvider>().verifyEmail(widget.token);
    });
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VerifyEmailProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (provider.isLoading) ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 24),
                        const Text(
                          'Verifying your email...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ] else if (provider.isSuccess) ...[
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 72,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Email verified successfully',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          provider.successMessage ??
                              'Your account is now active. You can login.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _goToLogin,
                            child: const Text('Go to Login'),
                          ),
                        ),
                      ] else ...[
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 72,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Verification failed',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          provider.errorMessage ??
                              'Invalid or expired verification token.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _goToLogin,
                            child: const Text('Back to Login'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}