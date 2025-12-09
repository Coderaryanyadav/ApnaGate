import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/extras.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widgets.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../utils/input_validator.dart';
import '../../utils/haptic_helper.dart';


import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_constants.dart';

// --- COMPLAINTS ADMIN ---
class ComplaintAdminScreen extends ConsumerWidget {
  const ComplaintAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Manage Complaints'), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      body: StreamBuilder<List<Complaint>>(
        stream: ref.watch(firestoreServiceProvider).getAllComplaints(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingList(message: 'Loading complaints...');
          final complaints = snapshot.data!;
          
          if (complaints.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No Open Complaints',
              message: 'All complaints have been resolved',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final c = complaints[index];
              return Card(
                color: Colors.white.withOpacity(0.05), // Use withOpacity for safety if withValues fails versions
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.report, color: Colors.white),
                  ),
                  title: Row(
                    children: [
                       if (c.ticketId != null) 
                         Text('${c.ticketId} • ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
                       Expanded(child: Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppConstants.spacing4),
                      Text(c.description, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: AppConstants.spacing4),
                      Text(
                        '${c.flatNumber} • ${c.status.toUpperCase()}',
                         style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.white),
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintChatAdminWrapper(complaint: c)));
                        },
                      ),
                      PopupMenuButton<String>(
                        color: Colors.grey[900],
                        iconColor: Colors.white,
                        onSelected: (val) async {
                          await ref.read(firestoreServiceProvider).updateComplaintStatus(c.id, val);
                          if (context.mounted) {
                            ref.invalidate(firestoreServiceProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Status updated to ${val.toUpperCase()}')),
                            );
                          }
                        },
                        itemBuilder: (_) => ['open', 'in_progress', 'resolved'].map((s) => PopupMenuItem(
                          value: s, child: Text(s.toUpperCase(), style: const TextStyle(color: Colors.white))
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ComplaintChatAdminWrapper extends ConsumerWidget {
  final Complaint complaint;
  const ComplaintChatAdminWrapper({super.key, required this.complaint});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AdminChatScreen(complaint: complaint);
  }
}

class _AdminChatScreen extends ConsumerStatefulWidget {
  final Complaint complaint;
  const _AdminChatScreen({required this.complaint});

  @override
  ConsumerState<_AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<_AdminChatScreen> {
  final _messageController = TextEditingController();

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    _messageController.clear();
    
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      await ref.read(firestoreServiceProvider).sendComplaintMessage(
        complaintId: widget.complaint.id,
        message: text.isEmpty ? null : text,
        imageUrl: imageUrl,
        senderId: user.id,
        isAdmin: true, // ADMIN SENDING
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Chat: ${widget.complaint.flatNumber}'), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: ref.watch(firestoreServiceProvider).getComplaintChats(widget.complaint.id),
              builder: (context, snapshot) {
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                 final chats = snapshot.data ?? [];
                 
                 return ListView.builder(
                   padding: const EdgeInsets.all(16),
                   itemCount: chats.length,
                   itemBuilder: (context, index) {
                     final chat = chats[index];
                     final isMe = chat.isAdmin; // ADMIN VIEW
                     return Align(
                       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                       child: Container(
                         padding: const EdgeInsets.all(12),
                         margin: const EdgeInsets.symmetric(vertical: 4),
                         decoration: BoxDecoration(
                           color: isMe ? Colors.white : Colors.white10,
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (chat.imageUrl != null)
                                CachedNetworkImage(
                                  imageUrl: chat.imageUrl!, 
                                  height: 150,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              if (chat.message != null)
                                Text(
                                  chat.message!, 
                                  style: TextStyle(color: isMe ? Colors.black : Colors.white)
                                ),
                            ],
                         ),
                       ),
                     );
                   },
                 );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(child: TextField(
                  controller: _messageController, 
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Reply as Admin...', hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none)
                )),
                IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- SERVICE ADMIN ---
class ServiceProviderAdminScreen extends ConsumerWidget {
  const ServiceProviderAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black, 
      appBar: AppBar(
        title: const Text('Manage Service Providers'),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: StreamBuilder<List<ServiceProvider>>(
        stream: ref.watch(firestoreServiceProvider).getServiceProviders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingList(message: 'Loading service providers...');
          final providers = snapshot.data!;

          if (providers.isEmpty) {
            return const EmptyState(
              icon: Icons.engineering,
              title: 'No Service Providers',
              message: 'Add staff members to get started',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final p = providers[index];
              return Card(
                color: Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), 
                  side: BorderSide(color: Colors.white.withOpacity(0.1))
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white10,
                      child: Text(p.name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    title: Text(
                      p.name, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppConstants.spacing4),
                        Chip(
                          label: Text(p.category, style: const TextStyle(color: Colors.white)), 
                          backgroundColor: Colors.white10, 
                          padding: EdgeInsets.zero, 
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide.none,
                        ),
                        const SizedBox(height: AppConstants.spacing4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: Colors.grey), 
                            const SizedBox(width: AppConstants.spacing4), 
                            Text(p.phone, style: const TextStyle(color: Colors.white70))
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _showEditDialog(context, ref, p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProvider(context, ref, p.id),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Add Provider', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        onPressed: () => _showAddDialog(context, ref),
      ),
    );
  }

  Future<void> _deleteProvider(BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await ConfirmationDialog.confirmDelete(
      context: context,
      itemName: 'service provider',
    );

    if (!confirmed) return;

    try {
      await ref.read(firestoreServiceProvider).deleteServiceProvider(id);
      if (context.mounted) {
        HapticHelper.mediumImpact();
        ref.invalidate(firestoreServiceProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Provider deleted'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        HapticHelper.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Staff', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70), prefixIcon: Icon(Icons.person, color: Colors.white70)), validator: InputValidator.validateName),
              const SizedBox(height: AppConstants.spacing12),
              TextFormField(controller: catCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Role (e.g. Watchman)', labelStyle: TextStyle(color: Colors.white70), prefixIcon: Icon(Icons.badge, color: Colors.white70)), validator: (v) => InputValidator.validateRequired(v, 'Role')),
              const SizedBox(height: AppConstants.spacing12),
              TextFormField(controller: phoneCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: Colors.white70), prefixIcon: Icon(Icons.phone, color: Colors.white70)), keyboardType: TextInputType.phone, validator: InputValidator.validatePhone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await ref.read(firestoreServiceProvider).addServiceProvider(ServiceProvider(
                  id: const Uuid().v4(),
                  name: nameCtrl.text,
                  category: catCtrl.text,
                  phone: phoneCtrl.text,
                  isVerified: true,
                  status: 'out',
                ));
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(firestoreServiceProvider);
                }
              }
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, ServiceProvider p) {
    final nameCtrl = TextEditingController(text: p.name);
    final catCtrl = TextEditingController(text: p.category);
    final phoneCtrl = TextEditingController(text: p.phone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Edit Staff', style: TextStyle(color: Colors.white)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70), prefixIcon: Icon(Icons.person, color: Colors.white70)), validator: InputValidator.validateName),
              const SizedBox(height: AppConstants.spacing12),
              TextFormField(controller: catCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Role', labelStyle: TextStyle(color: Colors.white70), prefixIcon: Icon(Icons.badge, color: Colors.white70)), validator: (v) => InputValidator.validateRequired(v, 'Role')),
              const SizedBox(height: AppConstants.spacing12),
              TextFormField(controller: phoneCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: Colors.white70), prefixIcon: Icon(Icons.phone, color: Colors.white70)), keyboardType: TextInputType.phone, validator: InputValidator.validatePhone),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final updated = p.copyWith(
                  name: nameCtrl.text,
                  category: catCtrl.text,
                  phone: phoneCtrl.text,
                );
                await ref.read(firestoreServiceProvider).updateServiceProvider(updated);
                if (context.mounted) {
                  Navigator.pop(context);
                  ref.invalidate(firestoreServiceProvider);
                }
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}
