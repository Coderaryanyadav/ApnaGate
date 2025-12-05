import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/visitor_request.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/visitor_card.dart';

class ApprovalScreen extends ConsumerWidget {
  const ApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const Center(child: Text('Not logged in'));

    final requestsStream = ref.watch(firestoreServiceProvider).getPendingRequestsForResident(user.uid);

    return StreamBuilder<List<VisitorRequest>>(
      stream: requestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No pending approvals'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return VisitorCard(
              request: request,
              showActions: true,
              onApprove: () => _handleApproval(context, ref, request.id, 'approved'),
              onReject: () => _handleApproval(context, ref, request.id, 'rejected'),
            );
          },
        );
      },
    );
  }

  Future<void> _handleApproval(
      BuildContext context, WidgetRef ref, String requestId, String status) async {
    try {
      await ref.read(firestoreServiceProvider).updateVisitorStatus(requestId, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visitor $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
