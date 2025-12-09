import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/extras.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'package:intl/intl.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../utils/haptic_helper.dart';

class NoticeListScreen extends ConsumerWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('📢 Building Notices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Notices',
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Notice>>(
        stream: ref.watch(firestoreServiceProvider).getNotices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingList(message: 'Loading notices...');
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load notices', style: TextStyle(color: Colors.red, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(firestoreServiceProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final notices = snapshot.data ?? [];
          
          if (notices.isEmpty) {
            return const EmptyState(
              icon: Icons.mark_email_unread,
              title: 'No Notices Available',
              message: 'Check back later for updates',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              var _ = ref.refresh(firestoreServiceProvider);
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notices.length,
              itemBuilder: (context, index) {
                final notice = notices[index];
                final isExpired = notice.expiresAt != null && notice.expiresAt!.isBefore(DateTime.now());
                
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isExpired 
                          ? Colors.red.withValues(alpha: 0.3) 
                          : _getTypeColor(notice.type).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getTypeColor(notice.type),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getTypeIcon(notice.type), size: 14, color: Colors.white),
                                  const SizedBox(width: 6),
                                  Text(
                                    notice.type.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (isExpired)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: const Text(
                                  'EXPIRED',
                                  style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          notice.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            decoration: isExpired ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notice.description,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: isDark ? Colors.white54 : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy HH:mm').format(notice.createdAt),
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (notice.expiresAt != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.timer_off, size: 14, color: isExpired ? Colors.red : Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                'Expires: ${DateFormat('MMM dd, yyyy').format(notice.expiresAt!)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpired ? Colors.red : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                        
                        // Admin-only delete button
                        if (user != null) ...[
                          FutureBuilder(
                            future: ref.read(firestoreServiceProvider).getUser(user.id),
                            builder: (context, userSnapshot) {
                              if (userSnapshot.data?.role == 'admin') {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _deleteNotice(context, ref, notice.id, notice.title),
                                        icon: const Icon(Icons.delete, size: 18),
                                        label: const Text('Delete Notice'),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.indigo),
            SizedBox(width: 8),
            Text('About Notices'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stay updated with building announcements:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            _InfoItem(icon: Icons.info, color: Colors.blue, text: 'INFO - General announcements'),
            SizedBox(height: 8),
            _InfoItem(icon: Icons.warning, color: Colors.red, text: 'ALERT - Urgent notifications'),
            SizedBox(height: 8),
            _InfoItem(icon: Icons.event, color: Colors.purple, text: 'EVENT - Upcoming events'),
            SizedBox(height: 12),
            Text('Pull down to refresh notices', style: TextStyle(fontSize: 12, color: Colors.white54, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _deleteNotice(BuildContext context, WidgetRef ref, String noticeId, String title) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Notice',
      message: 'Are you sure you want to delete "$title"?\n\nThis action cannot be undone.',
      confirmText: 'Delete',
      confirmColor: Colors.red,
      icon: Icons.warning_amber,
    );

    if (!confirmed) return;

    try {
      await ref.read(firestoreServiceProvider).deleteNotice(noticeId);
      if (context.mounted) {
        HapticHelper.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Notice deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        HapticHelper.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'alert': return Colors.red;
      case 'event': return Colors.purple;
      default: return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'alert': return Icons.warning_amber;
      case 'event': return Icons.calendar_month;
      default: return Icons.info_outline;
    }
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoItem({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
