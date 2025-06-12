import 'package:adisyona/views/dashboard/admin_dashboard.dart';
import 'package:adisyona/views/super_admin/super_admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import 'subscription_expired_screen.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController(); // telefon ya da eposta
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final input = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (input.contains("@")) {
        // e-posta ise süper admin
        await authProvider.loginWithEmail(input, password);
      } else {
        // telefon ile giriş
        await authProvider.login(input, password);
      }

      final user = authProvider.user;

      if (user == null) {
        setState(() => _errorMessage = "Kullanıcı bulunamadı.");
        return;
      }

      if (user.role == "super_admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
        );
      } else if (user.role == "admin") {
        final isValid = await authProvider.isCompanyValid(user.companyId!);

        if (!isValid) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionExpiredScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        }
      } else {
        setState(() => _errorMessage = "Yetkisiz kullanıcı.");
      }
    } catch (e) {
      setState(() => _errorMessage = "Giriş hatası: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Adisyona",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Telefon veya E-posta",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Şifre",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _login(context),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Giriş Yap"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
