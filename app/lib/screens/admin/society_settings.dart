import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/society_config_service.dart';
import '../../utils/haptic_helper.dart';

class SocietySettingsScreen extends ConsumerStatefulWidget {
  const SocietySettingsScreen({super.key});

  @override
  ConsumerState<SocietySettingsScreen> createState() => _SocietySettingsScreenState();
}

class _SocietySettingsScreenState extends ConsumerState<SocietySettingsScreen> {
  final TextEditingController _wingController = TextEditingController();
  final TextEditingController _floorsController = TextEditingController();
  final TextEditingController _flatsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final config = ref.read(societyConfigProvider);
    _floorsController.text = config.totalFloors.toString();
    _flatsController.text = config.flatsPerFloor.toString();
  }

  Future<void> _addWing() async {
    if (_wingController.text.isNotEmpty) {
      final currentWings = List<String>.from(ref.read(societyConfigProvider).wings);
      final newWing = _wingController.text.toUpperCase().trim();
      
      if (!currentWings.contains(newWing)) {
        currentWings.add(newWing);
        currentWings.sort();
        try {
          await ref.read(societyConfigProvider.notifier).updateConfig(wings: currentWings);
          _wingController.clear();
          HapticHelper.mediumImpact();
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wing already exists')));
      }
    }
  }

  Future<void> _removeWing(String wing) async {
    final currentWings = List<String>.from(ref.read(societyConfigProvider).wings);
    currentWings.remove(wing);
    try {
      await ref.read(societyConfigProvider.notifier).updateConfig(wings: currentWings);
      HapticHelper.mediumImpact();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _saveStructure() async {
    final floors = int.tryParse(_floorsController.text);
    final flats = int.tryParse(_flatsController.text);

    if (floors != null && flats != null) {
      try {
        await ref.read(societyConfigProvider.notifier).updateConfig(
          floors: floors,
          flatsPerFloor: flats,
        );
        HapticHelper.mediumImpact();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Structure Updated!')));
      } catch (e) {
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(societyConfigProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Society Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
               colors: [Color(0xFF000000), Color(0xFF1A1A1A)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100), // Top padding for AppBar
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🏢 building Structure Section
              _buildSectionHeader('🏢 Building Structure'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, 10)),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildGlassTextField(
                             controller: _floorsController,
                             label: 'Total Floors',
                             icon: Icons.apartment,
                             isNumber: true
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildGlassTextField(
                             controller: _flatsController,
                             label: 'Flats/Floor',
                             icon: Icons.grid_view,
                             isNumber: true
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigoAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 8,
                          shadowColor: Colors.indigoAccent.withValues(alpha: 0.4),
                        ),
                        onPressed: _saveStructure,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save Structure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              
              // 🏙️ Wings Configuration Section
              _buildSectionHeader('🏙️ Manage Wings'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black, blurRadius: 20, offset: Offset(0, 10)),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildGlassTextField(
                            controller: _wingController, 
                            label: 'Wing Name (e.g. C)', 
                            icon: Icons.add_location_alt,
                            hint: 'Name',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: IconButton(
                            onPressed: _addWing, 
                            icon: const Icon(Icons.add, size: 28, color: Colors.white),
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    config.wings.isEmpty 
                      ? const Center(child: Text('No wings added yet.', style: TextStyle(color: Colors.white38)))
                      : Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: config.wings.map((wing) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Wing $wing', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _removeWing(wing),
                                    child: const Icon(Icons.cancel, size: 18, color: Colors.white70),
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ), 
      ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            prefixIcon: Icon(icon, color: Colors.white70),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.indigoAccent),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
      ),
    );
  }
}
