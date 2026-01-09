import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_shell.dart';

class InterestSelectionScreen extends StatefulWidget {
  final String phone;

  const InterestSelectionScreen({super.key, required this.phone});

  @override
  State<InterestSelectionScreen> createState() =>
      _InterestSelectionScreenState();
}

class _InterestSelectionScreenState extends State<InterestSelectionScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String studentName = '';
  bool loading = true;
  bool submitting = false;

  final List<Map<String, dynamic>> interests = [
    {
      'title': 'Dance',
      'image': 'assets/images/dance.jpg',
      'clubs': 0,
    },
    {
      'title': 'Singing',
      'image': 'assets/images/singing.jpg',
      'clubs': 0,
    },
    {
      'title': 'Stand-up Comedy',
      'image': 'assets/images/standup.jpg',
      'clubs': 0,
    },
    {
      'title': 'Content Creation',
      'image': 'assets/images/content_creator.jpg',
      'clubs': 0,
    },
    {
      'title': 'Video Editing',
      'image': 'assets/images/editing.jpg',
      'clubs': 0,
    },
    {
      'title': 'Reel Making',
      'image': 'assets/images/reel_making.jpg',
      'clubs': 0,
    },
    {
      'title': 'Photography',
      'image': 'assets/images/photography.jpg',
      'clubs': 0,
    },
    {
      'title': 'Debate',
      'image': 'assets/images/debate.jpg',
      'clubs': 0,
    },
    {
      'title': 'Creative Writing',
      'image': 'assets/images/writing.jpg',
      'clubs': 0,
    },
    {
      'title': 'Coding',
      'image': 'assets/images/coding.jpg',
      'clubs': 0,
    },
    {
      'title': 'App Development',
      'image': 'assets/images/app_dev.jpg',
      'clubs': 0,
    },
    {
      'title': 'Cooking',
      'image': 'assets/images/cooking.jpg',
      'clubs': 0,
    },
    {
      'title': 'Philanthropy',
      'image': 'assets/images/philanthropy.jpg',
      'clubs': 0,
    },
  ];

  final Set<String> selectedInterests = {};

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    final doc =
        await _db.collection('students').doc(widget.phone).get();

    if (doc.exists) {
      studentName = doc.data()?['name'] ?? 'Student';
    }

    setState(() => loading = false);
  }

  void toggleSelection(String interest) {
    setState(() {
      if (selectedInterests.contains(interest)) {
        selectedInterests.remove(interest);
      } else {
        selectedInterests.add(interest);
      }
    });
  }

  Future<void> submitInterests() async {
    if (selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one interest')),
      );
      return;
    }

    setState(() => submitting = true);

    await _db.collection('students').doc(widget.phone).update({
      'interests': selectedInterests.toList(),
      'interestsSelected': true,
    });

    if (!mounted) return;
// TODO: Navigate to Home
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B5CF6),
        elevation: 0,
        title: Text(
          'Hi, $studentName',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select your Interest',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: GridView.builder(
                itemCount: interests.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  final item = interests[index];
                  final selected =
                      selectedInterests.contains(item['title']);

                  return GestureDetector(
                    onTap: () => toggleSelection(item['title']),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: AssetImage(item['image']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withOpacity(0.35),
                          ),
                        ),

                        Positioned(
                          left: 12,
                          bottom: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'No of clubs: ${item['clubs']}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (selected)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: submitting ? null : submitInterests,
                child: submitting
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Next',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
