import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pocketbase/pocketbase.dart';

// Halaman-halaman lain yang di-import
import 'register_page.dart';
import 'forgot_password.dart';
import 'package:volunteervibe/screens/home_screen.dart';
import 'package:volunteervibe/screens/organization_dashboard.dart';

// Import file pocketbase_client.dart untuk menggunakan instance pb global.
import 'package:volunteervibe/pocketbase_client.dart';

// Kelas untuk transisi halaman kustom (Slide & Fade)
class SlideFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideFadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
            final slideAnimation = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(curvedAnimation);
            final fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(curvedAnimation);
            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(position: slideAnimation, child: child),
            );
          },
        );
}

// Enum untuk membedakan jenis pengguna
enum UserType { user, organization }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _showPassword = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  bool _isInstagramLoading = false;

  UserType _selectedUserType = UserType.user;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isGoogleLoading || _isFacebookLoading || _isInstagramLoading) return;

    setState(() => _isLoading = true);

    final collection = _selectedUserType == UserType.user ? 'users' : 'organization';

    try {
      final authData = await pb.collection(collection).authWithPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      if (!mounted) return;

      final recordName = authData.record?.getStringValue('name') ?? _emailController.text.trim();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login berhasil! Selamat datang kembali, $recordName!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

      if (_selectedUserType == UserType.user) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/organization');
      }
    } on ClientException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Login gagal: ${(e.response['message']?.toString()) ?? e.toString()}';
      if (e.statusCode == 400) {
        errorMessage = 'Email atau password salah. Silakan coba lagi.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: ${e.toString()}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithProvider(String provider) async {
    if (_isLoading) return;

    if (provider == 'google') setState(() => _isGoogleLoading = true);
    if (provider == 'facebook') setState(() => _isFacebookLoading = true);

    try {
      final authData = await pb.collection('users').authWithOAuth2(
        provider,
        (url) async {
          final uri = Uri.parse(url.toString());
          if (await canLaunchUrl(uri)) {
            final mode = Platform.isAndroid || Platform.isIOS ? LaunchMode.externalApplication : LaunchMode.platformDefault;
            if (!await launchUrl(uri, mode: mode)) throw 'Gagal membuka URL: $uri';
          } else {
            throw 'Tidak bisa membuka URL: $uri';
          }
        },
      );

      if (!mounted) return;

      final userName = authData.record?.getStringValue('name') ?? authData.meta?['name'] ?? 'Pengguna $provider';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login $provider berhasil! Selamat datang kembali, $userName!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login $provider gagal: ${e.toString()}'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) {
        if (provider == 'google') setState(() => _isGoogleLoading = false);
        if (provider == 'facebook') setState(() => _isFacebookLoading = false);
      }
    }
  }

  Future<void> _signInWithInstagram() async {
    if (_isLoading || _isGoogleLoading || _isFacebookLoading) return;
    setState(() => _isInstagramLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Login dengan Instagram belum diimplementasikan.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      setState(() => _isInstagramLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildTopSection(),
                _buildBottomSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      child: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1B384A), Color(0xFF326789)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.05,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                            color: Colors.black.withOpacity(0.25),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 70,
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
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Hero(
                    tag: 'appLogoHero',
                    child: _buildLogo(scale: 0.9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo({double scale = 1.0}) {
    return Transform.scale(
      scale: scale,
      child: Row(
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
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFFF3AB3F), borderRadius: BorderRadius.circular(1))),
                ),
                Positioned(
                  top: 9,
                  right: 3,
                  child: Container(width: 8, height: 6, decoration: BoxDecoration(color: const Color(0xFFEB4335), borderRadius: BorderRadius.circular(1))),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('VV', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B384A), height: 1.0)),
              Text('Volunteer', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: Color(0xFF1B384A), height: 1.0)),
              Text('Vibe', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, color: Color(0xFF1B384A), height: 1.0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.center,
            child: Text(
              'Sign In to Your Account',
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF1B384A),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildUserTypeSelector(),
          const SizedBox(height: 24),
          _buildForm(),
          const SizedBox(height: 20),
          _buildLoginButton(),
          const SizedBox(height: 12),
          _buildForgotPassword(),
          const SizedBox(height: 24),
          _buildRegisterLink(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ToggleButtons(
        isSelected: [
          _selectedUserType == UserType.user,
          _selectedUserType == UserType.organization,
        ],
        onPressed: (index) {
          setState(() {
            _selectedUserType = (index == 0) ? UserType.user : UserType.organization;
          });
        },
        color: const Color(0xFF828282),
        selectedColor: Colors.white,
        fillColor: const Color(0xFF1B384A),
        splashColor: const Color(0xFF1B384A).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        borderWidth: 0,
        renderBorder: false,
        constraints: BoxConstraints.expand(width: (MediaQuery.of(context).size.width / 2) - 25, height: 48),
        children: const [
          Text('User', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Organization', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
              if (!value.contains('@') || !value.contains('.')) return 'Format email tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            showPassword: _showPassword,
            onTogglePassword: () => setState(() => _showPassword = !_showPassword),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFE9EEF2),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: isPassword && !showPassword,
            validator: validator,
            style: const TextStyle(fontSize: 16, color: Color(0xFF4A4A4A)),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFF828282), fontSize: 16),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              prefixIcon: prefixIcon != null 
                  ? Icon(prefixIcon, color: const Color(0xFF828282))
                  : null,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF828282)),
                      onPressed: onTogglePassword,
                    )
                  : null,
              errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Builder(
          builder: (context) {
            final formField = context.findAncestorWidgetOfExactType<TextFormField>();
            if (formField == null) return const SizedBox.shrink();
            final errorText = formField.validator?.call(controller.text);
            return errorText != null && errorText.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Text(
                      errorText,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    bool anyLoadingInProgress = _isLoading || _isGoogleLoading || _isFacebookLoading || _isInstagramLoading;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: anyLoadingInProgress ? null : _loginUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF3AB3F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          shadowColor: const Color(0xFFF3AB3F).withOpacity(0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: () => Navigator.push(context, SlideFadePageRoute(page: ForgotPassword())),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF326789),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text(
          'Forgot password?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Don\'t have an account? ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context, SlideFadePageRoute(page: const RegisterPage())),
            child: const Text(
              'Sign Up',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF326789),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurvedLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    final path1 = Path();
    path1.moveTo(0, size.height * 0.5);
    path1.quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width, size.height * 0.5);
    
    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0.7);
    
    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}