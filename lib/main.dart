import 'package:flutter/widgets.dart';
import 'package:dummyjson_flutter_test/app/app.dart';
import 'package:dummyjson_flutter_test/app/injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const App());
}
