import 'package:flutter/material.dart';

class OrganizationRegisterScreen extends StatefulWidget {
  @override
  _OrganizationRegisterScreenState createState() => _OrganizationRegisterScreenState();
}

class _OrganizationRegisterScreenState extends State<OrganizationRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _orgNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  
  String _selectedCategory = 'Community';
  String _selectedOrgType = 'Non-Profit';
  bool _isVerified = false;

  final List<String> _categories = [
    'Community', 'Environment', 'Education', 'Health', 'Animals', 'Technology', 'Arts & Culture'
  ];

  final List<String> _orgTypes = [
    'Non-Profit', 'NGO', 'Government', 'Educational Institution', 'Religious Organization', 'Corporate'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Register Organization',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 32),
                _buildBasicInfo(),
                SizedBox(height: 24),
                _buildContactInfo(),
                SizedBox(height: 24),
                _buildOrganizationDetails(),
                SizedBox(height: 24),
                _buildVerificationSection(),
                SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.business,
            size: 48,
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            'Join VolunteerVibe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Register your organization to start posting volunteer opportunities',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _orgNameController,
            label: 'Organization Name',
            hint: 'Enter your organization name',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter organization name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildDropdown(
            label: 'Organization Type',
            value: _selectedOrgType,
            items: _orgTypes,
            onChanged: (value) => setState(() => _selectedOrgType = value!),
          ),
          SizedBox(height: 16),
          _buildDropdown(
            label: 'Primary Category',
            value: _selectedCategory,
            items: _categories,
            onChanged: (value) => setState(() => _selectedCategory = value!),
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _registrationNumberController,
            label: 'Registration Number',
            hint: 'Official registration number (if applicable)',
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'organization@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter email address';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+1 (555) 123-4567',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter phone number';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'Address',
            hint: 'Organization address',
            maxLines: 2,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter address';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _websiteController,
            label: 'Website (Optional)',
            hint: 'https://www.example.com',
            keyboardType: TextInputType.url,
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _contactPersonController,
            label: 'Contact Person',
            hint: 'Primary contact person name',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter contact person name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrganizationDetails() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organization Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Tell us about your organization and its mission',
            maxLines: 4,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter organization description';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: Color(0xFF6C63FF)),
              SizedBox(width: 8),
              Text(
                'Verification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'To ensure the safety and credibility of our platform, all organizations undergo a verification process.',
            style: TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          _buildVerificationStep('1', 'Submit application', true),
          _buildVerificationStep('2', 'Document review', false),
          _buildVerificationStep('3', 'Background check', false),
          _buildVerificationStep('4', 'Approval & activation', false),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF6C63FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Color(0xFF6C63FF), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Verification typically takes 3-5 business days',
                    style: TextStyle(
                      color: Color(0xFF6C63FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  Widget _buildVerificationStep(String number, String title, bool isActive) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? Color(0xFF6C63FF) : Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: isActive ? Colors.white : Color(0xFF718096),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isActive ? Color(0xFF2D3748) : Color(0xFF718096),
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
            filled: true,
            fillColor: Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red, width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.validate() ?? false) {
            _submitApplication();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF6C63FF),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Submit Application',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _submitApplication() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 40,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Application Submitted!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Thank you for your application. We will review it and get back to you within 3-5 business days.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF4A5568)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
