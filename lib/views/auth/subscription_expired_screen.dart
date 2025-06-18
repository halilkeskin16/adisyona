import 'package:adisyona/views/auth/login_view.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionExpiredScreen extends StatelessWidget {
  const SubscriptionExpiredScreen({super.key});

  // Destek e-posta adresini veya telefon numarasını açacak metot
  Future<void> _contactSupport(BuildContext context) async {
    // Buraya kendi destek e-posta adresinizi yazın
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'destek@adisyona.com',
      queryParameters: {
        'subject': 'Abonelik Yenileme Talebi',
        'body': 'Merhaba, Adisyona aboneliğimizi yenilemek istiyoruz. Lütfen yardımcı olun.'
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('E-posta uygulaması bulunamadı.')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşlem sırasında bir hata oluştu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dikkat Çekici İkon
              Icon(
                Icons.timer_off_outlined,
                size: 80,
                color: colorScheme.error,
              ),
              const SizedBox(height: 24),

              // Ana Başlık
              Text(
                "Aboneliğiniz Sona Erdi",
                textAlign: TextAlign.center,
                style: textTheme.displaySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Açıklama Metni
              Text(
                "Bu işletmenin abonelik süresi dolmuştur. Uygulamayı kullanmaya devam etmek için lütfen destek ekibimizle iletişime geçin.",
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5, // Satır yüksekliği
                ),
              ),
              const SizedBox(height: 48),

              // Ana Aksiyon Butonu (İletişim)
              FilledButton.icon(
                icon: const Icon(Icons.support_agent),
                label: const Text("Destek ile İletişime Geç"),
                onPressed: () => _contactSupport(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // İkincil Aksiyon Butonu (Giriş Ekranına Dön)

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginView()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child:  Text("Giriş Ekranına Dön"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}