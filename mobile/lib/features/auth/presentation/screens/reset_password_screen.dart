import 'package:flutter/material.dart';

import '../../../../data/services/auth_api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  final AuthApiService _authApiService = AuthApiService();

  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _pageMessage;
  bool _isErrorMessage = true;

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showPageError(String message) {
    setState(() {
      _pageMessage = message;
      _isErrorMessage = true;
    });
  }

  void _showPageSuccess(String message) {
    setState(() {
      _pageMessage = message;
      _isErrorMessage = false;
    });
  }

  Future<void> _resetPassword() async {
    setState(() {
      _pageMessage = null;
    });

    final password = _newPasswordController.text.trim();

    if (password.length < 8) {
      _showPageError(
        'Your new password is too short. Password must be at least 8 characters. Example: Password123',
      );
      _formKey.currentState?.validate();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _showPageError('Please fix the highlighted fields and try again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final message = await _authApiService.resetPassword(
        token: _tokenController.text.trim(),
        newPassword: password,
      );

      if (!mounted) return;

      _showPageSuccess(message);

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
      });
    } catch (e) {
      if (!mounted) return;

      _showPageError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateToken(String? value) {
    final token = value?.trim() ?? '';

    if (token.isEmpty) {
      return 'Reset token is required';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';

    if (password.isEmpty) {
      return 'New password is required';
    }

    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final confirmPassword = value?.trim() ?? '';
    final newPassword = _newPasswordController.text.trim();

    if (confirmPassword.isEmpty) {
      return 'Confirm password is required';
    }

    if (confirmPassword != newPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  void _goBackToLogin() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  Widget _buildPageMessage() {
    if (_pageMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _isErrorMessage
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isErrorMessage
              ? const Color(0xFFE53935)
              : const Color(0xFF43A047),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isErrorMessage ? Icons.error_outline : Icons.check_circle_outline,
            color: _isErrorMessage
                ? const Color(0xFFE53935)
                : const Color(0xFF43A047),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _pageMessage!,
              style: TextStyle(
                color: _isErrorMessage
                    ? const Color(0xFFC62828)
                    : const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FA),
      appBar: AppBar(
        title: const Text('Reset Password'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : _goBackToLogin,
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(
                  Icons.password_rounded,
                  size: 72,
                  color: Color(0xFF6D28D9),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Create New Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Enter the reset token from your email and set a new password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 28),

                _buildPageMessage(),

                TextFormField(
                  controller: _tokenController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Reset Token',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  validator: _validateToken,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    helperText: 'Minimum 8 characters. Example: Password123',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                      icon: Icon(
                        _obscureNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        setState(() {
                          _obscureConfirmPassword =
                          !_obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  validator: _validateConfirmPassword,
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Reset Password'),
                  ),
                ),

                const SizedBox(height: 18),

                TextButton(
                  onPressed: _isLoading ? null : _goBackToLogin,
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}