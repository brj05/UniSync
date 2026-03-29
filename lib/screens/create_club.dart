import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/session_service.dart';

class CreateClubScreen extends StatefulWidget {
  const CreateClubScreen({super.key});

  @override
  State<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final adminController = TextEditingController();
  final memberController = TextEditingController();

  Map<String, dynamic>? selectedAdmin;
  List<Map<String, dynamic>> selectedMembers = [];

  bool loading = false;

  Future<String> _getCurrentUserName(String phone) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(phone)
        .get();

    return doc.data()?['name'] ?? 'Unknown';
  }

  Future<void> _submitClubRequest() async {
    final name = nameController.text.trim();
    final desc = descController.text.trim();

    if (name.isEmpty || desc.isEmpty || selectedAdmin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and select an admin'),
        ),
      );
      return;
    }

    setState(() => loading = true);

    final creatorPhone = await SessionService.getPhone();
    final creatorName = await _getCurrentUserName(creatorPhone ?? '');

    final requestRef = await FirebaseFirestore.instance
        .collection('club_requests')
        .add({
      'name': name,
      'about': desc,
      'createdBy': creatorPhone,
      'createdByName': creatorName,
      'approvalAdminPhone': selectedAdmin!['phone'],
      'approvalAdminName': selectedAdmin!['name'],
      'invitedMembers': selectedMembers.map((e) => e['phone']).toList(),
      'invitedMembersData': selectedMembers,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(selectedAdmin!['phone'])
        .collection('notifications')
        .add({
      'type': 'club_request',
      'clubRequestId': requestRef.id,
      'clubName': name,
      'about': desc,
      'creatorPhone': creatorPhone,
      'creatorName': creatorName,
      'members': selectedMembers,
      'seen': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    setState(() => loading = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Club request sent to selected admin'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Club'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Club Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'About Club',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TypeAheadField<Map<String, dynamic>>(
              controller: adminController,
              suggestionsCallback: (pattern) async {
                final snap = await FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'admin')
                    .get();

                return snap.docs
                    .map((e) => {
                          'phone': e.id,
                          'name': e['name'] ?? '',
                        })
                    .where(
                      (user) => user['name']
                          .toString()
                          .toLowerCase()
                          .contains(pattern.toLowerCase()),
                    )
                    .toList();
              },
              itemBuilder: (context, user) {
                return ListTile(
                  title: Text(user['name']),
                  subtitle: Text(user['phone']),
                );
              },
              onSelected: (user) {
                setState(() {
                  selectedAdmin = user;
                  adminController.text = user['name'];
                });
              },
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Select Approval Admin',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TypeAheadField<Map<String, dynamic>>(
              controller: memberController,
              suggestionsCallback: (pattern) async {
                final snap = await FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
                    .get();

                return snap.docs
                    .map((e) => {
                          'phone': e.id,
                          'name': e['name'] ?? '',
                        })
                    .where((user) {
                      final matches = user['name']
                          .toString()
                          .toLowerCase()
                          .contains(pattern.toLowerCase());

                      final alreadyAdded = selectedMembers.any(
                        (m) => m['phone'] == user['phone'],
                      );

                      return matches && !alreadyAdded;
                    }).toList();
              },
              itemBuilder: (context, user) {
                return ListTile(
                  title: Text(user['name']),
                  subtitle: Text(user['phone']),
                );
              },
              onSelected: (user) {
                setState(() {
                  selectedMembers.add(user);
                  memberController.clear();
                });
              },
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Add Members',
                    hintText: 'Search students and add',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedMembers.map((member) {
                  return Chip(
                    label: Text(member['name']),
                    onDeleted: () {
                      setState(() {
                        selectedMembers.removeWhere(
                          (m) => m['phone'] == member['phone'],
                        );
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: loading ? null : _submitClubRequest,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Request Club Creation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
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