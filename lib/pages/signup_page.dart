import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import 'auth_google.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  static const bg = Color(0xFF333333);
  static const accent = Color(0xFFE6A4B4);
  static const secondary = Color(0xFF999999);

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();

  bool _agree = false;
  bool _loading = false;
  String? _error;

  Future<void> _signUpEmail() async {
  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    if (_nameCtrl.text.trim().isEmpty) throw Exception('이름을 입력해 주세요.');
    if (_emailCtrl.text.trim().isEmpty) throw Exception('이메일을 입력해 주세요.');
    if (_pwCtrl.text.isEmpty) throw Exception('비밀번호를 입력해 주세요.');
    if (_pwCtrl.text != _pw2Ctrl.text) throw Exception('비밀번호가 일치하지 않아요.');
    if (!_agree) throw Exception('약관에 동의해 주세요.');

    // 1️⃣ FirebaseAuth 계정 생성
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(
      email: _emailCtrl.text.trim(),
      password: _pwCtrl.text,
    );

    final user = credential.user;
    if (user == null) throw Exception('회원가입에 실패했습니다.');

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();

    // 2️⃣ displayName 저장
    await user.updateDisplayName(name);

    // 3️⃣ Firestore users/{uid} 저장
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    Navigator.of(context).pop(); // AuthGate가 자동 전환

  } catch (e) {
    if (!mounted) return;
    setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
  } finally {
    if (mounted) {
      setState(() => _loading = false);
    }
  }
  await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameCtrl.text.trim());
}

  Future<void> _signUpGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await signInWithGoogle(); // Google 로그인 성공 -> AuthGate가 메인으로
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
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
                "Let’s Start",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                  color: accent,
                ),
              ),
              const SizedBox(height: 26),

              const _Label('이름'),
              _NeoField(controller: _nameCtrl, hint: '앱에서 사용할 닉네임을 입력해주세요'),
              const SizedBox(height: 26),

              const _Label('이메일'),
              _NeoField(controller: _emailCtrl, hint: 'example@gmail.com', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 26),

              const _Label('비밀번호'),
              _NeoField(controller: _pwCtrl, hint: '비밀번호', obscureText: true),
              const SizedBox(height: 16),

              _NeoField(controller: _pw2Ctrl, hint: '비밀번호 확인', obscureText: true),

              const SizedBox(height: 26),
              Row(
                children: [
                  Checkbox(
                    value: _agree,
                    onChanged: _loading ? null : (v) => setState(() => _agree = v ?? false),
                    side: const BorderSide(color: secondary),
                    activeColor: accent,
                  ),
                  const Text(
                    'Agree with ',
                    style: TextStyle(fontFamily: 'Noto Sans', color: secondary),
                  ),
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(fontFamily: 'Noto Sans', color: accent),
                ),
              ],

              const SizedBox(height: 18),

              _BigButton(
                text: '회원가입',
                filled: true,
                loading: _loading,
                onTap: _signUpEmail,
              ),

              const SizedBox(height: 44),

              _BigButton(
                text: 'Email로 로그인',
                filled: false,
                loading: false,
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
              ),

              const SizedBox(height: 12),

              _BigButton(
                text: 'Google로 로그인',
                filled: false,
                loading: _loading,
                onTap: _signUpGoogle,
              ),

              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    '나중에하기',
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      color: Color.fromARGB(125, 255, 255, 255),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Noto Sans',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Colors.white,
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
        style: const TextStyle(fontFamily: 'Noto Sans', color: Colors.white, fontSize: 12),
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
    final Color bg = filled ? accent : Colors.white;
    final Color fg = filled ? const Color(0xFF333333) : const Color(0xFF333333);

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