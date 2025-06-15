import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pocketbase/pocketbase.dart';
import 'login_page.dart'; // Ensure this path is correct
import 'package:volunteervibe/pocketbase_client.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
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
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // State for account type
  bool _isOrganization = false; // Defaults to User (false)

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final collectionName = _isOrganization ? 'organization' : 'users';
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    
    try {
      // 1. Check if the email already exists
      bool emailExists = false;
      try {
        await pb.collection(collectionName).getFirstListItem('email = "$email"');
        emailExists = true;
      } on ClientException catch (e) {
        if (e.statusCode == 404) {
          emailExists = false;
        } else {
          rethrow;
        }
      }

      if (emailExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('This email is already registered. Please use another email.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        setState(() => _isLoading = false);
        return;
      }

      // 2. Prepare the body data
      final body = <String, dynamic>{
        "name": name,
        "email": email,
        "password": password,
        "passwordConfirm": _confirmPasswordController.text.trim(),
      };

      // 3. Create the new record
      final record = await pb.collection(collectionName).create(body: body);

      if (!mounted) return;

      // 4. Show a confirmation dialog on success
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Registration Successful'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('The account for \'${record.getStringValue('name')}\' has been successfully created.'),
                  const SizedBox(height: 8),
                  const Text('Please log in to continue.'),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); 
                  Navigator.pushReplacement(context, SlideFadePageRoute(page: const LoginPage()));
                },
              ),
            ],
          );
        },
      );
      
    } on ClientException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Registration failed: ${(e.response['message']?.toString()) ?? e.toString()}';
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
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('An error occurred: ${e.toString()}'),
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

  // --- Social Login Functions ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      await pb.collection('users').authWithOAuth2(
        'google', (url) async => await launchUrl(url),
      );
      if(mounted) {
          Navigator.pushReplacement(context, SlideFadePageRoute(page: const LoginPage()));
      }
    } catch(e) {
        // handle error
    } finally {
      if(mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
      setState(() => _isFacebookLoading = true);
      try {
        await pb.collection('users').authWithOAuth2(
          'facebook', (url) async => await launchUrl(url),
        );
        if(mounted) {
          Navigator.pushReplacement(context, SlideFadePageRoute(page: const LoginPage()));
        }
      } catch(e) {
        // handle error
      } finally {
        if(mounted) setState(() => _isFacebookLoading = false);
      }
  }
  
  Future<void> _signInWithInstagram() async {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Instagram login not implemented.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildIllustration(),
                const SizedBox(height: 32),
                _buildForm(),
                const SizedBox(height: 24),
                _buildSignupButton(),
                const SizedBox(height: 24),
                _buildLoginLink(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1B384A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Hero(tag: 'appLogoHero', child: _buildLogo()),
        const SizedBox(width: 48), // Balance the layout
      ],
    );
  }

  Widget _buildLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'VV',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B384A),
                height: 1.0,
              ),
            ),
            Text(
              'Volunteer',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B384A),
                height: 1.1,
              ),
            ),
            Text(
              'Vibe',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1B384A),
                height: 1.1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/amico.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEF2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.image_not_supported_rounded,
                size: 50,
                color: Colors.grey,
              ),
            ),
          ),
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
            'Create Your Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B384A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join our community and start volunteering',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          _buildAccountTypeSwitcher(),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _nameController,
            hintText: _isOrganization ? 'Organization Name' : 'Full Name',
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.name,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Name cannot be empty';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            hintText: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email cannot be empty';
              if (!value.contains('@') || !value.contains('.')) return 'Email format is not valid';
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
              if (value == null || value.isEmpty) return 'Password cannot be empty';
              if (value.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmPasswordController,
            hintText: 'Confirm Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            showPassword: _showConfirmPassword,
            onTogglePassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Confirm password cannot be empty';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeSwitcher() {
    return Container(
      height: 56,
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
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _isOrganization ? Alignment.centerRight : Alignment.centerLeft,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Container(
              width: (MediaQuery.of(context).size.width - 48 - 4) / 2, 
              height: 48,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B384A),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B384A).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isOrganization = false),
                  child: Container(
                    color: Colors.transparent, 
                    child: Center(
                      child: Text(
                        'User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: !_isOrganization ? Colors.white : Colors.black54,
                          fontSize: 16
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isOrganization = true),
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Text(
                        'Organization',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isOrganization ? Colors.white : Colors.black54,
                          fontSize: 16
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
    return Container(
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
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF828282),
                  ),
                  onPressed: onTogglePassword,
                )
              : null,
          errorStyle: const TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
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
                'Create Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialButton({
    Widget? child,
    Color? backgroundColor,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(27),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pushReplacement(
              SlideFadePageRoute(page: const LoginPage())
            ), 
            child: const Text(
              'Sign In',
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

// Helper for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Helper for page transition animation
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
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
          transitionDuration: const Duration(milliseconds: 400),
        );
}