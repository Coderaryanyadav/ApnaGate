import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user.dart';
import '../../services/firestore_service.dart';

class ManageUsersScreen extends ConsumerWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersStream = ref.watch(firestoreServiceProvider).getAllUsers();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement user creation dialog
          // Ideally this would trigger a Cloud Function or use a secondary auth app
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User creation via Admin panel not implemented yet')),
          );
        },
        child: const Icon(Icons.person_add),
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: usersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final users = snapshot.data ?? [];

          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
                ),
                title: Text(user.name),
                subtitle: Text('${user.role.toUpperCase()} • ${user.phone}'),
                trailing: user.flatNumber != null
                    ? Chip(label: Text(user.flatNumber!))
                    : const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
