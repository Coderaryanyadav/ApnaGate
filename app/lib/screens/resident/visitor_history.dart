import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/visitor_request.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/visitor_card.dart';

class VisitorHistoryScreen extends ConsumerWidget {
  const VisitorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    final historyStream = ref.watch(firestoreServiceProvider).getVisitorHistoryForResident(user.uid);

    return StreamBuilder<List<VisitorRequest>>(
      stream: historyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return const Center(child: Text('No visitor history'));
        }

        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) {
            return VisitorCard(request: history[index]);
          },
        );
      },
    );
  }
}
