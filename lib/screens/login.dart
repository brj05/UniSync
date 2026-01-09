import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import 'interest.dart';
import 'home_shell.dart';
enum LoginRole { student, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authService = AuthService();

  final phoneController = TextEditingController();
  final rollController = TextEditingController();
  final passwordController = TextEditingController();

  LoginRole selectedRole = LoginRole.student;
  bool loading = false;

  String normalizePhone(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }

  Future<void> login() async {
    setState(() => loading = true);

    final phone = normalizePhone(phoneController.text.trim());

    bool success = false;

    /// ================= STUDENT LOGIN =================
    if (selectedRole == LoginRole.student) {
      final roll = rollController.text.trim();
      success = await authService.verifyStudent(phone, roll);

      if (!success) {
        _stopWithError();
        return;
      }

      /// SAVE SESSION
      await SessionService.saveSession(
        role: 'student',
        phone: phone,
      );

      /// CHECK IF INTERESTS ALREADY SELECTED
      final hasInterests =
          await authService.hasSelectedInterests(phone);

      setState(() => loading = false);
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              hasInterests
                  ? const HomeShell() // create later
                  : InterestSelectionScreen(phone: phone),
        ),
      );
    }

    /// ================= ADMIN LOGIN =================
    else {
      final password = passwordController.text.trim();
      success = await authService.verifyAdmin(phone, password);

      if (!success) {
        _stopWithError();
        return;
      }

      /// SAVE SESSION
      await SessionService.saveSession(
        role: 'admin',
        phone: phone,
      );

      setState(() => loading = false);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin login successful')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    }
  }

  void _stopWithError() {
    setState(() => loading = false);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Access denied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFFF6EC);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 40),

              /// LOGO
              Image.asset(
                'assets/images/unisync_logo.png',
                height: 110,
              ),

              const SizedBox(height: 40),

              /// ROLE SELECTOR
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _roleButton(
                      label: 'Student',
                      icon: Icons.school,
                      role: LoginRole.student,
                    ),
                    _roleButton(
                      label: 'Admin',
                      icon: Icons.admin_panel_settings,
                      role: LoginRole.admin,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              /// PHONE
              _inputField(
                controller: phoneController,
                hint: 'Phone number',
                keyboard: TextInputType.phone,
              ),

              const SizedBox(height: 14),

              /// STUDENT FIELD
              if (selectedRole == LoginRole.student)
                _inputField(
                  controller: rollController,
                  hint: 'Roll number',
                ),

              /// ADMIN FIELD
              if (selectedRole == LoginRole.admin)
                _inputField(
                  controller: passwordController,
                  hint: 'Password',
                  obscure: true,
                ),

              const SizedBox(height: 40),

              /// LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B4EFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// ROLE BUTTON
  Widget _roleButton({
    required String label,
    required IconData icon,
    required LoginRole role,
  }) {
    final selected = selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF7B4EFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.black54,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// INPUT FIELD
  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
