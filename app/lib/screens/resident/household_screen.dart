import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class HouseholdScreen extends ConsumerStatefulWidget {
  const HouseholdScreen({super.key});

  @override
  ConsumerState<HouseholdScreen> createState() => _HouseholdScreenState();
}

class _HouseholdScreenState extends ConsumerState<HouseholdScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final profile = await ref.read(firestoreServiceProvider).getUser(user.id);
    if (profile == null) return;

    final updatedMembers = [...(profile.familyMembers ?? []), name];
    await ref.read(firestoreServiceProvider).updateUser(profile.copyWith(familyMembers: updatedMembers));

    _nameController.clear();
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $name to household')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Household Members')),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : FutureBuilder(
              future: ref.read(firestoreServiceProvider).getUser(user.id),
              builder: (context, snapshot) {
                final profile = snapshot.data;
                final members = profile?.familyMembers ?? [];

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(hintText: 'Member Full Name'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addMember,
                            child: const Text('ADD'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: members.isEmpty
                            ? const Center(child: Text('No family members added yet.'))
                            : ListView.builder(
                                itemCount: members.length,
                                itemBuilder: (context, index) {
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.person),
                                      title: Text(members[index]),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
