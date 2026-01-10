import 'package:flutter/material.dart';
import 'create_club.dart';
import '../widgets/home_app_bar.dart';
class ClubHubScreen extends StatelessWidget {
  const ClubHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildHomeAppBar(context),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B5CF6),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateClubScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('My Clubs'),
          const SizedBox(height: 12),
          _clubTile('Photography Club', true),
          _clubTile('Coding Society', true),

          const SizedBox(height: 28),

          _sectionTitle('Discover Clubs'),
          const SizedBox(height: 12),
          _clubTile('Music Club', false),
          _clubTile('Startup Circle', false),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _clubTile(String name, bool joined) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF8B5CF6),
          child: Icon(Icons.groups, color: Colors.white),
        ),
        title: Text(name),
        subtitle: Text(joined ? 'Member' : 'Public club'),
        trailing: joined
            ? const Icon(Icons.chevron_right)
            : const Icon(Icons.add_circle_outline),
        onTap: () {},
      ),
    );
  }
}
