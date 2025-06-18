import 'package:adisyona/views/dashboard/admin_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../super_admin/super_admin_dashboard.dart';
import 'subscription_expired_screen.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final identifier = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen tüm alanları doldurun."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final result = await authProvider.signIn(identifier, password);

    if (!mounted) return;

    // Başarılı giriş sonrası yönlendirme
    switch (result) {
      case AuthResult.success:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardMenu()),
        );
        break;
      case AuthResult.successSuperAdmin:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
        );
        break;
      case AuthResult.subscriptionExpired:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionExpiredScreen()),
        );
        break;
      case AuthResult.userNotFound:
      case AuthResult.error:
        // Hata durumunda bir şey yapmaya gerek yok,
        // Consumer zaten hata mesajını gösterecek.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Modern bir görünüm için tema renklerini kullanıyoruz
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Arka planı daha yumuşak bir tona ayarlıyoruz
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Kullanıcı yazmaya başladığında hatayı temizlemek için listener
          if (authProvider.errorMessage != null) {
            _usernameController.addListener(authProvider.clearError);
            _passwordController.addListener(authProvider.clearError);
          }

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Marka Logosu
                    Icon(
                      Icons.receipt_long,
                      size: 60,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Adisyona",
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Hesabınıza giriş yapın",
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Form elemanlarını modern bir kart içine alıyoruz
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Kullanıcı Adı/E-posta Alanı
                          _buildTextField(
                            controller: _usernameController,
                            labelText: "Telefon veya E-posta",
                            icon: Icons.person_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            enabled: !authProvider.isLoading,
                          ),
                          const SizedBox(height: 20),

                          // Şifre Alanı
                          _buildTextField(
                            controller: _passwordController,
                            labelText: "Şifre",
                            icon: Icons.lock_outline_rounded,
                            obscureText: true,
                            enabled: !authProvider.isLoading,
                          ),
                          const SizedBox(height: 12),

                          // Şifremi Unuttum Butonu
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // TODO: Şifremi unuttum özelliği
                              },
                              child: const Text("Şifremi Unuttum?"),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Hata Mesajı
                          if (authProvider.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: _buildErrorMessage(authProvider.errorMessage!),
                            ),

                          // Giriş Butonu
                          _buildLoginButton(
                            context: context,
                            isLoading: authProvider.isLoading,
                            onPressed: () => _handleLogin(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Modern ve yeniden tasarlanmış TextField oluşturucu.
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      enabled: enabled,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: colors.onSurfaceVariant),
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // Kenarlığı kaldırıyoruz
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
    );
  }

  /// Modern ve yeniden tasarlanmış Hata Mesajı widget'ı.
  Widget _buildErrorMessage(String message) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Modern ve yeniden tasarlanmış Giriş Butonu.
  Widget _buildLoginButton({
    required BuildContext context,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Text(
                "Giriş Yap",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}