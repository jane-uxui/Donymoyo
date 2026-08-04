import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';


import 'add_page.dart';
import 'category_data.dart';

class CalendarPage extends StatefulWidget {
  final ValueChanged<DateTime>? onDaySelected;

  const CalendarPage({
    super.key,
    this.onDaySelected,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  final Color accent = const Color(0xFFE6A4B4);

  DateTime _focusedMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? _selectedDay;

  bool get showDayList => _selectedDay != null;

  static const double _panelMinHeight = 150;
  static const double _panelMaxHeight = 320;
  double _panelHeight = 260;

  late final AnimationController _panelSnapController;
  Animation<double>? _panelSnapAnimation;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _expenseRef {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('expenses');
  }

  DateTime get _monthStart =>
      DateTime(_focusedMonth.year, _focusedMonth.month, 1);

  DateTime get _nextMonthStart =>
      DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);

  DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _nextDayStart(DateTime d) => DateTime(d.year, d.month, d.day + 1);

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchMonth() {
    return _expenseRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(_monthStart))
        .where('date', isLessThan: Timestamp.fromDate(_nextMonthStart))
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchDay(DateTime day) {
    final start = _dayStart(day);
    final end = _nextDayStart(day);

    return _expenseRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots();
  }

  Future<void> _deleteExpense(String id) async {
    await _expenseRef.doc(id).delete();
  }

  Future<void> _editExpense(_ExpenseItem e) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPage(
          selectedDate: e.date,
          editExpenseId: e.id,
          initialAmount: e.amount,
          initialCategory: e.category,
          initialMemo: e.memo,
        ),
      ),
    );
  }

  _ExpenseItem _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return _ExpenseItem(
      id: doc.id,
      amount: ((d['amount'] ?? 0) as num).toInt(),
      category: (d['category'] ?? '') as String,
      memo: (d['memo'] ?? '') as String,
      date: (d['date'] as Timestamp).toDate(),
      createdAt:
          d['createdAt'] is Timestamp ? (d['createdAt'] as Timestamp).toDate() : null,
    );
  }

  void _goPrevMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
      _selectedDay = null;
      _panelHeight = 260;
    });
  }

  void _goNextMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
      _selectedDay = null;
      _panelHeight = 260;
    });
  }

  double get _panelProgress {
    final t = (_panelHeight - _panelMinHeight) / (_panelMaxHeight - _panelMinHeight);
    return t.clamp(0.0, 1.0);
  }

  void _animatePanelTo(double target) {
    _panelSnapController.stop();

    _panelSnapAnimation = Tween<double>(
      begin: _panelHeight,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _panelSnapController,
        curve: Curves.easeOutCubic,
      ),
    );

    _panelSnapController
      ..reset()
      ..forward();
  }

  void _onHandleDragStart(DragStartDetails details) {
    if (showDayList) return;
    _panelSnapController.stop();
  }

  void _onHandleDragUpdate(DragUpdateDetails details) {
    if (showDayList) return;

    setState(() {
      _panelHeight -= details.delta.dy;
      _panelHeight = _panelHeight.clamp(_panelMinHeight, _panelMaxHeight);
    });
  }

  void _onHandleDragEnd(DragEndDetails details) {
    if (showDayList) return;

    final velocity = details.primaryVelocity ?? 0;
    final middle = (_panelMinHeight + _panelMaxHeight) / 2;

    double target;
    if (velocity > 120) {
      target = _panelMinHeight;
    } else if (velocity < -120) {
      target = _panelMaxHeight;
    } else {
      target = _panelHeight < middle ? _panelMinHeight : _panelMaxHeight;
    }

    _animatePanelTo(target);
  }

  @override
  void initState() {
    super.initState();

    _panelSnapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _panelSnapController.addListener(() {
      if (_panelSnapAnimation != null) {
        setState(() {
          _panelHeight = _panelSnapAnimation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _panelSnapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = size.height < 760 ? 28.0 : 40.0;
    final calendarHeight = size.height < 760 ? 330.0 : 360.0;

    return Scaffold(
      backgroundColor: const Color(0xFF333333),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _watchMonth(),
          builder: (context, monthSnap) {
            if (monthSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (monthSnap.hasError) {
              return Center(
                child: Text(
                  '불러오기 실패: ${monthSnap.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final docs = monthSnap.data?.docs ?? const [];
            final monthExpenses = docs.map(_fromDoc).toList();

            final int monthTotal =
                monthExpenses.fold(0, (sum, e) => sum + e.amount);

            final Map<DateTime, int> byDay = {};
            for (final e in monthExpenses) {
              final key = DateTime(e.date.year, e.date.month, e.date.day);
              byDay[key] = (byDay[key] ?? 0) + e.amount;
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 0),
                      child: Column(
                        children: [
                          _CalendarHeader(
                            monthText: DateFormat('MMMM').format(_focusedMonth),
                            onPrev: _goPrevMonth,
                            onNext: _goNextMonth,
                            onTitleTap: () {
                              setState(() {
                                _selectedDay = null;
                                _panelHeight = 260;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          const _WeekHeader(),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: calendarHeight,
                            child: _MonthGrid(
                              focusedMonth: _focusedMonth,
                              selectedDay: _selectedDay,
                              dayTotals: byDay,
                              accent: accent,
                              onDaySelected: (d) {
                                setState(() {
                                  final tapped =
                                      DateTime(d.year, d.month, d.day);
                                  if (_selectedDay != null &&
                                      _dayStart(_selectedDay!) == tapped) {
                                    _selectedDay = null;
                                  } else {
                                    _selectedDay = tapped;
                                  }
                                });

                                widget.onDaySelected?.call(d);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  width: double.infinity,
                  height: _panelHeight,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F2F2F),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: showDayList
                      ? _DayDetailPanel(
                          day: _selectedDay!,
                          items: monthExpenses
                              .where((e) =>
                                  e.date.year == _selectedDay!.year &&
                                  e.date.month == _selectedDay!.month &&
                                  e.date.day == _selectedDay!.day)
                              .toList()
                            ..sort((a, b) {
                              final aTime = a.createdAt ?? a.date;
                              final bTime = b.createdAt ?? b.date;
                              return bTime.compareTo(aTime);
                            }),
                          accent: accent,
                          onEdit: _editExpense,
                          onDelete: (id) async {
                            await _deleteExpense(id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('삭제 완료')),
                              );
                            }
                          },
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                          child: _MonthCategoryPanel(
                            monthTotal: monthTotal,
                            items: monthExpenses,
                            progress: _panelProgress,
                            handle: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragStart: _onHandleDragStart,
                              onVerticalDragUpdate: _onHandleDragUpdate,
                              onVerticalDragEnd: _onHandleDragEnd,
                              child: Center(
                                child: Opacity(
                                  opacity: 0.6 + (_panelProgress * 0.4),
                                  child: Container(
                                    width: 36 + (_panelProgress * 10),
                                    height: 4,
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final String monthText;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTitleTap;

  const _CalendarHeader({
    required this.monthText,
    required this.onPrev,
    required this.onNext,
    required this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onTitleTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Text(
                monthText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.edit,
                color: Color(0xFF999999),
                size: 18,
              ),
            ],
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left, color: Colors.white),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right, color: Colors.white),
        ),
      ],
    );
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      children: labels
          .map(
            (e) => Expanded(
              child: Text(
                e,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final Map<DateTime, int> dayTotals;
  final Color accent;
  final ValueChanged<DateTime> onDaySelected;

  const _MonthGrid({
    required this.focusedMonth,
    required this.selectedDay,
    required this.dayTotals,
    required this.accent,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0);

    final leading = firstDayOfMonth.weekday % 7;
    final totalDays = lastDayOfMonth.day;
    final totalCells = ((leading + totalDays) / 7).ceil() * 7;
    final prevMonthLastDay = DateTime(focusedMonth.year, focusedMonth.month, 0).day;

    final List<DateTime> cells = List.generate(totalCells, (index) {
      final dayNumber = index - leading + 1;

      if (dayNumber < 1) {
        return DateTime(
          focusedMonth.year,
          focusedMonth.month - 1,
          prevMonthLastDay + dayNumber,
        );
      } else if (dayNumber > totalDays) {
        return DateTime(
          focusedMonth.year,
          focusedMonth.month + 1,
          dayNumber - totalDays,
        );
      } else {
        return DateTime(focusedMonth.year, focusedMonth.month, dayNumber);
      }
    });

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: cells.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 6,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (context, index) {
        final date = cells[index];
        final isCurrentMonth = date.month == focusedMonth.month;

        final isSelected = selectedDay != null &&
            date.year == selectedDay!.year &&
            date.month == selectedDay!.month &&
            date.day == selectedDay!.day;

        final now = DateTime.now();
        final isToday =
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;

        final total = dayTotals[DateTime(date.year, date.month, date.day)];
        final sumText = isCurrentMonth && total != null && total > 0
            ? NumberFormat('#,###').format(total)
            : null;

        return _DayCell(
          dayNumber: '${date.day}',
          sumText: sumText,
          active: isSelected,
          isToday: isToday,
          disabled: !isCurrentMonth,
          onTap: isCurrentMonth ? () => onDaySelected(date) : null,
          accent: accent,
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  final String dayNumber;
  final String? sumText;
  final bool active;
  final bool isToday;
  final bool disabled;
  final VoidCallback? onTap;
  final Color accent;

  const _DayCell({
    required this.dayNumber,
    required this.sumText,
    required this.active,
    required this.isToday,
    required this.disabled,
    required this.onTap,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 380;
    final numColor = disabled ? Colors.white.withValues(alpha: 0.35) : Colors.white;
    final double circle = isSmall ? 38 : 44;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: circle,
            height: circle,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              dayNumber,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: isSmall ? 15 : 16,
                fontWeight: FontWeight.w600,
                color: active
                  ? Colors.white
                  : isToday
                      ? const Color(0xFFFFB3B3)
                      : numColor,
                      // 오늘날짜 텍스트색으로 표시
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: isSmall ? 10 : 12,
            child: sumText == null
                ? null
                : Text(
                    sumText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isSmall ? 8 : 9,
                      height: 1.0,
                      color: const Color(0xFFFFB3B3),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MonthCategoryPanel extends StatelessWidget {
  final int monthTotal;
  final List<_ExpenseItem> items;
  final double progress;
  final Widget? handle;

  const _MonthCategoryPanel({
    required this.monthTotal,
    required this.items,
    required this.progress,
    this.handle,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');

    final Map<String, int> byCat = {};
    for (final e in items) {
      byCat[e.category] = (byCat[e.category] ?? 0) + e.amount;
    }

    final entries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final visibleEntries = entries.take(6).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const double columnSpacing = 18;
        const double rowSpacing = 12;
        final double itemWidth = (constraints.maxWidth - columnSpacing) / 2;
        final double categoryMaxHeight = 180 * progress;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (handle != null) handle!,
            const Text(
              '이 달의 지출',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF999999),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fmt.format(monthTotal),
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.0,
              ),
            ),
            SizedBox(height: 28 * progress),
            ClipRect(
              child: SizedBox(
                height: categoryMaxHeight,
                child: Opacity(
                  opacity: Curves.easeOut.transform(progress),
                  child: Wrap(
                    spacing: columnSpacing,
                    runSpacing: rowSpacing,
                    children: visibleEntries.map((e) {
                      return SizedBox(
                        width: itemWidth,
                        child: _CategoryRowChip(
                          category: e.key,
                          amount: fmt.format(e.value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryRowChip extends StatelessWidget {
  final String category;
  final String amount;

  const _CategoryRowChip({
    required this.category,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _chipBg(category),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            category,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _chipFg(category),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Color _chipBg(String category) {
    switch (category) {
      case '식비':
        return const Color(0xFFE8B0C2);
      case '배달':
        return const Color(0xFFE8CDAA);
      case '교통비':
        return const Color(0xFFC8DAEB);
      case '문화':
        return const Color(0xFFE8D2D2);
      case '의료':
        return const Color(0xFFD3DFB2);
      case '생필품':
        return const Color(0xFFDCD0F3);
      case '쇼핑':
        return const Color(0xFFE8E39A);
      default:
        return const Color(0xFFD9D9D9);
    }
  }

  Color _chipFg(String category) {
    switch (category) {
      case '식비':
        return const Color(0xFF6A1232);
      case '배달':
        return const Color(0xFF7A4518);
      case '교통비':
        return const Color(0xFF284A69);
      case '문화':
        return const Color(0xFF6E2C2C);
      case '의료':
        return const Color(0xFF4A5A22);
      case '생필품':
        return const Color(0xFF53317C);
      case '쇼핑':
        return const Color(0xFF665A00);
      default:
        return const Color(0xFF444444);
    }
  }
}

class _DayDetailPanel extends StatelessWidget {
  final DateTime day;
  final List<_ExpenseItem> items;
  final Color accent;
  final ValueChanged<_ExpenseItem> onEdit;
  final Future<void> Function(String id) onDelete;

  const _DayDetailPanel({
    required this.day,
    required this.items,
    required this.accent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final total = items.fold<int>(0, (acc, e) => acc + e.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Text(
            DateFormat('MMMM d').format(day),
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fmt.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text(
                      '해당 날짜의 지출 내역이 없습니다.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final e = items[index];
                      final categoryStyle = getCategoryStyle(e.category);
                      return Slidable(
                        key: ValueKey(e.id),
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (_) => onEdit(e),
                              backgroundColor: const Color.fromARGB(255, 171, 176, 228),
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: '수정',
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          extentRatio: 0.25,
                          children: [
                            SlidableAction(
                              onPressed: (_) => onDelete(e.id),
                              backgroundColor: const Color(0xFFFF5F5F),
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: '삭제',
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ],
                        ),
                        child: Container(
                          
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A3A3A),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: categoryStyle.backgroundColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  e.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: categoryStyle.textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.memo.isEmpty ? '메모 없음' : e.memo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                fmt.format(e.amount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseItem {
  final String id;
  final int amount;
  final String category;
  final String memo;
  final DateTime date;
  final DateTime? createdAt;

  _ExpenseItem({
    required this.id,
    required this.amount,
    required this.category,
    required this.memo,
    required this.date,
    this.createdAt,
  });
}