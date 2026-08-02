import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_models.dart';
import '../services/cambric_auth_service_v2.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final List<String> missingFields;
  final VoidCallback? onComplete;
  
  const ProfileCompletionScreen({
    super.key,
    required this.missingFields,
    this.onComplete,
  });
  
  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
  // Values
  String _gender = 'male';
  String? _bloodType;
  List<String> _medicalConditions = [];
  List<String> _allergies = [];
  
  bool _isLoading = false;
  
  final List<String> _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'
  ];
  
  final List<String> _commonConditions = [
    'Diabetes',
    'Hypertension',
    'Heart Disease',
    'Asthma',
    'COPD',
    'Arthritis',
    'Cancer',
    'Kidney Disease',
    'Stroke History',
    'Epilepsy',
  ];
  
  final List<String> _commonAllergies = [
    'Penicillin',
    'Sulfa Drugs',
    'Aspirin',
    'Ibuprofen',
    'Latex',
    'Peanuts',
    'Shellfish',
    'Eggs',
    'Milk',
    'Soy',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }
  
  Future<void> _loadExistingProfile() async {
    final auth = context.read<AuthProvider>();
    if (auth.user != null) {
      try {
        final result = await Supabase.instance.client
            .from('digital_saver_user_profiles')
            .select()
            .eq('id', auth.user!.id)
            .maybeSingle();
        
        if (result != null && mounted) {
          setState(() {
            final profile = UserProfile.fromSupabase(result);
            _nameController.text = profile.name;
            _ageController.text = profile.age > 0 ? profile.age.toString() : '';
            _weightController.text = profile.weightKg > 0 ? profile.weightKg.toStringAsFixed(0) : '';
            _heightController.text = profile.heightCm > 0 ? profile.heightCm.toStringAsFixed(0) : '';
            _gender = profile.gender;
            _bloodType = profile.bloodType;
            _emergencyNameController.text = profile.emergencyContactName ?? '';
            _emergencyPhoneController.text = profile.emergencyContactPhone ?? '';
            _medicalConditions = List.from(profile.medicalConditions);
            _allergies = List.from(profile.allergies);
          });
        }
      } catch (e) {
        debugPrint('Error loading profile: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final auth = context.read<AuthProvider>();
      if (auth.user == null) {
        _showError('Not signed in');
        return;
      }
      
      final profileData = {
        'id': auth.user!.id,
        'display_name': _nameController.text.trim(),
        'email': auth.user!.email,
        'age': int.tryParse(_ageController.text) ?? 30,
        'weight_kg': double.tryParse(_weightController.text) ?? 70,
        'height_cm': double.tryParse(_heightController.text) ?? 170,
        'gender': _gender,
        'blood_type': _bloodType,
        'medical_conditions': _medicalConditions,
        'allergies': _allergies,
        'emergency_contact_name': _emergencyNameController.text.trim(),
        'emergency_contact_phone': _emergencyPhoneController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await Supabase.instance.client
          .from('digital_saver_user_profiles')
          .upsert(profileData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        widget.onComplete?.call();
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      _showError('Failed to save profile');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header Card
            _buildHeaderCard(),
            const SizedBox(height: 16),
            
            // Basic Info Section
            _buildSectionTitle('Basic Information', Icons.person),
            _buildCard([
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                required: widget.missingFields.contains('name'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(
                    controller: _ageController,
                    label: 'Age',
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return widget.missingFields.contains('age') ? 'Required' : null;
                      final age = int.tryParse(v);
                      if (age == null || age < 1 || age > 150) return 'Invalid age';
                      return null;
                    },
                    required: widget.missingFields.contains('age'),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _buildGenderSelector())),
                ],
              ),
            ]),
            const SizedBox(height: 16),
            
            // Physical Stats Section
            _buildSectionTitle('Physical Statistics', Icons.straighten),
            _buildCard([
              Row(
                children: [
                  Expanded(child: _buildTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return widget.missingFields.contains('weight') ? 'Required' : null;
                      final w = double.tryParse(v);
                      if (w == null || w < 1 || w > 500) return 'Invalid';
                      return null;
                    },
                    required: widget.missingFields.contains('weight'),
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(
                    controller: _heightController,
                    label: 'Height (cm)',
                    icon: Icons.height,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return widget.missingFields.contains('height') ? 'Required' : null;
                      final h = double.tryParse(v);
                      if (h == null || h < 1 || h > 300) return 'Invalid';
                      return null;
                    },
                    required: widget.missingFields.contains('height'),
                  )),
                ],
              ),
              const SizedBox(height: 16),
              _buildBloodTypeSelector(),
            ]),
            const SizedBox(height: 16),
            
            // Emergency Contact Section
            _buildSectionTitle('Emergency Contact', Icons.emergency),
            _buildCard([
              _buildTextField(
                controller: _emergencyNameController,
                label: 'Contact Name',
                icon: Icons.contact_emergency_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                required: widget.missingFields.contains('emergencyContact'),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emergencyPhoneController,
                label: 'Contact Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return widget.missingFields.contains('emergencyPhone') ? 'Required' : null;
                  return null;
                },
                required: widget.missingFields.contains('emergencyPhone'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This contact will be notified in case of emergency',
                        style: TextStyle(fontSize: 12, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),
            
            // Medical Info Section
            _buildSectionTitle('Medical Information (Optional)', Icons.medical_services),
            _buildCard([
              _buildChipSelector(
                label: 'Medical Conditions',
                items: _commonConditions,
                selected: _medicalConditions,
                onChanged: (v) => setState(() => _medicalConditions = v),
              ),
              const SizedBox(height: 16),
              _buildChipSelector(
                label: 'Allergies',
                items: _commonAllergies,
                selected: _allergies,
                onChanged: (v) => setState(() => _allergies = v),
              ),
            ]),
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save),
                          SizedBox(width: 8),
                          Text(
                            'Save Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.person_add, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Complete Your Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide the following information to ensure we can help you in case of an emergency.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${widget.missingFields.length} fields to complete',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _gender,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Male')),
                DropdownMenuItem(value: 'female', child: Text('Female')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'male'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Blood Type',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _bloodTypes.map((type) {
            final isSelected = _bloodType == type;
            return GestureDetector(
              onTap: () => setState(() => _bloodType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChipSelector({
    required String label,
    required List<String> items,
    required List<String> selected,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E3A5F),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final isSelected = selected.contains(item);
            return GestureDetector(
              onTap: () {
                final newList = List<String>.from(selected);
                if (isSelected) {
                  newList.remove(item);
                } else {
                  newList.add(item);
                }
                onChanged(newList);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF22C55E).withOpacity(0.1) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 16),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      item,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF22C55E) : const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
