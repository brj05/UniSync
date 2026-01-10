import 'package:flutter/material.dart';

class CreateClubScreen extends StatefulWidget {
  const CreateClubScreen({super.key});

  @override
  State<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final memberController = TextEditingController();
  final adminController = TextEditingController();

  // TEMP USERS (later from Firestore "users" collection)
  final List<String> allUsers = [
    'Aarav Sharma',
    'Priya Verma',
    'Rohit Mehta',
    'Neha Singh',
    'Karan Patel',
  ];

  final List<String> selectedMembers = [];
  String? selectedAdmin;

  List<String> memberSuggestions = [];
  List<String> adminSuggestions = [];

  void _searchMembers(String value) {
    if (!value.contains('@')) {
      setState(() => memberSuggestions = []);
      return;
    }

    final query = value.replaceAll('@', '').toLowerCase();
    setState(() {
      memberSuggestions = allUsers
          .where((u) =>
              u.toLowerCase().contains(query) &&
              !selectedMembers.contains(u))
          .toList();
    });
  }

  void _searchAdmin(String value) {
    if (!value.contains('@')) {
      setState(() => adminSuggestions = []);
      return;
    }

    final query = value.replaceAll('@', '').toLowerCase();
    setState(() {
      adminSuggestions =
          allUsers.where((u) => u.toLowerCase().contains(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Club'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// CLUB NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Club Name'),
            ),

            const SizedBox(height: 16),

            /// DESCRIPTION
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),

            const SizedBox(height: 24),

            /// ADD MEMBERS
            const Text(
              'Add Members',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: memberController,
              decoration: const InputDecoration(
                hintText: 'Type @ to add members',
              ),
              onChanged: _searchMembers,
            ),

            if (memberSuggestions.isNotEmpty)
              _suggestionBox(memberSuggestions, (user) {
                setState(() {
                  selectedMembers.add(user);
                  memberController.clear();
                  memberSuggestions = [];
                });
              }),

            Wrap(
              spacing: 8,
              children: selectedMembers
                  .map(
                    (m) => Chip(
                      label: Text(m),
                      onDeleted: () =>
                          setState(() => selectedMembers.remove(m)),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            /// SELECT ADMIN
            const Text(
              'Select Admin for Approval',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: adminController,
              decoration: const InputDecoration(
                hintText: 'Type @ to select admin',
              ),
              onChanged: _searchAdmin,
            ),

            if (adminSuggestions.isNotEmpty)
              _suggestionBox(adminSuggestions, (user) {
                setState(() {
                  selectedAdmin = user;
                  adminController.text = user;
                  adminSuggestions = [];
                });
              }),

            if (selectedAdmin != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Chip(
                  label: Text('Admin: $selectedAdmin'),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => setState(() {
                    selectedAdmin = null;
                    adminController.clear();
                  }),
                ),
              ),

            const SizedBox(height: 40),

            /// SUBMIT
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Request Club Creation',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionBox(
    List<String> items,
    Function(String) onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(items[i]),
          onTap: () => onTap(items[i]),
        ),
      ),
    );
  }
}
