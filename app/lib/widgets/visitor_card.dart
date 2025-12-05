import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/visitor_request.dart';

class VisitorCard extends StatelessWidget {
  final VisitorRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool showActions;

  const VisitorCard({
    super.key,
    required this.request,
    this.onApprove,
    this.onReject,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 Color & Icon Logic
    final purp = request.purpose.toLowerCase();
    final isDelivery = purp.contains('delivery');
    final isGuest = purp.contains('guest');
    final isCab = purp.contains('cab');
    
    Color typeColor = Colors.grey;
    IconData typeIcon = Icons.info;
    // Strip Emojis
    String cleanPurpose = request.purpose.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim().toUpperCase();
    if (cleanPurpose.isEmpty) cleanPurpose = "VISITOR";

    if (isDelivery) { typeColor = Colors.orange; typeIcon = Icons.local_shipping; }
    else if (isGuest) { typeColor = Colors.blue; typeIcon = Icons.people; }
    else if (isCab) { typeColor = Colors.yellow.shade800; typeIcon = Icons.local_taxi; }
    else { typeColor = Colors.purple; typeIcon = Icons.build; }

    final cardColor = Theme.of(context).cardTheme.color ?? const Color(0xFF1E1E1E);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8), // Margin handled by parent mostly, but keeping vertical
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Header: Status & Time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor(request.status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(typeIcon, size: 16, color: typeColor),
                    const SizedBox(width: 6),
                    Text(
                      cleanPurpose,
                      style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  _formatTime(request.createdAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 📸 Photo (Base64) with Hero Animation
                GestureDetector(
                  onTap: () => _showFullScreenImage(context, request.photoUrl, 'photo_${request.id}'),
                  child: Hero(
                    tag: 'photo_${request.id}',
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                        color: Colors.black,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImage(request.photoUrl),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // 📝 Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.visitorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                       Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.white54),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse('tel:${request.visitorPhone}')),
                            child: Text(
                              request.visitorPhone,
                              style: const TextStyle(color: Colors.blueAccent, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Status: ${request.status.toUpperCase()}', 
                        style: TextStyle(
                          color: _getStatusColor(request.status), 
                          fontWeight: FontWeight.bold, 
                          fontSize: 12
                        )
                      ),
                    ],
                  ),
                ),
                
                // 🚦 Status Icon
                _buildStatusIcon(request.status),
              ],
            ),
          ),

          // ⚡ Actions (Approve/Reject) or Active Status
          if (showActions && request.status == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('REJECT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check),
                      label: const Text('APPROVE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return const Center(child: Icon(Icons.person, color: Colors.white54));
    }
    try {
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        errorBuilder: (_,__,___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
      );
    } catch (e) {
      return const Center(child: Icon(Icons.error, color: Colors.white54));
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'exited': return Colors.grey;
      default: return Colors.orange;
    }
  }

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'approved': icon = Icons.check_circle; color = Colors.green; break;
      case 'rejected': icon = Icons.cancel; color = Colors.red; break;
      default: icon = Icons.access_time_filled; color = Colors.orange; break;
    }
    return Icon(icon, color: color, size: 28);
  }

  String _formatTime(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }

  void _showFullScreenImage(BuildContext context, String? photoUrl, String heroTag) {
    if (photoUrl == null || photoUrl.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      body: PhotoView(
        imageProvider: photoUrl.startsWith('http')
            ? NetworkImage(photoUrl) as ImageProvider
            : MemoryImage(base64Decode(photoUrl)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        heroAttributes: PhotoViewHeroAttributes(tag: heroTag),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
      appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
    )));
  }
}
