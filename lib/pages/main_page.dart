import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const double _defaultLimit = 3312000;

  void _showSetLimitOverlay(double currentLimit) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'limit',
      barrierDismissible: true,
      barrierColor: const Color(0xFF333333).withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) {
        return _LimitSettingOverlay(
          currentLimit: currentLimit,
          onLimitSet: (newLimit) async {
            await _saveSpendingLimit(newLimit);
          },
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return FadeTransition(opacity: curve, child: child);
      },
    );
  }

  Future<void> _saveSpendingLimit(double newLimit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'spendingLimit': newLimit,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<double> _spendingLimitStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(_defaultLimit);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return _defaultLimit;

      final data = doc.data();
      final limit = data?['spendingLimit'];

      if (limit is int) return limit.toDouble();
      if (limit is double) return limit;

      return _defaultLimit;
    });
  }

  Stream<double> _monthlyTotalSpentStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('date', isLessThan: Timestamp.fromDate(nextMonthStart))
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final amount = data['amount'];

        if (amount is int) {
          total += amount.toDouble();
        } else if (amount is double) {
          total += amount;
        }
      }
      return total;
    });
  }

  String _fmt(num v) => NumberFormat('#,###').format(v);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scale = size.width / 393.0;
    final safeTop = MediaQuery.of(context).padding.top;

    final month = DateFormat('M월').format(DateTime.now());

    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim();
    final title = (name != null && name.isNotEmpty) ? '$name의 $month' : '귀요미의 $month';

    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: StreamBuilder<double>(
        stream: _spendingLimitStream(),
        builder: (context, limitSnapshot) {
          final spendingLimit = limitSnapshot.data ?? _defaultLimit;

          return StreamBuilder<double>(
            stream: _monthlyTotalSpentStream(),
            builder: (context, spentSnapshot) {
              final totalSpent = spentSnapshot.data ?? 0;
              final remainingAmount = spendingLimit - totalSpent;
              final ratio = (spendingLimit <= 0)
                  ? 0.0
                  : (totalSpent / spendingLimit).clamp(0.0, 1.0);

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height: mathMax(size.height, 852 * scale),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 39 * scale,
                        top: (100 * scale) + safeTop * 0.0,
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Noto Sans',
                            fontSize: 24 * scale,
                            height: (33 / 24),
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      Positioned(
                        left: (393 / 2 - 280 / 2) * scale,
                        top: 179 * scale,
                        child: Container(
                          width: 280 * scale,
                          height: 280 * scale,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 5 * scale,
                                spreadRadius: 1 * scale,
                                offset: Offset(5 * scale, 5 * scale),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.03),
                                blurRadius: 18 * scale,
                                offset: Offset(-6 * scale, -6 * scale),
                              ),
                            ],
                          ),
                          child: _Donut(
                            size: 280 * scale,
                            thickness: 50 * scale,
                            value: ratio,
                            trackColor: const Color(0xFF444444),
                            valueColor: const Color(0xFFE6A4B4),
                            centerChild: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(ratio * 100).round()}%',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 34 * scale,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFE6A4B4),
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 40 * scale,
                        top: 510 * scale,
                        child: _NeoCard(
                          width: 312 * scale,
                          height: 99 * scale,
                          radius: 8 * scale,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(left: 15 * scale, right: 15 * scale),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '남은 금액',
                                    style: TextStyle(
                                      fontFamily: 'Noto Sans',
                                      fontSize: 12 * scale,
                                      height: (16 / 12),
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF999999),
                                    ),
                                  ),
                                  SizedBox(height: 3 * scale),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      _fmt(remainingAmount.round()),
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 36 * scale,
                                        height: (42 / 36),
                                        fontWeight: FontWeight.w700,
                                        color: remainingAmount < 0
                                            ? const Color(0xFFE6A4B4)
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 40 * scale,
                        top: 631 * scale,
                        child: _NeoCard(
                          width: 148 * scale,
                          height: 92 * scale,
                          radius: 8 * scale,
                          child: Padding(
                            padding: EdgeInsets.only(left: 14 * scale, top: 17 * scale),
                            child: SizedBox(
                              width: 120 * scale,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '지출',
                                    style: TextStyle(
                                      fontFamily: 'Noto Sans',
                                      fontSize: 12 * scale,
                                      height: (16 / 12),
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF999999),
                                    ),
                                  ),
                                  SizedBox(height: 10 * scale),
                                  Text(
                                    _fmt(totalSpent.round()),
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 22 * scale,
                                      height: (26 / 22),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 204 * scale,
                        top: 631 * scale,
                        child: GestureDetector(
                          onTap: () => _showSetLimitOverlay(spendingLimit),
                          behavior: HitTestBehavior.opaque,
                          child: _NeoCard(
                            width: 148 * scale,
                            height: 92 * scale,
                            radius: 8 * scale,
                            child: Padding(
                              padding: EdgeInsets.only(left: 14 * scale, top: 17 * scale),
                              child: SizedBox(
                                width: 120 * scale,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '나의 한도',
                                          style: TextStyle(
                                            fontFamily: 'Noto Sans',
                                            fontSize: 12 * scale,
                                            height: (16 / 12),
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF999999),
                                          ),
                                        ),
                                        SizedBox(width: 5 * scale),
                                        Icon(
                                          Icons.edit,
                                          size: 14 * scale,
                                          color: const Color(0xFF999999),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10 * scale),
                                    Text(
                                      _fmt(spendingLimit.round()),
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 22 * scale,
                                        height: (26 / 22),
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: TextButton(
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                            },
                            child: const Text(
                              '로그아웃',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF999999),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NeoCard extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Widget child;

  const _NeoCard({
    required this.width,
    required this.height,
    required this.radius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(255, 255, 255, 0.05),
              blurRadius: 16,
              offset: Offset(-5, -5),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.90),
              blurRadius: 16,
              offset: Offset(5, 5),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _Donut extends StatelessWidget {
  final double size;
  final double thickness;
  final double value;
  final Color trackColor;
  final Color valueColor;
  final Widget centerChild;

  const _Donut({
    required this.size,
    required this.thickness,
    required this.value,
    required this.trackColor,
    required this.valueColor,
    required this.centerChild,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          value: value,
          thickness: thickness,
          trackColor: trackColor,
          valueColor: valueColor,
        ),
        child: Center(child: centerChild),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double value;
  final double thickness;
  final Color trackColor;
  final Color valueColor;

  _DonutPainter({
    required this.value,
    required this.thickness,
    required this.trackColor,
    required this.valueColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - (thickness / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = valueColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2,
      false,
      trackPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.thickness != thickness ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.valueColor != valueColor;
  }
}

class _LimitSettingOverlay extends StatefulWidget {
  final double currentLimit;
  final ValueChanged<double> onLimitSet;

  const _LimitSettingOverlay({
    required this.currentLimit,
    required this.onLimitSet,
  });

  @override
  State<_LimitSettingOverlay> createState() => __LimitSettingOverlayState();
}

class __LimitSettingOverlayState extends State<_LimitSettingOverlay> {
  static const Color pill = Color(0xFF2F2F2F);
  static const Color secondary = Color(0xFF999999);

  String _amount = '0';

  @override
  void initState() {
    super.initState();
    _amount = widget.currentLimit.toStringAsFixed(0);
  }

  void _onKey(String v) {
    setState(() {
      if (v == '←') {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
      } else if (v == '00' && _amount == '0') {
      } else if (_amount.length > 11) {
      } else if (_amount == '0' && v != '00') {
        _amount = v;
      } else {
        _amount += v;
      }
    });
  }

  String _formatAmount(String raw) {
    final n = double.tryParse(raw) ?? 0;
    final s = n.toStringAsFixed(0);
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _formatAmount(_amount);
    final hasValue = (double.tryParse(_amount) ?? 0) > 0;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final keypadHeight = (c.maxHeight * 0.42).clamp(260.0, 340.0);

            return Container(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Positioned(
                    top: 65,
                    right: 14,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 140, 30, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '나의 한도',
                          style: TextStyle(
                            fontFamily: 'NotoSansKR',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: pill,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(-5, -5),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.9),
                                blurRadius: 16,
                                offset: const Offset(5, 5),
                              ),
                            ],
                          ),
                          child: hasValue
                              ? Align(
                                  alignment: Alignment.centerRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$formatted원',
                                      style: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                )
                              : const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '이번달의 지출 한도를 정하세요',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: secondary,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: keypadHeight,
                          child: _KeypadOverlay(onTap: _onKey),
                        ),
                        const SizedBox(height: 60),
                        SafeArea(
                          top: false,
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: pill,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    blurRadius: 16,
                                    offset: const Offset(-5, -5),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.9),
                                    blurRadius: 16,
                                    offset: const Offset(5, 5),
                                  ),
                                ],
                              ),
                              child: TextButton(
                                onPressed: () {
                                  final newLimit =
                                      double.tryParse(_amount) ?? widget.currentLimit;
                                  widget.onLimitSet(newLimit);
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  '등록',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _KeypadOverlay extends StatelessWidget {
  final void Function(String) onTap;
  const _KeypadOverlay({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['00', '0', '←'],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxHeight < 300;
        final fontSize = isSmall ? 24.0 : 28.0;
        final iconSize = isSmall ? 24.0 : 28.0;

        return Column(
          children: keys.map((row) {
            return Expanded(
              child: Row(
                children: row.map((k) {
                  final isBack = k == '←';

                  return Expanded(
                    child: SizedBox.expand(
                      child: TextButton(
                        onPressed: () => onTap(k),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero, // 핵심
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Center(
                          child: isBack
                              ? Icon(
                                  Icons.backspace,
                                  color: Colors.white,
                                  size: iconSize,
                                )
                              : Text(
                                  k,
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

double mathMax(double a, double b) => (a > b) ? a : b;