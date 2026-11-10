
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/message_update.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  await FCMService.instance.initialize();

  runApp(const CloudCourierApp());
}

class CloudCourierApp extends StatelessWidget {
  const CloudCourierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cloud Courier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF315C81),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        cardTheme: CardThemeData(
          elevation: 1,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      home: const CourierHomePage(),
    );
  }
}

class CourierHomePage extends StatefulWidget {
  const CourierHomePage({super.key});

  @override
  State<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends State<CourierHomePage> {
  final FCMService _service = FCMService.instance;

  String _permissionStatus = 'Not requested';
  String _tokenStatus = 'Not retrieved';
  bool _requestingPermission = false;

  Future<void> _enableNotifications() async {
    setState(() => _requestingPermission = true);

    try {
      final settings = await _service.requestPermission();
      final token = await _service.getToken();

      // Print the full token for Firebase Console testing.
      debugPrint('FCM_TOKEN: $token');

      if (!mounted) return;

      setState(() {
        _permissionStatus = settings.authorizationStatus.name;
        _tokenStatus = token == null
            ? 'Token unavailable'
            : '${token.substring(0, token.length > 12 ? 12 : token.length)}...';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification permission: $_permissionStatus',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _permissionStatus = 'Error';
        _tokenStatus = 'Unavailable';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification setup failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _requestingPermission = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cloud Courier',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<MessageUpdate>(
        stream: _service.updates,
        initialData: _service.currentUpdate,
        builder: (context, snapshot) {
          final update = snapshot.data ?? MessageUpdate.initial();

          final imagePath = update.asset == 'promo'
              ? 'assets/images/promo.png'
              : 'assets/images/default.jpg';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF315C81),
                      Color(0xFF5486A9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.mark_email_read_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Your updates, delivered.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'A real-time messaging experience powered by Firebase Cloud Messaging.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Latest cloud update',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      imagePath,
                      height: 190,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 190,
                          color: Colors.blueGrey.shade100,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            update.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            update.body,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Chip(
                            avatar: const Icon(
                              Icons.image_outlined,
                              size: 17,
                            ),
                            label: Text('Asset: ${update.asset}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery diagnostics',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _detailRow('Handler', update.handler),
                      _detailRow(
                        'Receipt count',
                        '${update.receiptCount}',
                      ),
                      _detailRow('Message ID', update.messageId),
                      _detailRow('Diagnostic', update.diagnostic),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device registration',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _detailRow('Permission', _permissionStatus),
                      _detailRow('Installation token', _tokenStatus),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _requestingPermission
                              ? null
                              : _enableNotifications,
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                          ),
                          label: Text(
                            _requestingPermission
                                ? 'Checking permission...'
                                : 'Enable notifications',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'A registration token identifies this app installation. It does not identify a signed-in user or grant access to protected resources.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey,
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
