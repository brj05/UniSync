import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/notification_tile.dart';
import '../widgets/home_bottom_nav.dart';
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _buildNotifications() {
    switch (_tabController.index) {
      /// 🔔 PERSONAL
      case 0:
        return const [
          NotificationTile(
            avatar: 'https://i.pravatar.cc/150?img=1',
            title: 'Aarav liked your post',
            time: '2h',
          ),
          NotificationTile(
            avatar: 'https://i.pravatar.cc/150?img=2',
            title: 'Priya commented on your post',
            time: '5h',
          ),
        ];

      /// 🏫 CLUB
      case 1:
        return const [
          NotificationTile(
            avatar: 'https://i.pravatar.cc/150?img=4',
            title: 'Photography Club posted an update',
            subtitle: 'Marked as club collaboration',
            time: '1h',
          ),
        ];

      /// 🛡 ADMIN
      case 2:
        return const [
          NotificationTile(
            avatar: 'https://i.pravatar.cc/150?img=6',
            title: 'Admin updated your score',
            subtitle: 'Creativity score increased',
            time: 'Yesterday',
          ),
        ];

      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: buildHomeAppBar(context),
      body: Column(
        children: [
          /// TAB BAR
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF8B5CF6),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              onTap: (_) => setState(() {}), // 🔥 KEY LINE
              tabs: const [
                Tab(text: 'Personal'),
                Tab(text: 'Clubs'),
                Tab(text: 'Admin'),
              ],
            ),
          ),

          /// DYNAMIC CONTENT
          Expanded(
            child: ListView(
              children: _buildNotifications(),
            ),
          ),
        ],
      ),
    );
  }
}
