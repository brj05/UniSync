import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _db = FirebaseFirestore.instance;

  Future<bool> verifyStudent(String phone, String roll) async {
    try {
      final doc = await _db.collection('students').doc(phone).get();

      if (!doc.exists) return false;

      final data = doc.data()!;
      return data['rollNo'] == roll;
    } catch (e) {
      return false;
    }
  }
}
