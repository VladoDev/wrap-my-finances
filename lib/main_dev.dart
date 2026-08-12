import 'package:wrap_my_finances/bootstrap.dart';
import 'package:wrap_my_finances/core/config/app_environment.dart';
import 'package:wrap_my_finances/core/config/firebase_options_dev.dart';

void main() =>
    bootstrap(AppEnvironment.dev, DefaultFirebaseOptions.currentPlatform);
