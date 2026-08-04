import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'pages/start_page.dart';
import 'pages/main_page.dart';
import 'pages/calendar_page.dart';
import 'pages/add_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

/// ✅ MyApp은 "딱 1개만"
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const AuthGate(),
    );
  }
}

/// ✅ Firebase 로그인 상태 기반 자동 분기
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 로그인 됨 -> 메인(AppShell)
        if (snap.data != null) {
          return AppShell(
            onLogout: () async {
              await FirebaseAuth.instance.signOut();
            },
          );
        }

        // 로그아웃 -> StartPage
        return const StartPage();
      },
    );
  }
}

// ----------------------------------------------------
// AppShell
// ----------------------------------------------------
class AppShell extends StatefulWidget {
  final VoidCallback onLogout;
  const AppShell({super.key, required this.onLogout});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // 캘린더에서 선택한 날짜 (없으면 오늘)
  DateTime? _selectedCalendarDay;

  late final List<Widget> _pages = [
    const MainPage(),
    CalendarPage(
      onDaySelected: (d) => setState(() => _selectedCalendarDay = d),
    ),
  ];

  Future<void> _onItemTapped(int index) async {
    // 가운데 + 버튼
    if (index == 1) {
      final selected = _selectedCalendarDay ?? DateTime.now();

      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: AddPage(selectedDate: selected),
        ),
      );

      if (saved == true) {
        // 캘린더/메인 리빌드해서 stream 다시 받게
        setState(() {});
      }
      return;
    }

    // 0: home, 2: calendar -> 내부 index는 0/1로 매핑
    setState(() {
      _selectedIndex = index > 1 ? index - 1 : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF333333),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '오버뷰',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 40),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
        ],
        // bottomIndex(0,1,2) <-> pageIndex(0,1) 매핑
        currentIndex: _selectedIndex > 0 ? _selectedIndex + 1 : 0,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}