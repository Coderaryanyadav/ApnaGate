import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import '../../models/extras.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ComplaintChatScreen extends ConsumerStatefulWidget {
  final Complaint complaint;

  const ComplaintChatScreen({super.key, required this.complaint});

  @override
  ConsumerState<ComplaintChatScreen> createState() => _ComplaintChatScreenState();
}

class _ComplaintChatScreenState extends ConsumerState<ComplaintChatScreen> {
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
        isAdmin: false, // User is sending
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
        backgroundColor: const Color(0xFF1E1E1E),
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
      const maxSize = 3000 * 1024; // 3MB
      
      if (fileSize > maxSize) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image too large! Max 3MB (Current: ${(fileSize / 1024).toStringAsFixed(0)}KB)'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
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
          backgroundColor: const Color(0xFF1E1E1E),
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
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            throw Exception('Failed to process image');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Upload failed: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
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
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.error, color: Colors.red, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark Theme
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF1E1E1E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ticket ${widget.complaint.ticketId ?? "..."}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(
              widget.complaint.title, 
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
             margin: const EdgeInsets.only(right: 16),
             decoration: BoxDecoration(
               color: _getStatusColor(widget.complaint.status).withValues(alpha: 0.1),
               borderRadius: BorderRadius.circular(20),
               border: Border.all(color: _getStatusColor(widget.complaint.status)),
             ),
             child: Text(
               widget.complaint.status.toUpperCase().replaceAll('_', ' '),
               style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(widget.complaint.status)),
             ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat List
          Expanded(
            child: StreamBuilder<List<ComplaintChat>>(
              stream: ref.watch(firestoreServiceProvider).getComplaintChats(widget.complaint.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final chats = snapshot.data!;

                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(Icons.mark_chat_unread_outlined, size: 60, color: Colors.grey.shade800),
                         const SizedBox(height: 16),
                         Text(
                          'Start the conversation\nDescribe your issue clearly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                     final chat = chats[index];
                     final isMe = !chat.isAdmin; // Assuming current user is "me" (resident app)
                     
                     return Align(
                       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                       child: Container(
                         margin: const EdgeInsets.symmetric(vertical: 4),
                         padding: const EdgeInsets.all(12),
                         constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                         decoration: BoxDecoration(
                           gradient: isMe 
                              ? const LinearGradient(colors: [Colors.blueAccent, Colors.blue])
                              : const LinearGradient(colors: [Color(0xFF2C2C2E), Color(0xFF2C2C2E)]),
                           borderRadius: BorderRadius.only(
                             topLeft: const Radius.circular(16),
                             topRight: const Radius.circular(16),
                             bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                             bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                           ),
                           boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))],
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             if (chat.imageUrl != null)
                                GestureDetector(
                                  onTap: () => _showFullscreenImage(chat.imageUrl!),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Stack(
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: chat.imageUrl!, 
                                          height: 200, 
                                          width: double.infinity, 
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                              height: 200,
                                              color: Colors.white10,
                                              child: const Center(
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            ),
                                          errorWidget: (context, url, error) => const Icon(Icons.error),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.zoom_in, size: 14, color: Colors.white),
                                                SizedBox(width: 4),
                                                Text('Tap to view', style: TextStyle(color: Colors.white, fontSize: 10)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                             if (chat.imageUrl != null && chat.message != null) const SizedBox(height: 8),
                             if (chat.message != null)
                               Text(
                                 chat.message!,
                                 style: const TextStyle(color: Colors.white, fontSize: 16),
                               ),
                             const SizedBox(height: 4),
                             Text(
                               _formatTime(chat.createdAt),
                               style: const TextStyle(fontSize: 10, color: Colors.white54),
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

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate, color: Colors.blueAccent),
                    onPressed: _showImageSourceDialog,
                    tooltip: 'Add Photo (Max 300KB)',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSending 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                      : const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _isSending ? null : () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved': return Colors.green;
      case 'in_progress': return Colors.orange;
      default: return Colors.red;
    }
  }
}
