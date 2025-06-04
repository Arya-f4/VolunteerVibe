import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pocketbase/pocketbase.dart'; // For ClientException and PocketBase
// import '../pocketbase_client.dart'; // Jika Anda punya file konfigurasi PB terpisah
import 'login_page.dart'; // Pastikan ini mengarah ke LoginPage Anda

// Jika Anda tidak menggunakan pocketbase_client.dart, inisialisasi pb bisa langsung di sini
final pb = PocketBase('http://127.0.0.1:8090'); // Pastikan URL ini sesuai

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  bool _isInstagramLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      bool emailExists = false;
      try {
        await pb.collection('users').getFirstListItem('email = "${_emailController.text.trim()}"');
        emailExists = true;
      } on ClientException catch (e) {
        if (e.statusCode == 404) {
          emailExists = false;
        } else {
          throw e;
        }
      } catch (e) {
        throw Exception('Gagal memverifikasi email: ${e.toString()}');
      }

      if (emailExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email ini sudah terdaftar. Silakan gunakan email lain atau login.'),
          backgroundColor: Colors.orange,
        ));
        return;
      }

      final body = <String, dynamic>{
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
        "passwordConfirm": _confirmPasswordController.text.trim(),
        "name": _nameController.text.trim(),
      };
      final record = await pb.collection('users').create(body: body);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Registrasi berhasil untuk ${record.getStringValue('name')}! Silakan login.'),
        backgroundColor: Colors.green,
      ));
      Navigator.pushReplacement(context, SlideFadePageRoute(page: LoginPage()));
    } on ClientException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Registrasi gagal: ${(e.response['message']?.toString()) ?? e.toString()}';
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kesalahan registrasi: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testLaunchUrl() async {
    final Uri testUri = Uri.parse('https://google.com');
    print('Mencoba membuka URL tes: $testUri');
    if (await canLaunchUrl(testUri)) {
      print('Bisa membuka URL tes: $testUri');
      await launchUrl(testUri, mode: LaunchMode.externalApplication);
    } else {
      print('Tidak bisa membuka URL tes: $testUri');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak bisa membuka URL tes: $testUri')),
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    print('--- [_signInWithGoogle] Dimulai: _isGoogleLoading = true. Timestamp: ${DateTime.now()}');

    try {
      print('--- [_signInWithGoogle] Memulai OAuth2 dengan Google...');
      final authData = await pb.collection('users').authWithOAuth2(
        'google',
        (url) async {
          print('==============================================================');
          print('>>> URL Callback OAuth2 Google: $url');
          print('==============================================================');

          final uri = Uri.parse(url.toString());
          print('--- [_signInWithGoogle callback] URI yang diparsing: $uri');

          if (await canLaunchUrl(uri)) {
            print('--- [_signInWithGoogle callback] canLaunchUrl: true untuk $uri');
            bool launched;
            if (Platform.isAndroid || Platform.isIOS) {
              launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              launched = await launchUrl(uri, mode: LaunchMode.platformDefault, webOnlyWindowName: '_blank');
            }
            print('--- [_signInWithGoogle callback] launchUrl dipanggil: $launched');
            if (!launched) {
              throw 'Gagal membuka URL: $uri';
            }
          } else {
            print('--- [_signInWithGoogle callback] canLaunchUrl: false untuk $uri');
            throw 'Tidak bisa membuka URL: $uri';
          }
        },
      );

      if (!mounted) {
        print('--- [_signInWithGoogle] Widget tidak terpasang setelah authData diterima.');
        return;
      }

      print('--- [_signInWithGoogle] OAuth2 Sukses. Token: ${authData.token}, Record ID: ${authData.record?.id}');
      print('--- [_signInWithGoogle] authData.meta: ${authData.meta}');

      final bool isNewUser = authData.meta?['isNew'] == true;
      final userName = authData.record?.getStringValue('name') ??
          authData.meta?['name'] ??
          authData.record?.getStringValue('email') ??
          'Pengguna Google';

      pb.authStore.save(authData.token, authData.record);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isNewUser
            ? 'Registrasi Google berhasil! Selamat datang, $userName!'
            : 'Login Google berhasil! Selamat datang kembali, $userName!'),
        backgroundColor: Colors.green,
      ));

      if (isNewUser) {
        print('--- [_signInWithGoogle] Pengguna baru terdaftar: ${authData.record?.id}');
        Navigator.pushReplacement(context, SlideFadePageRoute(page: LoginPage()));
      } else {
        print('--- [_signInWithGoogle] Pengguna lama login: ${authData.record?.id}');
        Navigator.pushReplacement(context, SlideFadePageRoute(page: LoginPage()));
      }
    } catch (e, stackTrace) {
      if (!mounted) {
        print('--- [_signInWithGoogle] Widget tidak terpasang saat penanganan error.');
        return;
      }
      print('>>> ERROR di _signInWithGoogle: $e');
      print('>>> Stack Trace: $stackTrace');
      String errorMessage = 'Login/registrasi Google gagal: ${e.toString()}';
      if (e is ClientException) {
        print('>>> Detail ClientException: ${e.response}');
        print('>>> Error Asli: ${e.originalError}');
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
        print('--- [_signInWithGoogle] Finalisasi: _isGoogleLoading = false. Timestamp: ${DateTime.now()}');
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() => _isFacebookLoading = true);
    print('--- [_signInWithFacebook] Dimulai: _isFacebookLoading = true. Timestamp: ${DateTime.now()}');

    try {
      print('--- [_signInWithFacebook] Memulai OAuth2 dengan Facebook...');
      final authData = await pb.collection('users').authWithOAuth2(
        'facebook', // Provider
        (url) async {
          print('==============================================================');
          print('>>> URL Callback OAuth2 Facebook: $url');
          print('==============================================================');

          final uri = Uri.parse(url.toString());
          print('--- [_signInWithFacebook callback] URI yang diparsing: $uri');

          if (await canLaunchUrl(uri)) {
            print('--- [_signInWithFacebook callback] canLaunchUrl: true untuk $uri');
            bool launched;
            if (Platform.isAndroid || Platform.isIOS) {
              launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              launched = await launchUrl(uri, mode: LaunchMode.platformDefault, webOnlyWindowName: '_blank');
            }
            print('--- [_signInWithFacebook callback] launchUrl dipanggil: $launched');
            if (!launched) {
              throw 'Gagal membuka URL: $uri';
            }
          } else {
            print('--- [_signInWithFacebook callback] canLaunchUrl: false untuk $uri');
            throw 'Tidak bisa membuka URL: $uri';
          }
        },
      );

      if (!mounted) {
        print('--- [_signInWithFacebook] Widget tidak terpasang setelah authData diterima.');
        return;
      }

      print('--- [_signInWithFacebook] OAuth2 Sukses. Token: ${authData.token}, Record ID: ${authData.record?.id}');
      print('--- [_signInWithFacebook] authData.meta: ${authData.meta}');

      final bool isNewUser = authData.meta?['isNew'] == true;
      final userName = authData.record?.getStringValue('name') ??
          authData.meta?['name'] ??
          authData.record?.getStringValue('email') ??
          'Pengguna Facebook';

      pb.authStore.save(authData.token, authData.record);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isNewUser
            ? 'Registrasi Facebook berhasil! Selamat datang, $userName!'
            : 'Login Facebook berhasil! Selamat datang kembali, $userName!'),
        backgroundColor: Colors.green,
      ));

      if (isNewUser) {
        print('--- [_signInWithFacebook] Pengguna baru terdaftar: ${authData.record?.id}');
        Navigator.pushReplacement(context, SlideFadePageRoute(page: LoginPage()));
      } else {
        print('--- [_signInWithFacebook] Pengguna lama login: ${authData.record?.id}');
        Navigator.pushReplacement(context, SlideFadePageRoute(page: LoginPage()));
      }
    } catch (e, stackTrace) {
      if (!mounted) {
        print('--- [_signInWithFacebook] Widget tidak terpasang saat penanganan error.');
        return;
      }
      print('>>> ERROR di _signInWithFacebook: $e');
      print('>>> Stack Trace: $stackTrace');
      String errorMessage = 'Login/registrasi Facebook gagal: ${e.toString()}';
      if (e is ClientException) {
        print('>>> Detail ClientException: ${e.response}');
        print('>>> Error Asli: ${e.originalError}');
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
        print('--- [_signInWithFacebook] Finalisasi: _isFacebookLoading = false. Timestamp: ${DateTime.now()}');
        setState(() => _isFacebookLoading = false);
      }
    }
  }

  Future<void> _signInWithInstagram() async {
    setState(() => _isInstagramLoading = true);
    print('--- [_signInWithInstagram] Dimulai: _isInstagramLoading = true. Timestamp: ${DateTime.now()}');

    // PENTING:
    // PocketBase tidak secara default mendukung login Instagram langsung melalui
    // pb.collection('users').authWithOAuth2('instagram', ...) seperti provider lain.
    // Implementasi login Instagram biasanya memerlukan konfigurasi dan pendekatan yang berbeda.
    // Fungsi ini adalah placeholder.

    await Future.delayed(const Duration(seconds: 1)); // Simulasi proses

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Login dengan Instagram belum diimplementasikan sepenuhnya. Memerlukan konfigurasi khusus.'),
        backgroundColor: Colors.orange,
      ));
      print('--- [_signInWithInstagram] Placeholder: Fungsi login Instagram belum diimplementasikan sepenuhnya.');
      setState(() => _isInstagramLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              Hero(tag: 'appLogoHero', child: _buildLogo()),
              const SizedBox(height: 32),
              _buildIllustration(),
              const SizedBox(height: 48),
              _buildForm(),
              const SizedBox(height: 24),
              _buildSignupButton(),
              const SizedBox(height: 32),
              _buildSocialLogin(),
              const SizedBox(height: 24),
              _buildLoginLink(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 32,
          height: 40,
          child: Stack(
            children: [
              Container(
                width: 32,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B384A),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3AB3F),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 4,
                child: Container(
                  width: 12,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEB4335),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VV',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B384A),
                height: 1.0,
              ),
            ),
            Text(
              'Volunteer',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B384A),
                height: 1.0,
              ),
            ),
            Text(
              'Vibe',
              style: TextStyle(
                fontSize: 10,
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

  Widget _buildIllustration() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Image.asset(
        'assets/amico.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.image_not_supported_rounded,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'CREATE ACCOUNT',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B384A),
            ),
          ),
          const SizedBox(height: 32),
          _buildTextField(
            controller: _nameController,
            hintText: 'Name',
            keyboardType: TextInputType.name,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
              return null;
            },
          ),
          const SizedBox(height: 16),
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
              if (value.length < 8) return 'Password minimal 8 karakter';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm password',
            isPassword: true,
            showPassword: _showConfirmPassword,
            onTogglePassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Konfirmasi password tidak boleh kosong';
              if (value != _passwordController.text) return 'Password tidak cocok';
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
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF2),
        borderRadius: BorderRadius.circular(16),
      ),
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
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF828282),
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSignupButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF3AB3F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Signup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildSocialLogin() {
    return Column(
      children: [
        const Text(
          '-Or signup with-',
          style: TextStyle(fontSize: 16, color: Color(0xFF000000)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              isLoading: _isGoogleLoading,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Image.asset(
                  'assets/google-logo.png',
                  errorBuilder: (c, e, s) => const Icon(Icons.error, color: Colors.red),
                ),
              ),
              onPressed: _signInWithGoogle,
            ),
            const SizedBox(width: 24),
            _buildSocialButton(
              isLoading: _isFacebookLoading,
              backgroundColor: const Color(0xFF1877F2),
              child: const Icon(Icons.facebook, color: Colors.white, size: 24),
              onPressed: _signInWithFacebook,
            ),
            const SizedBox(width: 24),
            _buildSocialButton(
              isLoading: _isInstagramLoading,
              // Anda bisa menggunakan warna gradien Instagram jika mau,
              // tapi untuk simpelnya, bisa menggunakan putih (agar logo terlihat)
              // atau warna solid seperti pink/ungu.
              // Jika menggunakan backgroundColor putih, pastikan logo kontras.
              backgroundColor: Colors.white, // Atau warna lain seperti Color(0xFFE1306C)
              child: SizedBox( // Menggunakan SizedBox untuk mengatur ukuran logo jika perlu
                width: 24,
                height: 24,
                child: Image.asset(
                  'assets/instagram-logo.png', // Logo Instagram Anda
                  errorBuilder: (c,e,s) => const Icon(Icons.camera_alt_outlined, color: Colors.grey), // Fallback icon
                ),
              ),
              onPressed: _signInWithInstagram,
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        // Jika background button adalah putih atau null, gunakan warna primer gelap tema
                        // Jika tidak, gunakan putih untuk progress indicator agar kontras
                        (backgroundColor == Colors.white || backgroundColor == null)
                            ? Theme.of(context).primaryColorDark
                            : Colors.white,
                      ),
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: Color(0xFF000000)),
        children: [
          const TextSpan(text: 'Already have an account? '),
          WidgetSpan(
            child: GestureDetector(
              onTap: () => Navigator.pop(context), // Atau Navigator.pushReplacement jika lebih sesuai
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1B384A),
                  fontWeight: FontWeight.w500,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class SlideFadePageRoute extends PageRouteBuilder {
  final Widget page;
  SlideFadePageRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 300),
        );
}