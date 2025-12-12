import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/visitor_request.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/visitor_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../utils/haptic_helper.dart';

class ApprovalScreen extends ConsumerStatefulWidget {
  const ApprovalScreen({super.key});

  @override
  ConsumerState<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends ConsumerState<ApprovalScreen> {
  // 🏎️ Optimistic UI: Hidden IDs (Approved/Rejected but not yet synced)
  final Set<String> _processedIds = {};

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));

    final requestsStream = ref.watch(firestoreServiceProvider).getPendingRequestsForResident(user.id);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Approvals')),
      body: StreamBuilder<List<VisitorRequest>>(
        stream: requestsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingList(message: 'Loading approvals...');
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          
          // 🚀 Filter out processed items instantly
          final requests = (snapshot.data ?? [])
              .where((r) => !_processedIds.contains(r.id))
              .toList();

          if (requests.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outlined,
              title: 'No Pending Approvals',
              message: 'All visitor requests have been processed',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return VisitorCard(
                request: request,
                showActions: true,
                onApprove: () async {
                    await _handleApproval(context, ref, request, 'approved');
                },
                onReject: () async {
                    await _handleApproval(context, ref, request, 'rejected');
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleApproval(
      BuildContext context, WidgetRef ref, VisitorRequest request, String status) async {
    
    // 1. Confirm First
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: status == 'approved' ? 'Approve Visitor?' : 'Reject Visitor?',
      message: 'Visitor: ${request.visitorName}\nPurpose: ${request.purpose}',
      confirmText: status == 'approved' ? 'Approve' : 'Reject',
      confirmColor: status == 'approved' ? Colors.green : Colors.red,
      icon: status == 'approved' ? Icons.check_circle : Icons.cancel,
    );

    if (!confirmed) return;

    // 2. Optimistic Update (Hide Immediately)
    setState(() {
      _processedIds.add(request.id);
    });

    try {
      // 3. Update DB
    await ref.read(firestoreServiceProvider).updateVisitorStatus(request.id, status);
    
    // 4. Sync Dismissal: Clear notifications for ALL users
    try {
      await ref.read(notificationServiceProvider).markAllNotificationsAsReadForVisitor(request.id);
      
      // 5. Notify Guard
      if (request.guardId.isNotEmpty) {
        await ref.read(notificationServiceProvider).notifyUser(
          userId: request.guardId, 
          title: 'Visitor $status', 
          message: '${request.visitorName} has been $status by resident.',
          data: {'type': 'visitor_status_update', 'requestId': request.id}
        );
      }
    } catch (e) {
      debugPrint('⚠️ Notification failed, but approval saved: $e');
      // Do NOT revert the approval. It is saved.
    }
    
    if (context.mounted) {
      HapticHelper.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Visitor $status successfully!'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    // Only revert if DB update failed
    debugPrint('❌ Critical DB Error: $e');
    if (mounted) {
      setState(() {
        _processedIds.remove(request.id);
      });
      HapticHelper.heavyImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  }
}
