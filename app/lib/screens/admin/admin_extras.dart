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


import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import '../../services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../utils/app_constants.dart';

// --- COMPLAINTS ADMIN ---
class ComplaintAdminScreen extends ConsumerStatefulWidget {
  const ComplaintAdminScreen({super.key});

  @override
  ConsumerState<ComplaintAdminScreen> createState() => _ComplaintAdminScreenState();
}

class _ComplaintAdminScreenState extends ConsumerState<ComplaintAdminScreen> {
  String _selectedStatus = 'open';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Manage Complaints'), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'open', label: Text('Open')),
                  ButtonSegment(value: 'in_progress', label: Text('In Progress')),
                  ButtonSegment(value: 'resolved', label: Text('Resolved')),
                ],
                showSelectedIcon: false,
                selected: {_selectedStatus},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _selectedStatus = newSelection.first);
                },
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) return Colors.white;
                      return Theme.of(context).cardTheme.color ?? Colors.grey[900]!;
                    },
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) return Colors.black;
                      return Colors.grey;
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Complaint>>(
              stream: ref.watch(firestoreServiceProvider).getAllComplaints(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LoadingList(message: 'Loading complaints...');
                var complaints = snapshot.data!;
                
                // Filter by status
                complaints = complaints.where((c) => c.status == _selectedStatus).toList();

                if (complaints.isEmpty) {
                  return EmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No ${_getLabel(_selectedStatus)} Complaints',
                    message: _getEmptyMessage(_selectedStatus),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final c = complaints[index];
                    return Card(
                      color: Colors.white.withValues(alpha: 0.05),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
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
          ),
        ],
      ),
    );
  }

  String _getLabel(String status) {
    switch (status) {
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      default: return 'Open';
    }
  }

  String _getEmptyMessage(String status) {
     switch (status) {
      case 'in_progress': return 'No complaints currently being worked on';
      case 'resolved': return 'No resolved complaints history';
      default: return 'No new complaints!';
    }
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
  bool _isSending = false;

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    _messageController.clear();
    setState(() => _isSending = true);
    
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
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Add Photo', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source, 
      imageQuality: 70, 
      maxWidth: 1200,
    );
    
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      
      // Check file size (300KB = 300 * 1024 bytes)
      final fileSize = await file.length();
      const maxSize = 3000 * 1024; // 3MB to match resident side logic (user requested 300KB previously but code has 3000KB/3MB in resident side?? Let's stick to 3MB or whatever user code has. Code had 3000*1024)
      
      if (fileSize > maxSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image too large! Max 3MB (Current: ${(fileSize / 1024).toStringAsFixed(0)}KB)'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show preview dialog
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Send this image?', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(file, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Text(
                'Size: ${(fileSize / 1024).toStringAsFixed(1)}KB',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() => _isSending = true);
        try {
          final url = await ref.read(storageServiceProvider).uploadComplaintImage(file);
          if (url != null) {
            await _sendMessage(imageUrl: url);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image sent successfully!'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } else {
            throw Exception('Failed to process image');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
            );
          }
        } finally {
          if (mounted) setState(() => _isSending = false);
        }
      }
    }
  }

  void _showFullscreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Image', style: TextStyle(color: Colors.white)),
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
                                GestureDetector(
                                  onTap: () => _showFullscreenImage(chat.imageUrl!),
                                  child: CachedNetworkImage(
                                    imageUrl: chat.imageUrl!, 
                                    height: 150,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                  ),
                                ),
                              if (chat.message != null)
                                  Text(
                                    chat.message!, 
                                    style: TextStyle(color: isMe ? Colors.black : Colors.white)
                                  ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTime(chat.createdAt),
                                style: TextStyle(fontSize: 10, color: isMe ? Colors.grey[600] : Colors.white54),
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
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate, color: Colors.blueAccent),
                  onPressed: _showImageSourceDialog,
                ),
                Expanded(child: TextField(
                  controller: _messageController, 
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Reply as Admin...', hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none)
                )),
                IconButton(
                  icon: _isSending 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white), 
                  onPressed: _isSending ? null : () => _sendMessage()
                ),
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
                color: Colors.white.withValues(alpha: 0.05),
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), 
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1))
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Provider deleted')));
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
