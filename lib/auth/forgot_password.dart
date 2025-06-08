import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart'; // Diperlukan untuk ClientException
import '../pocketbase_client.dart'; // Sesuaikan path jika perlu (tempat variabel 'pb' Anda berada)

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPassword> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // [BARU] State untuk menyimpan tipe akun yang dipilih
  bool _isOrganization = false; 

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // [DIMODIFIKASI] Fungsi ini sekarang menangani kedua tipe akun
  Future<void> _handleSendResetLink() async {
    final email = _emailController.text.trim();

    // Validasi email
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email';
      });
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // [BARU] Tentukan koleksi berdasarkan pilihan pengguna
    final collectionName = _isOrganization ? 'organization' : 'users';

    try {
      // [DIMODIFIKASI] Panggil PocketBase pada koleksi yang benar
      await pb.collection(collectionName).requestPasswordReset(email);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showSuccessDialog();

    } on ClientException catch (e) {
      if (!mounted) return;
      String specificMessage = 'Failed to send reset link.';
      
      if (e.statusCode == 404) {
        // [BARU] Pesan error yang lebih spesifik
        final accountType = _isOrganization ? 'Organization' : 'User';
        specificMessage = '$accountType with this email not found.';
      } else if (e.response.containsKey('message') && e.response['message'].toString().isNotEmpty) {
        specificMessage = e.response['message'].toString();
      } else if (e.response.containsKey('data')) {
        final errors = e.response['data'] as Map<String, dynamic>;
        if (errors.isNotEmpty) {
          final firstErrorField = errors.keys.first;
          final fieldErrorData = errors[firstErrorField];
          if (fieldErrorData is Map && fieldErrorData.containsKey('message')) {
            specificMessage = fieldErrorData['message'];
          }
        }
      }
      
      setState(() {
        _isLoading = false;
        _errorMessage = specificMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
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
                  color: const Color(0xFFF3AB3F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFFF3AB3F),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Check Your Email',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B384A),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We have sent a password reset link to\n${_emailController.text.trim()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF828282),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Tutup dialog
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop(); // Kembali ke halaman sebelumnya
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3AB3F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopSection(),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    // ... (Kode _buildTopSection Anda tidak berubah)
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.55,
            decoration: const BoxDecoration(
              color: Color(0xFF1B384A),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 24,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 80,
                  left: 50,
                  right: 50,
                  child: CustomPaint(
                    painter: CurvedLinesPainter(),
                    size: const Size(double.infinity, 60),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Hero(
                    tag: 'appLogoHero',
                    child: _buildLogo(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    // ... (Kode _buildLogo Anda tidak berubah)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 30,
          child: Stack(
            children: [
              Container(
                width: 24,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B384A),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3AB3F),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              Positioned(
                top: 9,
                right: 3,
                child: Container(
                  width: 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEB4335),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B384A),
                height: 1.0,
              ),
            ),
            Text(
              'Volunteer',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B384A),
                height: 1.0,
              ),
            ),
            Text(
              'Vibe',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B384A),
                height: 1.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    // ... (Kode _buildBottomSection Anda tidak berubah)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 32),
          const Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FORGOT',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B384A),
                  ),
                ),
                Text(
                  'PASSWORD?',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B384A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Don\'t worry! Select your account type, enter your email and we\'ll send you a reset link.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF828282),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildForm(),
          const SizedBox(height: 20),
          _buildSendButton(),
          const SizedBox(height: 20),
          _buildBackToLogin(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // [DIMODIFIKASI] Form sekarang berisi pilihan tipe akun
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // [BARU] Widget untuk memilih tipe akun
          _buildAccountTypeSwitcher(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFEB4335),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // [BARU] Widget untuk tombol pilihan User/Organization
  Widget _buildAccountTypeSwitcher() {
    return Center(
      child: Column(
        children: [
          const Text(
            'I am a...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF828282),
            ),
          ),
          const SizedBox(height: 8),
          ToggleButtons(
            isSelected: [!_isOrganization, _isOrganization],
            onPressed: (index) {
              setState(() {
                _isOrganization = (index == 1);
              });
            },
            borderRadius: BorderRadius.circular(12),
            fillColor: const Color(0xFF1B384A),
            selectedColor: Colors.white,
            color: const Color(0xFF1B384A),
            constraints: BoxConstraints(
              minHeight: 40.0,
              minWidth: (MediaQuery.of(context).size.width - 48 - 12) / 2,
            ),
            children: const [
              Text('User'),
              Text('Organization'),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    // ... (Kode _buildTextField Anda tidak berubah)
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF2),
        borderRadius: BorderRadius.circular(16),
        border: _errorMessage != null
            ? Border.all(color: const Color(0xFFEB4335).withOpacity(0.3), width: 1)
            : null,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (value) {
          if (_errorMessage != null) {
            setState(() {
              _errorMessage = null;
            });
          }
        },
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1B384A),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF828282),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          prefixIcon: const Icon(
            Icons.email_outlined,
            color: Color(0xFF828282),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    // ... (Kode _buildSendButton Anda tidak berubah, _handleSendResetLink sudah diupdate)
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSendResetLink,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF3AB3F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Send Reset Link',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildBackToLogin() {
    // ... (Kode _buildBackToLogin Anda tidak berubah)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.arrow_back_ios,
          color: Color(0xFF326789),
          size: 16,
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Text(
            'Back to Login',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF326789),
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

class CurvedLinesPainter extends CustomPainter {
  // ... (Kode CurvedLinesPainter Anda tidak berubah)
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF326789).withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.2, size.width, size.height * 0.5);

    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
        size.width * 0.5, size.height * 0.4, size.width, size.height * 0.7);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}