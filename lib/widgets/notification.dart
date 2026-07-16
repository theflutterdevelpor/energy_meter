import 'package:flutter/material.dart';

import '../models/response/notification_response.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {


  String _selectedTab = 'All';
  bool _hasChanges = false;


  bool _isLoading = true;
  String? _errorMessage;

  List<NotificationModel> _notifications = [];



  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await NotificationApi.getMyNotifications();
      setState(() {
        _notifications = response.data.where((n) {
          return n.type == 'electricity_alert';
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadIds = _notifications
        .where((n) => !n.read)
        .map((n) => n.id)
        .toList();

    if (unreadIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications are already read')),
      );
      return;
    }

    final success = await NotificationApi.markManyAsRead(ids: unreadIds);

    if (success) {
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(read: true))
            .toList();
      });
      _hasChanges = true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  // Future<void> _markSingleAsRead(NotificationModel notification) async {
  //   if (notification.read) return;
  //
  //   final success = await NotificationApi.markAsRead(
  //     notificationId: notification.id,
  //   );
  //   print("API Success: $success");
  //   if (success) {
  //     await _fetchNotifications();
  //   }
  //
  //   if (success) {
  //     setState(() {
  //       final index = _notifications.indexWhere((n) => n.id == notification.id);
  //       if (index != -1) {
  //         _notifications[index] = notification.copyWith(read: true);
  //       }
  //     });
  //     _hasChanges = true;
  //     print("Local Read Updated");
  //   } else {
  //     print("API Failed");
  //   }
  // }

  Future<void> _markSingleAsRead(NotificationModel notification) async {

    print("=== _markSingleAsRead Called ===");
    print("Notification ID: ${notification.id}");
    print("Current Read: ${notification.read}");
    if (notification.read) {
      print("Already Read");
      return;
    }

    final success = await NotificationApi.markAsRead(
      notificationId: notification.id,
    );

    print("API Success: $success");

    if (!success) {
      print("API Failed");
      return;
    }

    setState(() {
      final index =
      _notifications.indexWhere((n) => n.id == notification.id);

      if (index != -1) {
        _notifications[index] =
            _notifications[index].copyWith(read: true);
      }
    });

    print("Local Read Updated");

    await _fetchNotifications();

    _hasChanges = true;
  }



  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        final hour = date.hour;
        final minute = date.minute.toString().padLeft(2, '0');
        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return 'Today at $hour12:$minute $period';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return 'Last ${days[date.weekday - 1]}';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (_) {
      return isoDate;
    }
  }




  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final GlobalKey filterIconKey = GlobalKey();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
            },
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _markAllAsRead,
                  child: const Text(
                    "Mark all as read",
                    style: TextStyle(color: Colors.green, fontSize: 10),
                  ),
                ),



                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [


          Row(
            children: [
              _buildTab("All"),
              _buildTab("Unread"),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Failed to load notifications',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fetchNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      );
    }

    return buildNotificationList();
  }

  Widget _buildTab(String label) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget buildNotificationList() {
    var filtered = _notifications.where((n) {
      if (_selectedTab == 'Unread') return !n.read;
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "No notifications found.",
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }



    return RefreshIndicator(
      color: Colors.green,
      onRefresh: _fetchNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final n = filtered[index];
          return GestureDetector(
              onTap: () async {
                print("Notification tapped: ${n.id}");
                await _markSingleAsRead(n);
              },
            child: buildNotificationTile(
              title: n.title,
              message: n.message,
              time: _formatDate(n.createdAt),
              isUnread: !n.read,
            ),
          );
        },
      ),
    );
  }

  Widget buildNotificationTile({
    required String title,
    required String message,
    required String time,
    bool isUnread = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUnread
            ? Colors.green.withOpacity(0.18)
            : const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? Colors.green.withOpacity(0.5)
              : Colors.white10,
          width: isUnread ? 1.2 : 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + Title + Message
          Row(
            children: [
              const Icon(Icons.circle, color: Colors.green, size: 10),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$title: $message",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}