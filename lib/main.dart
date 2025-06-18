import 'package:adisyona/providers/order_provider.dart';
import 'package:adisyona/providers/product_provider.dart';
import 'package:adisyona/providers/reports_provider.dart';
import 'package:adisyona/providers/staff_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'views/auth/login_view.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  await initializeDateFormatting('tr_TR', null);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AdisyonaApp());
}

class AdisyonaApp extends StatelessWidget {
  const AdisyonaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProxyProvider<AuthProvider, StaffProvider>(
          create:
              (context) => StaffProvider(
                Provider.of<AuthProvider>(context, listen: false),
              ),
          update: (context, auth, previousStaff) => StaffProvider(auth),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Adisyona',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations
              .delegate, 
          GlobalWidgetsLocalizations
              .delegate,
          GlobalCupertinoLocalizations
              .delegate,
        ],
        supportedLocales: const [
          Locale(
            'tr',
            'TR',
          ),
        ],
        home: const LoginView(),
      ),
    );
  }
}
