import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  static const bg = Color(0xFF333333);
  static const accent = Color(0xFFE6A4B4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Column(
                children: const [
                  Text(
                    'Dony moyo',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      color: accent,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '오늘 쓴 돈을 꾸준히 기록해봐요',
                    style: TextStyle(
                      fontFamily: 'Noto Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 4),

              _NeoButton(
                text: '시작하기',
                filled: true,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SignupPage()),
                ),
              ),
              const SizedBox(height: 14),
              _NeoButton(
                text: '로그인',
                filled: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeoButton extends StatelessWidget {
  final String text;
  final bool filled;
  final VoidCallback onTap;

  const _NeoButton({
    required this.text,
    required this.filled,
    required this.onTap,
  });

  static const accent = Color(0xFFE6A4B4);

  @override
  Widget build(BuildContext context) {
    final Color surface = filled ? accent : Colors.black;
    final Color textColor = filled ? const Color(0xFF333333) : Colors.white;

    return SizedBox(
      width: double.infinity,
      height: 49,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
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
          onPressed: onTap,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}