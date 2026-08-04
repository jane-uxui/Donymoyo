import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('로그인이 필요합니다.');
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users').doc(_uid).collection('expenses');

  Future<void> addExpense({
    required DateTime date,
    required int amount,
    required String category,
    String memo = '',
  }) async {
    await _col.add({
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'amount': amount,
      'category': category,
      'memo': memo,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 수정
  Future<void> updateExpense(
  String id, {
  required DateTime date,
  required int amount,
  required String category,
  String memo = '',
}) async {
  await _col.doc(id).update({
    'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
    'amount': amount,
    'category': category,
    'memo': memo,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

  /// 삭제
  Future<void> deleteExpense(String docId) async {
    await _col.doc(docId).delete();
  }

  /// 월 단위로 불러오기(캘린더 합계용)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots();
  }

  ///  특정 날짜(리스트용)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return _col
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots();
  }
}