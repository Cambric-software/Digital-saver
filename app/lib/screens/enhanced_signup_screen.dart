import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/cambric_auth_service_v2.dart';
import '../services/profile_service.dart';

class EnhancedSignupScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  
  const EnhancedSignupScreen({super.key, this.onComplete});

  @override
  State<EnhancedSignupScreen> createState() => _EnhancedSignupScreenState();
}

class _EnhancedSignupScreenState extends State<EnhancedSignupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Form data
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  
  String _gender = 'male';
  String _bloodType = '';
  List<String> _medicalConditions = [];
  List<String> _allergies = [];
  List<String> _medications = [];
  
  bool _showPassword = false;
  bool _isLoading = false;
  String _errorMessage = '';
  
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  
  final List<String> _commonConditions = [
    'None',
    'Diabetes',
    'Hypertension',
    'Heart Disease',
    'Asthma',
    'Arthritis',
    'Depression/Anxiety',
    'Thyroid Disorder',
    'Kidney Disease',
    'Liver Disease',
  ];
  
  final List<String> _commonAllergies = [
    'None',
    'Penicillin',
    'Sulfa Drugs',
    'Aspirin',
    'Ibuprofen',
    'Latex',
    'Peanuts',
    'Shellfish',
    'Eggs',
    'Milk',
  ];
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  bool _validatePage(int page) {
    switch (page) {
      case 0:
        if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
          setState(() => _errorMessage = 'Please fill in all required fields');
          return false;
        }
        if (_passwordController.text != _confirmController.text) {
          setState(() => _errorMessage = 'Passwords do not match');
          return false;
        }
        if (_passwordController.text.length < 6) {
          setState(() => _errorMessage = 'Password must be at least 6 characters');
          return false;
        }
        return true;
      case 1:
        if (_ageController.text.isEmpty || _heightController.text.isEmpty || _weightController.text.isEmpty) {
          setState(() => _errorMessage = 'Please fill in age, height, and weight');
          return false;
        }
        final age = int.tryParse(_ageController.text);
        if (age == null || age < 1 || age > 120) {
          setState(() => _errorMessage = 'Please enter a valid age');
          return false;
        }
        return true;
      case 2:
        if (_emergencyNameController.text.isEmpty || _emergencyPhoneController.text.isEmpty) {
          setState(() => _errorMessage = 'Please add at least one emergency contact');
          return false;
        }
        return true;
      default:
        return true;
    }
  }
  
  Future<void> _handleSignUp() async {
    if (_isLoading) return;
    
    if (!_validatePage(0) || !_validatePage(1) || !_validatePage(2)) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final auth = context.read<AuthProvider>();
      
      // Step 1: Create account
      final success = await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      
      if (!success) {
        setState(() {
          _isLoading = false;
          _errorMessage = auth.error ?? 'Sign up failed. Please try again.';
        });
        return;
      }
      
      // Step 2: Update profile with health data
      await ProfileService().updateHealthProfile(
        displayName: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        gender: _gender,
        heightCm: double.parse(_heightController.text),
        weightKg: double.parse(_weightController.text),
        bloodType: _bloodType.isEmpty ? null : _bloodType,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        emergencyContactName: _emergencyNameController.text,
        emergencyContactPhone: _emergencyPhoneController.text,
        medicalConditions: _medicalConditions.where((c) => c != 'None').toList(),
        allergies: _allergies.where((a) => a != 'None').toList(),
        medications: _medications.where((m) => m.isNotEmpty).toList(),
      );
      
      if (mounted) {
        widget.onComplete?.call();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A5F), Color(0xFF2563EB), Color(0xFF7C3AED)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    _buildBasicInfoPage(),
                    _buildHealthInfoPage(),
                    _buildEmergencyPage(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    final titles = [
      'Create Account',
      'Health Profile',
      'Emergency Contact',
    ];
    final subtitles = [
      'Join the Cambric ecosystem',
      'Help us personalize your care',
      'For your safety',
    ];
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentPage > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _previousPage,
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Text(
                  titles[_currentPage],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitles[_currentPage],
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        children: List.generate(3, (index) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: index <= _currentPage ? Colors.white : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(_emailController, 'Email *', Icons.email_outlined, TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField(_nameController, 'Full Name *', Icons.person_outlined, TextInputType.name),
          const SizedBox(height: 16),
          _buildTextField(_phoneController, 'Phone (optional)', Icons.phone_outlined, TextInputType.phone),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 16),
          _buildPasswordField(confirm: true),
          const SizedBox(height: 16),
          if (_errorMessage.isNotEmpty && _currentPage == 0) _buildErrorBox(),
        ],
      ),
    );
  }
  
  Widget _buildHealthInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Age
          _buildTextField(_ageController, 'Age *', Icons.cake_outlined, TextInputType.number, 
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          
          // Gender
          const Text('Gender', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildGenderChip('Male', Icons.male, _gender == 'male', () => setState(() => _gender = 'male')),
              const SizedBox(width: 12),
              _buildGenderChip('Female', Icons.female, _gender == 'female', () => setState(() => _gender = 'female')),
              const SizedBox(width: 12),
              _buildGenderChip('Other', Icons.transgender, _gender == 'other', () => setState(() => _gender = 'other')),
            ],
          ),
          const SizedBox(height: 16),
          
          // Height and Weight
          Row(
            children: [
              Expanded(child: _buildTextField(_heightController, 'Height (cm) *', Icons.height, TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_weightController, 'Weight (kg) *', Icons.monitor_weight_outlined, TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          
          // Blood Type
          const Text('Blood Type', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _bloodTypes.map((bt) {
              final isSelected = _bloodType == bt;
              return ChoiceChip(
                label: Text(bt),
                selected: isSelected,
                onSelected: (selected) => setState(() => _bloodType = selected ? bt : ''),
                selectedColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                labelStyle: TextStyle(color: isSelected ? Colors.blue : Colors.white),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Medical Conditions
          _buildMultiSelectSection('Medical Conditions', _commonConditions, _medicalConditions, (c) => setState(() { if (_medicalConditions.contains(c)) { _medicalConditions.remove(c); } else { _medicalConditions.add(c); } }), icon: Icons.medical_services_outlined),
          const SizedBox(height: 16),
          
          // Allergies
          _buildMultiSelectSection('Allergies', _commonAllergies, _allergies, (a) => setState(() { if (_allergies.contains(a)) { _allergies.remove(a); } else { _allergies.add(a); } }), icon: Icons.warning_outlined),
          const SizedBox(height: 16),
          
          if (_errorMessage.isNotEmpty && _currentPage == 1) _buildErrorBox(),
        ],
      ),
    );
  }
  
  Widget _buildEmergencyPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'In an emergency, we will contact this person and share your health data to get you help faster.',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(_emergencyNameController, 'Contact Name *', Icons.person_outlined, TextInputType.name),
          const SizedBox(height: 16),
          _buildTextField(_emergencyPhoneController, 'Contact Phone *', Icons.phone, TextInputType.phone),
          const SizedBox(height: 24),
          if (_errorMessage.isNotEmpty && _currentPage == 2) _buildErrorBox(),
          
          // Medical Summary
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your Health Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _summaryRow('Name', _nameController.text.isEmpty ? '-' : _nameController.text),
                _summaryRow('Age', '${_ageController.text} years'),
                _summaryRow('Gender', _gender.capitalize()),
                _summaryRow('Blood Type', _bloodType.isEmpty ? 'Not set' : _bloodType),
                _summaryRow('BMI Data', '${_heightController.text}cm / ${_weightController.text}kg'),
                _summaryRow('Conditions', _medicalConditions.isEmpty ? 'None' : _medicalConditions.join(', ')),
                _summaryRow('Allergies', _allergies.isEmpty ? 'None' : _allergies.join(', ')),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
          Flexible(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ],
      ),
    );
  }
  
  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () {
                if (_validatePage(_currentPage)) {
                  if (_currentPage < 2) {
                    _nextPage();
                  } else {
                    _handleSignUp();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_currentPage < 2 ? 'Continue' : 'Create Account'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, TextInputType keyboardType, {List<TextInputFormatter>? inputFormatters}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }
  
  Widget _buildPasswordField({bool confirm = false}) {
    return TextField(
      controller: confirm ? _confirmController : _passwordController,
      obscureText: !_showPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: confirm ? 'Confirm Password *' : 'Password *',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(Icons.lock_outlined, color: Colors.white.withOpacity(0.7)),
        suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white.withOpacity(0.7)),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }
  
  Widget _buildGenderChip(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.blue : Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.blue : Colors.white,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMultiSelectSection(String title, List<String> options, List<String> selected, Function(String) onToggle, {IconData? icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white.withOpacity(0.7), size: 18),
              const SizedBox(width: 8),
            ],
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selected.contains(opt);
            return FilterChip(
              label: Text(opt, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => onToggle(opt),
              selectedColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
              labelStyle: TextStyle(color: isSelected ? Colors.blue : Colors.white),
              checkmarkColor: Colors.blue,
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildErrorBox() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
