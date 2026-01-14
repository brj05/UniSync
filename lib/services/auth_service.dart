import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _db = FirebaseFirestore.instance;
//Student Login
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
/// ADMIN LOGIN
    Future<bool> verifyAdmin(String phone, String password) async {
       try {
         final doc = await _db.collection('admins').doc(phone).get();

         if (!doc.exists) return false;

         final data = doc.data()!;

         return data['password'] == password;
       } catch (e) {
         return false;
       }
     }
    Future<void> ensureUserExists({
      required String uid,
      required String name,
      required String role,
    }) async {
      final doc =
          FirebaseFirestore.instance.collection('users').doc(uid);

      final snap = await doc.get();

      if (!snap.exists) {
        await doc.set({
          'uid': uid,
          'name': name,
          'avatar': '',
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    Future<bool> hasSelectedInterests(String phone) async {
      final doc = await _db.collection('students').doc(phone).get();
      return doc.exists && (doc.data()?['interestsSelected'] == true);
    }
    Future<void> syncUserFromSource({
      required String phone,
      required String role, // 'student' or 'admin'
    }) async {
      final usersRef = _db.collection('users');
      final userDoc = usersRef.doc(phone);

      // If already exists → do nothing
      final userSnap = await userDoc.get();
      if (userSnap.exists) return;

      // Decide source collection
      final sourceCollection = role == 'student' ? 'students' : 'admins';

      final sourceDoc =
          await _db.collection(sourceCollection).doc(phone).get();

      if (!sourceDoc.exists) return;

      final sourceData = sourceDoc.data()!;

      // Copy everything + add role
      await userDoc.set({
        ...sourceData,            // copy student/admin fields
        'phone': phone,           // common id
        'role': role,             // 🔥 important
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

}

