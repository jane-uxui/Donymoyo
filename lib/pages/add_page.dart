import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class AddPage extends StatefulWidget {
  final DateTime selectedDate;

  final String? editExpenseId;
  final int? initialAmount;
  final String? initialCategory;
  final String? initialMemo;

  const AddPage({
    super.key,
    required this.selectedDate,
    this.editExpenseId,
    this.initialAmount,
    this.initialCategory,
    this.initialMemo,
  });

  bool get isEdit => editExpenseId != null;

  @override
  State<AddPage> createState() => _AddPageState();
}


class _AddPageState extends State<AddPage> {
  final PageController _pageController = PageController();
  final _expenseService = ExpenseService();
  bool _loading = false;

  String _amount = '0'; // 숫자만 저장
  final TextEditingController _memoCtrl = TextEditingController();
  String? _selectedCategory;

  // 디자인 카테고리
  final List<_Cat> _cats = const [
    _Cat('식비', Color(0xFFF2C9D6), Color(0xFF6A1E3B)),
    _Cat('배달', Color(0xFFF2E1CF), Color(0xFF7A3D00)),
    _Cat('생필품', Color(0xFFE1D6F2), Color(0xFF3F2A73)),
    _Cat('교통비', Color(0xFFD2E2F2), Color(0xFF1D4C6A)),
    _Cat('의료', Color(0xFFD8E8C3), Color(0xFF2E4D18)),
    _Cat('문화', Color(0xFFF2D2D2), Color(0xFF6A1D1D)),
    _Cat('경조사', Color(0xFFE2C2D8), Color(0xFF5A2146)),
    _Cat('쇼핑', Color(0xFFEFEBC3), Color(0xFF6B6311)),
    _Cat('기타', Color(0xFFCACACA), Color(0xFF2B2B2B)),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  // ---- helpers
  String _formatAmount(String raw) {
    final n = int.tryParse(raw) ?? 0;
    return NumberFormat('#,###').format(n);
  }

  void _onKeypadTapped(String value) {
    setState(() {
      if (value == '←') {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
        return;
      }

      if (value == '00') {
        if (_amount == '0') return;
        _amount += '00';
        return;
      }

      // 0~9
      if (_amount == '0') {
        _amount = value;
      } else {
        _amount += value;
      }

      // 너무 길면 컷(선택)
      if (_amount.length > 12) {
        _amount = _amount.substring(0, 12);
      }
    });
  }

  String _today() => DateFormat('MM.dd').format(widget.selectedDate);

  // ===== UI Tokens (메인 앱과 통일) =====
  static const Color bg = Color(0xFF333333);
  static const Color pill = Color(0xFF2F2F2F);
  static const Color secondary = Color(0xFF999999);

  static const List<BoxShadow> neoShadow = [
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
  ];

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _AmountPage(
          bg: bg,
          pill: pill,
          secondary: secondary,
          neoShadow: neoShadow,
          dateText: _today(),
          amountText: _formatAmount(_amount),
          onBack: () => Navigator.of(context).pop(),
          onClose: () => Navigator.of(context).pop(),
          onKey: _onKeypadTapped,
          onNext: () => _pageController.nextPage(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          ),
        ),
        _DetailPage(
          bg: bg,
          pill: pill,
          secondary: secondary,
          neoShadow: neoShadow,
          dateText: _today(),
          amountText: _formatAmount(_amount),
          memoCtrl: _memoCtrl,
          cats: _cats,
          selected: _selectedCategory,
          onSelect: (v) => setState(() => _selectedCategory = v),
          onBack: () => _pageController.previousPage(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          ),
          onClose: () => Navigator.of(context).pop(),
          onDone: _loading ? null : _save,
        ),
      ],
    );
  }
  Future<void> _save() async {
    final cat = _selectedCategory;
    final amount = int.tryParse(_amount) ?? 0;
    final memo = _memoCtrl.text.trim();

    if (cat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리를 선택해줘')),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금액을 입력해줘')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    setState(() => _loading = true);
    try {
      if (widget.isEdit) {
        // ✅ 수정
        await _expenseService.updateExpense(
          widget.editExpenseId!,
          date: widget.selectedDate,
          amount: amount,
          category: cat,
          memo: memo,
        );
      } else {
        // ✅ 추가
        await _expenseService.addExpense(
          date: widget.selectedDate,
          amount: amount,
          category: cat,
          memo: memo,
        );
      }

      if (!mounted) return;
      nav.pop(true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  void initState() {
    super.initState();

    if (widget.isEdit) {
      _amount = (widget.initialAmount ?? 0).toString();
      _selectedCategory = widget.initialCategory;
      _memoCtrl.text = widget.initialMemo ?? '';
    }
  }
}

// ======================
// Page 1: amount input
// ======================
class _AmountPage extends StatelessWidget {
  final Color bg;
  final Color pill;
  final Color secondary;
  final List<BoxShadow> neoShadow;

  final String dateText;
  final String amountText;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final void Function(String) onKey;
  final VoidCallback onNext;

  const _AmountPage({
    required this.bg,
    required this.pill,
    required this.secondary,
    required this.neoShadow,
    required this.dateText,
    required this.amountText,
    required this.onBack,
    required this.onClose,
    required this.onKey,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 34),
          onPressed: onBack,
        ),
        title: Text(
          dateText,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF999999),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 34),
            onPressed: onClose,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 40),

            // big amount
            Expanded(
              child: Center(
                child: Text(
                  amountText,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
            ),

            // keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _KeypadOverlay(onTap: onKey),
            ),

            const SizedBox(height: 22),

            // next button (pill)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: pill,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: neoShadow,
                  ),
                  child: TextButton(
                    onPressed: onNext,
                    child: const Text(
                      '다음',
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
          ],
        ),
      ),
    );
  }
}

