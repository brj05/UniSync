import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  final String avatar;
  final String title;
  final String? subtitle;
  final String time;

  const NotificationTile({
    super.key,
    required this.avatar,
    required this.title,
    this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(avatar),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: Text(
        time,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
