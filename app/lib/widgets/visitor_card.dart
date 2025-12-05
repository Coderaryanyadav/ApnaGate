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
    final isDelivery = request.purpose.toLowerCase().contains('delivery');
    final isGuest = request.purpose.toLowerCase().contains('guest');
    final isCab = request.purpose.toLowerCase().contains('cab');
    
    Color typeColor = Colors.grey;
    IconData typeIcon = Icons.info;

    if (isDelivery) { typeColor = Colors.orange; typeIcon = Icons.local_shipping; }
    else if (isGuest) { typeColor = Colors.blue; typeIcon = Icons.people; }
    else if (isCab) { typeColor = Colors.yellow.shade800; typeIcon = Icons.local_taxi; }
    else { typeColor = Colors.purple; typeIcon = Icons.build; }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                      request.purpose.toUpperCase(),
                      style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                Text(
                  _formatTime(request.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
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
                  onTap: () => _showFullScreenImage(context, request.photoUrl),
                  child: Hero(
                    tag: 'photo_${request.id}',
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImage(request.photoUrl),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 📝 Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.visitorName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _callNumber(request.visitorPhone),
                            child: Text(
                              request.visitorPhone,
                              style: const TextStyle(fontSize: 14, color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.apartment, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Flat ${request.flatNumber}',
                            style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 🚦 Status Icon
                _buildStatusIcon(request.status),
              ],
            ),
          ),

          // ⚡ Actions (Only if Pending & showActions=true)
          if (showActions && request.status == 'pending') ...[
            const Divider(height: 1),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('REJECT', style: TextStyle(color: Colors.red)),
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade200),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, color: Colors.green),
                    label: const Text('APPROVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildImage(String data) {
    if (data.startsWith('http')) return Image.network(data, fit: BoxFit.cover);
    try {
      return Image.memory(base64Decode(data), fit: BoxFit.cover);
    } catch (e) {
      return Container(color: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey));
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
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
    return DateFormat('h:mm a').format(dt);
  }

  void _callNumber(String phone) {
    launchUrl(Uri.parse('tel:$phone'));
  }

  void _showFullScreenImage(BuildContext context, String data) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      body: PhotoView(
        imageProvider: data.startsWith('http')
            ? NetworkImage(data) as ImageProvider
            : MemoryImage(base64Decode(data)),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        heroAttributes: PhotoViewHeroAttributes(tag: 'photo_$data'),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
      appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
    )));
  }
}
