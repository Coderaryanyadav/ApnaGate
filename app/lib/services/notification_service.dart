import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app.dart';
import '../models/visitor_request.dart';
import 'firestore_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

class NotificationService {
  final Ref ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  NotificationService(this.ref);

  Future<void> initialize(String uid) async {
    // Request permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    await _fcm.subscribeToTopic('residents'); // Subscribe to Announcements

    // Get token
    String? token = await _fcm.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }

    _fcm.onTokenRefresh.listen((token) {
       FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    });

    // Foreground notification setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(initializationSettings);

    // 🔊 CREATE NOTIFICATION CHANNEL (Android 8.0+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Critical visitor and security alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'visitor_request') {
        // 🚀 Premium Dialog for Visitor Requests
        _showApprovalDialog(message.data);
      } else {
        // Standard Notification
        _showNotification(message);
      }
    });
  }

  Future<void> _showApprovalDialog(Map<String, dynamic> data) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final requestId = data['requestId'];
    if (requestId == null) return;

    // Fetch full request details
    try {
      final doc = await FirebaseFirestore.instance.collection('visitorRequests').doc(requestId).get();
      if (!doc.exists) return;

      final request = VisitorRequest.fromMap(doc.data()!, doc.id);

      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      // Show Dialog
      showDialog(
        context: ctx,
        barrierDismissible: false, // Force action
        builder: (context) => _VisitorApprovalDialog(request: request, ref: ref),
      );
    } catch (e) {
      // debugPrint('Error fetching request: $e');
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }
}

// 💎 Premium Dialog Component
class _VisitorApprovalDialog extends StatefulWidget {
  final VisitorRequest request;
  final Ref ref;

  const _VisitorApprovalDialog({required this.request, required this.ref});

  @override
  State<_VisitorApprovalDialog> createState() => _VisitorApprovalDialogState();
}

class _VisitorApprovalDialogState extends State<_VisitorApprovalDialog> {
  bool _isLoading = false;

  Future<void> _handleAction(String status) async {
    // 📳 Haptic Feedback
    if (status == 'approved') {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.vibrate();
    }
    
    setState(() => _isLoading = true);
    try {
      await widget.ref.read(firestoreServiceProvider).updateVisitorStatus(widget.request.id, status);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Decode Photo
    Widget imageWidget;
    try {
      if (widget.request.photoUrl.startsWith('http')) {
        imageWidget = Image.network(widget.request.photoUrl, fit: BoxFit.cover);
      } else {
        imageWidget = Image.memory(base64Decode(widget.request.photoUrl), fit: BoxFit.cover);
      }
    } catch (e) {
      imageWidget = Container(color: Colors.grey, child: const Icon(Icons.person));
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.8, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 📸 Circular Photo with Ring
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.indigo.shade100, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: (imageWidget as Image).image,
              ),
            ),
            const SizedBox(height: 16),
            
            // 📝 Name & Purpose
            Text(
              widget.request.visitorName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.request.purpose.toUpperCase(),
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),

            // ⚡ Actions
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleAction('rejected'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.red.shade200),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('DENY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleAction('approved'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                      ),
                      child: const Text('APPROVE'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
        ),
      ),
    );
  }
}
