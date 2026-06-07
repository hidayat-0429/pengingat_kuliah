import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env vars
  await dotenv.load(fileName: ".env");

  // Init services
  await AppConfig.initialize();
  await NotificationService.initialize();

  runApp(const MainApp());
}
