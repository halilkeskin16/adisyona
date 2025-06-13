import 'package:adisyona/views/dashboard/admin_menu.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart'; // Mevcut AuthProvider'ınızın yolu
import '../dashboard/admin_dashboard.dart'; // AdminDashboard'ınızın yolu
import '../super_admin/super_admin_dashboard.dart'; // SuperAdminDashboard'ınızın yolu
import 'subscription_expired_screen.dart'; // Abonelik bitiş ekranınızın yolu

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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Giriş işlemini yöneten metod
  Future<void> _login(BuildContext context) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Hata mesajını temizle
    });

    try {
      final input = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      // Alanların boş olup olmadığını kontrol et
      if (input.isEmpty || password.isEmpty) {
        setState(() {
          _errorMessage = "Lütfen kullanıcı adı/e-posta ve şifrenizi girin.";
          _isLoading = false;
        });
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (input.contains("@")) {
        // e-posta ise süper admin girişi varsayılıyor
        await authProvider.loginWithEmail(input, password);
      } else {
        // telefon ile giriş
        await authProvider.login(input, password);
      }

      final user = authProvider.user; // Giriş yapan kullanıcı bilgilerini al

      if (user == null) {
        setState(() => _errorMessage = "Kullanıcı bulunamadı veya bilgiler hatalı.");
        return;
      }

      // Kullanıcı rolüne göre farklı ekranlara yönlendirme
      if (user.role == "super_admin") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
        );
      } else if (user.role == "admin") {
        // Admin ise şirket aboneliği geçerliliğini kontrol et
        final isValid = await authProvider.isCompanyValid(user.companyId!);

        if (!isValid) {
          // Abonelik süresi dolmuşsa ilgili ekrana yönlendir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SubscriptionExpiredScreen()),
          );
        } else {
          // Abonelik geçerliyse Admin Dashboard'a yönlendir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardMenu()),
          );
        }
      } else {
        // Tanımlanmamış rol durumunda hata mesajı
        setState(() => _errorMessage = "Yetkisiz kullanıcı rolü.");
      }
    } catch (e) {
      // Giriş sırasında oluşan genel hataları yakala
      setState(() => _errorMessage = "Giriş hatası: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false); // Yükleniyor durumunu bitir
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema renklerini ve metin stillerini tanımla
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface, // Genel arka plan rengi
      body: GestureDetector(
        onTap: () {
          // Klavyeyi kapatmak için dışarı tıklamayı dinle
          FocusScope.of(context).unfocus();
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // İçeriği dikeyde ortala
              children: [
                // Uygulama ikonu
                Icon(
                  Icons.receipt_long, // Adisyona temasını yansıtan bir ikon
                  size: 80, // İkon boyutu
                  color: colorScheme.primary, // Temanın ana rengiyle uyumlu
                ),
                const SizedBox(height: 24), // İkon ile başlık arası boşluk

                // Uygulama başlığı
                Text(
                  "Adisyona",
                  style: textTheme.displaySmall?.copyWith( // Daha büyük bir başlık stili
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary, // Temanın ana rengiyle uyumlu
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 48), // Daha fazla boşluk

                // Kullanıcı adı/e-posta giriş alanı
                _buildTextField(
                  controller: _usernameController,
                  labelText: "Telefon veya E-posta",
                  icon: Icons.person,
                  keyboardType: TextInputType.emailAddress, // E-posta veya telefon için uygun klavye
                ),
                const SizedBox(height: 16),

                // Şifre giriş alanı
                _buildTextField(
                  controller: _passwordController,
                  labelText: "Şifre",
                  icon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 24), // Buton öncesi boşluk

                // Hata mesajı gösterimi
                if (_errorMessage != null) _buildErrorMessage(colorScheme),
                const SizedBox(height: 24), // Hata mesajı sonrası boşluk

                // Giriş butonu
                _buildLoginButton(colorScheme, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Ortak TextField stilini oluşturan yardımcı metod
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: icon != null ? Icon(icon, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Yuvarlatılmış kenarlar
          borderSide: BorderSide.none, // Kenarlık çizgisini kaldır
        ),
        filled: true, // Alanın arka planını doldur
        fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5), // Daha yumuşak arka plan rengi
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
      cursorColor: Theme.of(context).colorScheme.primary,
    );
  }

  // Hata mesajını gösteren yardımcı metod
  Widget _buildErrorMessage(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Giriş butonunu oluşturan yardımcı metod
  Widget _buildLoginButton(ColorScheme colorScheme, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _login(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary, // Ana tema rengini kullan
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Yuvarlatılmış kenarlar
          ),
          elevation: 5,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
            : Text(
                "Giriş Yap",
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
