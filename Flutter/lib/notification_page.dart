import 'package:flutter/material.dart';

// Use the same color constants as main.dart for consistency
const Color kBg = Colors.white;
const Color kCard = Colors.white;
const Color kPrimary = Colors.green;
const Color kAccent = Colors.deepPurple; // Changed from light green to deep purple
const Color kText = Colors.black87;
const Color kGray = Color(0xFFF5F5F5);
const Color kWhite = Colors.white;

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  // Demo notifications
  List<Map<String, dynamic>> get notifications => [
    {
      "title": "Bid Accepted",
      "body": "Your bid on 'Luxury Villa' was accepted.",
      "icon": Icons.check_circle,
      "color": kPrimary,
      "time": "2 min ago"
    },
    {
      "title": "Auction Ending Soon",
      "body": "'Beachfront Condo' auction ends in 1 hour.",
      "icon": Icons.timer,
      "color": kAccent,
      "time": "10 min ago"
    },
    {
      "title": "New Auction Added",
      "body": "A new auction for 'Downtown Apartment' is now live.",
      "icon": Icons.add_box,
      "color": Colors.blueAccent,
      "time": "30 min ago"
    },
    {
      "title": "Outbid Alert",
      "body": "You have been outbid on 'Cozy Cottage'.",
      "icon": Icons.warning,
      "color": Colors.redAccent,
      "time": "1 hr ago"
    },
    {
      "title": "Profile Updated",
      "body": "Your profile information was successfully updated.",
      "icon": Icons.person,
      "color": kPrimary,
      "time": "Yesterday"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: kPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: IconThemeData(color: kPrimary),
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(
                  color: kText,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final notif = notifications[idx];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 232, 229, 229), // Simple grey background for each box
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notif["color"].withOpacity(0.15),
                      child: Icon(
                        notif["icon"],
                        color: notif["color"],
                        size: 28,
                      ),
                    ),
                    title: Text(
                      notif["title"],
                      style: TextStyle(
                        color: kPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif["body"],
                          style: TextStyle(
                            color: kText,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif["time"],
                          style: TextStyle(
                            color: kAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(Icons.chevron_right, color: kGray, size: 28),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                  ),
                );
              },
            ),
    );
  }
}