// ======================
// Page 2: memo + categories
// ======================
class _DetailPage extends StatelessWidget {
  final Color bg;
  final Color pill;
  final Color secondary;
  final List<BoxShadow> neoShadow;

  final String dateText;
  final String amountText;

  final TextEditingController memoCtrl;
  final List<_Cat> cats;
  final String? selected;
  final ValueChanged<String> onSelect;

  final VoidCallback onBack;
  final VoidCallback onClose;
  final VoidCallback? onDone;

  const _DetailPage({
    required this.bg,
    required this.pill,
    required this.secondary,
    required this.neoShadow,
    required this.dateText,
    required this.amountText,
    required this.memoCtrl,
    required this.cats,
    required this.selected,
    required this.onSelect,
    required this.onBack,
    required this.onClose,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 34),
          onPressed: onBack,
        ),
        title: Text(
          dateText,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF999999),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 34),
            onPressed: onClose,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 6),

              Text(
                amountText,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.0,
                ),
              ),

              const SizedBox(height: 24),

              // memo pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: pill,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: neoShadow,
                ),
                child: TextField(
                  controller: memoCtrl,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Memo',
                    hintStyle: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 34),

              // categories (3 columns)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cats.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 22,
                  crossAxisSpacing: 22,
                  childAspectRatio: 2.3,
                ),
                itemBuilder: (context, i) {
                  final c = cats[i];
                  final isSel = selected == c.label;
                  return GestureDetector(
                    onTap: () => onSelect(c.label),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      transform: isSel
                          ? (Matrix4.identity()..translate(0, -4)..scale(1.08))
                          : Matrix4.identity(),
                      decoration: BoxDecoration(
                        color: c.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: isSel
                            ? Border.all(
                                color: Colors.white,
                                width: 2.5,
                              )
                            : Border.all(
                                color: Colors.transparent,
                                width: 2,
                              ),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                )
                              ]
                            : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        c.label,
                        style: TextStyle(
                          fontFamily: 'NotoSansKR',
                          fontSize: isSel ? 22 : 20, // ⭐ 선택 시 글자도 살짝 커짐
                          fontWeight: FontWeight.w800,
                          color: c.fg,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    color: pill,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: neoShadow,
                  ),
                  child: TextButton(
                    onPressed: onDone,
                    child: const Text(
                      '저장',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
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

// ======================
// Keypad (design-like)
// ======================
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

    Widget cell(String k) {
      final isBack = k == '←';
      return Expanded(
        child: Center(
          child: TextButton(
            onPressed: () => onTap(k),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 28),
              foregroundColor: Colors.white,
            ),
            child: isBack
                ? const Icon(Icons.backspace, color: Colors.white, size: 28)
                : Text(
                    k,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ),
                  ),
          ),
        ),
      );
    }

    return Column(
      children: keys
          .map(
            (row) => Row(
              children: row.map(cell).toList(),
            ),
          )
          .toList(),
    );
  }
}

// category model
class _Cat {
  final String label;
  final Color bg;
  final Color fg;
  const _Cat(this.label, this.bg, this.fg);
}