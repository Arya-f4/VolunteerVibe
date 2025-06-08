import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pocketbase/pocketbase.dart'; 
import 'register_page.dart'; 
import 'forgot_password.dart'; 

final pb = PocketBase('http://127.0.0.1:8090');

// Kelas untuk transisi halaman kustom (Slide & Fade)
class SlideFadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideFadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final CurvedAnimation curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            const Offset beginSlide = Offset(1.0, 0.0);
            const Offset endSlide = Offset.zero;
            final Tween<Offset> slideTween = Tween(begin: beginSlide, end: endSlide);
            final Animation<Offset> slideAnimation = slideTween.animate(curvedAnimation);
            final Tween<double> fadeTween = Tween(begin: 0.0, end: 1.0);
            final Animation<double> fadeAnimation = fadeTween.animate(curvedAnimation);

            return FadeTransition(
              opacity: fadeAnimation,
              child: SlideTransition(
                position: slideAnimation,
                child: child,
              ),
            );
          },
        );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showPassword = false;
  bool _isLoading = false; // Untuk login form standar
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  bool _isInstagramLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Fungsi untuk navigasi ke halaman utama setelah login berhasil
  void _navigateToHome() {
    // Mengarahkan ke HomePage menggunakan transisi kustom setelah login berhasil.
    Navigator.pushReplacement(context, SlideFadePageRoute(page: const RegisterPage()));
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isGoogleLoading || _isFacebookLoading || _isInstagramLoading) return; // Jangan proses jika login sosial berjalan

    setState(() => _isLoading = true);

    try {
      final authData = await pb.collection('users').authWithPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login berhasil! Selamat datang kembali, ${authData.record?.getStringValue('name') ?? _emailController.text.trim()}!'),
        backgroundColor: Colors.green,
      ));
      _navigateToHome();
    } on ClientException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Login gagal: ${(e.response['message']?.toString()) ?? e.toString()}';
      if (e.statusCode == 400) {
        errorMessage = 'Email atau password salah. Silakan coba lagi.';
      } else if (e.response.containsKey('data') && e.response['data'] is Map) {
        final errors = e.response['data'] as Map<String, dynamic>;
        if (errors.isNotEmpty) {
          final firstErrorField = errors.keys.first;
          final fieldError = errors[firstErrorField];
          if (fieldError is Map && fieldError.containsKey('message')) {
            errorMessage = '${StringExtension(firstErrorField).capitalize()}: ${fieldError['message']}';
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Terjadi kesalahan: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithProvider(String provider) async {
    if (_isLoading) return; // Jangan proses jika login standar berjalan

    if (provider == 'google') setState(() => _isGoogleLoading = true);
    if (provider == 'facebook') setState(() => _isFacebookLoading = true);

    try {
      final authData = await pb.collection('users').authWithOAuth2(
        provider,
        (url) async {
          final uri = Uri.parse(url.toString());
          if (await canLaunchUrl(uri)) {
            bool launched;
            if (Platform.isAndroid || Platform.isIOS) {
              launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              launched = await launchUrl(uri, mode: LaunchMode.platformDefault, webOnlyWindowName: '_blank');
            }
            if (!launched) throw 'Gagal membuka URL: $uri';
          } else {
            throw 'Tidak bisa membuka URL: $uri';
          }
        },
      );

      if (!mounted) return;
      
      final userName = authData.record?.getStringValue('name') ??
          authData.meta?['name'] ??
          authData.record?.getStringValue('email') ??
          'Pengguna $provider';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login $provider berhasil! Selamat datang kembali, $userName!'),
        backgroundColor: Colors.green,
      ));
      _navigateToHome();
    } catch (e, stackTrace) {
      if (!mounted) return;
      String errorMessage = 'Login $provider gagal: ${e.toString()}';
      if (e is ClientException) {
        errorMessage = e.response['message']?.toString() ?? e.toString();
         if (e.response.containsKey('data') && e.response['data'] is Map) {
           final errors = e.response['data'] as Map<String, dynamic>;
           if (errors.isNotEmpty) {
             final firstErrorField = errors.keys.first;
             final fieldError = errors[firstErrorField];
             if (fieldError is Map && fieldError.containsKey('message')) {
               errorMessage = '${StringExtension(firstErrorField).capitalize()}: ${fieldError['message']}';
             }
           }
         }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
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
    
    await Future.delayed(const Duration(seconds: 1)); // Simulasi

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Login dengan Instagram belum diimplementasikan sepenuhnya.'),
        backgroundColor: Colors.orange,
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
          child: Column(
            children: [
              _buildTopSection(),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5, // Adjusted height
      child: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.45, // Adjusted height
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
                  bottom: 70, // Adjusted position
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
                width: 100, // Adjusted size
                height: 100, // Adjusted size
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
                    child: _buildLogo(scale: 0.8), // Slightly smaller logo
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo({double scale = 1.0}) { // Added scale parameter
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
                  top: 3, right: 3,
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFFF3AB3F), borderRadius: BorderRadius.circular(1))),
                ),
                Positioned(
                  top: 9, right: 3,
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
          const SizedBox(height: 30), // Adjusted spacing
          const Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HEY!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B384A))), // Adjusted size
                Text('LOGIN NOW', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1B384A))), // Adjusted size
              ],
            ),
          ),
          const SizedBox(height: 24), // Adjusted spacing
          _buildForm(),
          const SizedBox(height: 20), // Adjusted spacing
          _buildLoginButton(),
          const SizedBox(height: 12), // Adjusted spacing
          _buildForgotPassword(),
          const SizedBox(height: 24), // Adjusted spacing
          _buildSocialLogin(),
          const SizedBox(height: 20), // Adjusted spacing
          _buildRegisterLink(),
          const SizedBox(height: 24), // Adjusted spacing
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
    TextInputType? keyboardType,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(color: const Color(0xFFE9EEF2), borderRadius: BorderRadius.circular(16)),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && !showPassword,
        validator: validator,
        style: const TextStyle(fontSize: 16, color: Color(0xFF828282)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF828282), fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF828282)),
                  onPressed: onTogglePassword,
                )
              : null,
        ),
      ),
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
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => Navigator.push(context, SlideFadePageRoute(page: ForgotPassword())),
        child: const Text('Forgot password?', style: TextStyle(fontSize: 16, color: Color(0xFF326789), decoration: TextDecoration.underline)),
      ),
    );
  }

  Widget _buildSocialLogin() {
    bool anyLoadingInProgress = _isLoading || _isGoogleLoading || _isFacebookLoading || _isInstagramLoading;
    return Column(
      children: [
        const Text('-Or login with-', style: TextStyle(fontSize: 16, color: Color(0xFF000000))),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              isLoading: _isGoogleLoading,
              onPressed: anyLoadingInProgress && !_isGoogleLoading ? (){} : () => _signInWithProvider('google'),
              child: Image.asset('assets/google-logo.png', width: 24, height: 24, errorBuilder: (c,e,s) => const Icon(Icons.error, color: Colors.red)),
            ),
            const SizedBox(width: 24),
            _buildSocialButton(
              isLoading: _isFacebookLoading,
              onPressed: anyLoadingInProgress && !_isFacebookLoading ? (){} : () => _signInWithProvider('facebook'),
              backgroundColor: const Color(0xFF1877F2),
              child: const Icon(Icons.facebook, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 24),
            _buildSocialButton(
              isLoading: _isInstagramLoading,
              onPressed: anyLoadingInProgress && !_isInstagramLoading ? (){} : _signInWithInstagram,
              child: Image.asset('assets/instagram-logo.png', width: 24, height: 24, errorBuilder: (c,e,s) => const Icon(Icons.camera_alt_outlined, color: Colors.grey)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    Widget? child,
    Color? backgroundColor,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: isLoading
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation<Color>((backgroundColor == Colors.white || backgroundColor == null) ? Theme.of(context).primaryColorDark : Colors.white)))
                : child,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
        children: [
          const TextSpan(text: 'Don\'t have an account? '),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => Navigator.push(context, SlideFadePageRoute(page: const RegisterPage())),
              child: const Text('Create new', style: TextStyle(fontSize: 16, color: Color(0xFF326789), fontWeight: FontWeight.w500, decoration: TextDecoration.underline)),
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
    final paint = Paint()..color = const Color(0xFF326789).withOpacity(0.3)..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.2, size.width, size.height * 0.5);
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0.7);
    canvas.drawPath(path, paint);
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