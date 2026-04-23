import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/hospital.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/app_header.dart';
import '../widgets/buffer_time_indicator.dart';
import '../widgets/resource_bar.dart';
import '../widgets/skeleton_loader.dart';

class HospitalPanelScreen extends StatefulWidget {
  const HospitalPanelScreen({super.key});

  @override
  State<HospitalPanelScreen> createState() => _HospitalPanelScreenState();
}

class _HospitalPanelScreenState extends State<HospitalPanelScreen> {
  final _bedsController = TextEditingController();
  final _oxygenController = TextEditingController();
  final _icuController = TextEditingController();
  final _ventilatorController = TextEditingController();
  String? _selectedHospitalId;
  String? _selectedHospitalName;
  bool _isSaving = false;

  @override
  void dispose() {
    _bedsController.dispose();
    _oxygenController.dispose();
    _icuController.dispose();
    _ventilatorController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate(AppState state) async {
    if (_selectedHospitalId == null) {
      _showMessage('Select a hospital before updating resources.');
      return;
    }

    final beds = int.tryParse(_bedsController.text.trim()) ?? -1;
    final oxygen = int.tryParse(_oxygenController.text.trim()) ?? -1;
    final icu = int.tryParse(_icuController.text.trim());
    final vent = int.tryParse(_ventilatorController.text.trim());

    if (beds < 0 || oxygen < 0) {
      _showMessage('Please enter valid non-negative numbers.');
      return;
    }

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final success = await state.updateResources(
      hospitalId: _selectedHospitalId!,
      beds: beds,
      oxygen: oxygen,
      icuBeds: icu,
      ventilators: vent,
    );

    if (success) {
      _showMessage('$_selectedHospitalName updated successfully.', success: true);
      _bedsController.clear();
      _oxygenController.clear();
      _icuController.clear();
      _ventilatorController.clear();
    } else {
      _showMessage('Failed to update. ${state.error ?? ''}');
    }

    setState(() => _isSaving = false);
  }

  void _showMessage(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AppHeader(
              title: 'Hospital Control Panel',
              subtitle: 'Update resource availability',
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 14,
                    color: Colors.white60,
                  ),
                ),
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const SkeletonLoader(cardCount: 2)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 900;
                        final hospitals = state.effectiveHospitals;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      flex: 2,
                                      child: _buildUpdateForm(hospitals, state),
                                    ),
                                    const SizedBox(width: 18),
                                    Flexible(
                                      flex: 3,
                                      child: _buildHospitalList(hospitals, state),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildUpdateForm(hospitals, state),
                                    const SizedBox(height: 20),
                                    _buildHospitalList(hospitals, state),
                                  ],
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateForm(List<Hospital> hospitals, AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.panel],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppColors.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
              SizedBox(width: 10),
              Text(
                'UPDATE RESOURCES',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Track hospital resource levels and keep inventory current.',
            style: TextStyle(color: AppColors.accent, fontSize: 13, height: 1.45),
          ),
          const SizedBox(height: 20),

          // Hospital selector
          const Text(
            'Select hospital',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedHospitalId,
            decoration: const InputDecoration(border: InputBorder.none),
            dropdownColor: AppColors.surface,
            hint: const Text(
              'Choose hospital',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            items: hospitals.map((hospital) {
              return DropdownMenuItem(
                value: hospital.id,
                child: Text(
                  hospital.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              final selected = hospitals.firstWhere((h) => h.id == value);
              setState(() {
                _selectedHospitalId = value;
                _selectedHospitalName = selected.name;
              });
            },
          ),
          const SizedBox(height: 20),

          // Resource fields (2 x 2 grid)
          Row(
            children: [
              Expanded(
                child: _buildNumberField(_bedsController, 'Beds', Icons.bed_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(_oxygenController, 'Oxygen', Icons.air),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(_icuController, 'ICU Beds', Icons.monitor_heart),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  _ventilatorController,
                  'Ventilators',
                  Icons.medical_services_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.sync, size: 16),
              label: Text(
                _isSaving ? 'Updating...' : 'Update Resources',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              onPressed: _isSaving ? null : () => _submitUpdate(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF4B5563), size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalList(List<Hospital> hospitals, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LIVE STATUS',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...hospitals.map(
          (hospital) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildHospitalRow(hospital, state),
          ),
        ),
      ],
    );
  }

  Widget _buildHospitalRow(Hospital hospital, AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: hospital.statusColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: hospital.statusColor.withOpacity(0.45),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (hospital.lastUpdated != null)
                      Text(
                        'Updated ${TimeUtils.formatRelativeTime(hospital.lastUpdated!)}',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hospital.statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hospital.statusLabel,
                      style: TextStyle(
                        color: hospital.statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  BufferTimeIndicator(
                    hours: hospital.criticalBufferHours,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ResourceBar(
            label: 'Beds',
            value: '${hospital.beds}',
            progress: hospital.bedsFraction,
            color: hospital.statusColor,
            icon: Icons.bed_outlined,
          ),
          const SizedBox(height: 12),
          ResourceBar(
            label: 'Oxygen',
            value: '${hospital.oxygen} units',
            progress: hospital.oxygenFraction,
            color: AppColors.info,
            icon: Icons.air,
          ),
          if (hospital.icuBeds > 0) ...[
            const SizedBox(height: 12),
            ResourceBar(
              label: 'ICU Beds',
              value: '${hospital.icuBeds}',
              progress: hospital.icuFraction,
              color: AppColors.warning,
              icon: Icons.monitor_heart,
            ),
          ],
          if (hospital.ventilators > 0) ...[
            const SizedBox(height: 12),
            ResourceBar(
              label: 'Ventilators',
              value: '${hospital.ventilators}',
              progress: hospital.ventilatorFraction,
              color: AppColors.purple,
              icon: Icons.medical_services_outlined,
            ),
          ],
        ],
      ),
    );
  }
}
