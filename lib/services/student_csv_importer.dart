import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class StudentCsvImporter {
  static Future<void> importStudents() async {
    final firestore = FirebaseFirestore.instance;

    final rawData = await rootBundle.loadString(
      'assets/data/students.csv',
    );

    final rows = const CsvToListConverter().convert(rawData, eol: '\n');

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      final phone = row[1].toString().trim(); // +919022330817

      await firestore
          .collection('students')
          .doc(phone) // 🔥 PHONE AS DOCUMENT ID
          .set({
        'phone': phone,
        'name': row[2],
        'universityId': row[3],
        'rollNo': row[4],
        'course': row[5],
        'year': row[6].toString(),
        'isActive': row[7].toString().toLowerCase() == 'true',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    print('✅ Student CSV import completed');
  }
}
