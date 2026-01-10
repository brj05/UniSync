import 'package:flutter/material.dart';
import '../screens/club_hub.dart';
import '../screens/notification_screen.dart';
AppBar buildHomeAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: const Color(0xFFFFF6EC), // same as app bg
    elevation: 0,
    centerTitle: false,
    titleSpacing: 16,

    /// LEFT: LOGO + TEXT
    title: Row(
      children: [
        Image.asset(
          'assets/images/logo.png',
          height: 32,
        ),
        const SizedBox(width: 8),
        const Text(
          'UniSync',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    ),

    /// RIGHT: ACTION ICONS
    actions: [
      IconButton(
        icon: const Icon(Icons.notifications_none),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationScreen(),
            ),
          );
        },
      ),

      IconButton(
              icon: const Icon(Icons.groups_outlined, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClubHubScreen()),
                );
              },
      ),

      const SizedBox(width: 8),
    ],
  );
}
