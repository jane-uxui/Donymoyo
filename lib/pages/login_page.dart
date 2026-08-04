import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'signup_page.dart';
import 'auth_google.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const bg = Color(0xFF333333);
  static const accent = Color(0xFFE6A4B4);

  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _loginEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _pwCtrl.text,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await signInWithGoogle();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Login",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                  color: accent,
                ),
              ),
              const SizedBox(height: 26),

              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('이메일', style: TextStyle(fontFamily: 'Noto Sans', fontSize: 12, color: Colors.white)),
              ),
              _NeoField(controller: _emailCtrl, hint: 'example@gmail.com', keyboardType: TextInputType.emailAddress),

              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('비밀번호', style: TextStyle(fontFamily: 'Noto Sans', fontSize: 12, color: Colors.white)),
              ),
              _NeoField(controller: _pwCtrl, hint: '비밀번호', obscureText: true),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : () {},
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      color: Colors.white,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(fontFamily: 'Noto Sans', color: accent)),
              ],

              const SizedBox(height: 40),

              _BigButton(
                text: '로그인',
                filled: true,
                loading: _loading,
                onTap: _loginEmail,
              ),

              const SizedBox(height: 16),

              

              _BigButton(
                text: 'Google로 로그인',
                filled: false,
                loading: _loading,
                onTap: _loginGoogle,
              ),

              const SizedBox(height: 70),
              Center(
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SignupPage()),
                          ),
                  child: const Text(
                    '회원가입 하기',
                    style: TextStyle(fontFamily: 'Noto Sans', color: Colors.white,fontSize: 11,
                      decoration: TextDecoration.underline,),
                  ),
                ),
              ),

              
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    '나중에 하기',
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 11,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeoField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _NeoField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  static const pill = Color(0xFF2F2F2F);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 49,
      decoration: BoxDecoration(
        color: pill,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(-6, -6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.9),
            blurRadius: 18,
            offset: const Offset(6, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontFamily: 'Noto Sans', color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 16, fontFamily: 'Noto Sans'),
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String text;
  final bool filled;
  final bool loading;
  final VoidCallback onTap;

  const _BigButton({
    required this.text,
    required this.filled,
    required this.loading,
    required this.onTap,
  });

  static const accent = Color(0xFFE6A4B4);

  @override
  Widget build(BuildContext context) {
    final Color bg = filled ? accent : Colors.black;
    final Color fg = filled ? const Color(0xFF333333) : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 49,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(-6, -6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.9),
              blurRadius: 18,
              offset: const Offset(6, 6),
            ),
          ],
        ),
        child: TextButton(
          onPressed: loading ? null : onTap,
          child: loading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: fg,
                  ),
                ),
        ),
      ),
    );
  }
}