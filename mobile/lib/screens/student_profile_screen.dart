import 'package:flutter/material.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Dummy Data Controllers
  final _phoneController = TextEditingController(text: '9876543210');
  final _emailController = TextEditingController(text: 'surya.s@example.com');
  final _addressController = TextEditingController(text: '123, Gandhi Road, Chennai');
  final _cityController = TextEditingController(text: 'Chennai');
  final _parentNameController = TextEditingController(text: 'Suresh Kumar');
  final _parentPhoneController = TextEditingController(text: '9876543211');
  final _emergencyPhoneController = TextEditingController(text: '9876543212');

  String? _selectedBloodGroup = 'O+';

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      // Simulate save
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      // Print data to console as requested
      debugPrint('Saving Profile:');
      debugPrint('Phone: ${_phoneController.text}');
      debugPrint('Email: ${_emailController.text}');
      debugPrint('Address: ${_addressController.text}');
      debugPrint('City: ${_cityController.text}');
      debugPrint('Parent: ${_parentNameController.text}');
      debugPrint('Blood Group: $_selectedBloodGroup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSectionTitle('Contact Details'),
              _buildTextField('Phone Number', _phoneController, keyboardType: TextInputType.phone, validator: (v) => v?.isEmpty == true ? 'Required' : null),
              _buildTextField('Email', _emailController, keyboardType: TextInputType.emailAddress, validator: (v) => v?.contains('@') == false ? 'Invalid email' : null),
              _buildTextField('Address', _addressController, maxLines: 3),
              _buildTextField('City', _cityController),
              const SizedBox(height: 16),
              _buildSectionTitle('Personal Details'),
              _buildDropdown('Blood Group', _bloodGroups, _selectedBloodGroup, (v) => setState(() => _selectedBloodGroup = v)),
              const SizedBox(height: 16),
              _buildSectionTitle('Parent / Guardian Details'),
              _buildTextField('Parent Name', _parentNameController),
              _buildTextField('Parent Phone', _parentPhoneController, keyboardType: TextInputType.phone),
              _buildTextField('Emergency Contact (Optional)', _emergencyPhoneController, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              _buildAcademicSummary(),
              const SizedBox(height: 32),
              _buildActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              'S',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Surya S',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '21CS001',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          Text(
            'CSE - III Year',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAcademicSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Academic Summary (Read-Only)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('CGPA', '7.6'),
              _buildSummaryItem('Attendance', '82%'),
              _buildSummaryItem('Activities', '05'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }
}
