// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedLocatorGenerator
// **************************************************************************

// ignore_for_file: public_member_api_docs, implementation_imports, depend_on_referenced_packages

import 'package:stacked_services/src/dialog/dialog_service.dart';
import 'package:stacked_services/src/navigation/navigation_service.dart';
import 'package:stacked_services/src/snackbar/snackbar_service.dart';
import 'package:stacked_shared/stacked_shared.dart';

import '../core/api/api_client.dart';
import '../services/accord_service.dart';
import '../services/auth_service.dart';
import '../services/calendrier_service.dart';
import '../services/dashboard_service.dart';
import '../services/logement_service.dart';
import '../services/matching_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/token_storage_service.dart';

final locator = StackedLocator.instance;

Future<void> setupLocator({
  String? environment,
  EnvironmentFilter? environmentFilter,
}) async {
  // Register environments
  locator.registerEnvironment(
    environment: environment,
    environmentFilter: environmentFilter,
  );

  // Register dependencies
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => DialogService());
  locator.registerLazySingleton(() => SnackbarService());
  locator.registerLazySingleton(() => TokenStorageService());
  locator.registerLazySingleton(() => ApiClient());
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => ProfileService());
  locator.registerLazySingleton(() => DashboardService());
  locator.registerLazySingleton(() => CalendrierService());
  locator.registerLazySingleton(() => MatchingService());
  locator.registerLazySingleton(() => LogementService());
  locator.registerLazySingleton(() => AccordService());
  locator.registerLazySingleton(() => NotificationService());
}
