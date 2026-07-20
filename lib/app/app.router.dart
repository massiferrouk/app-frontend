// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// StackedNavigatorGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter/material.dart' as _i20;
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart' as _i1;
import 'package:stacked_services/stacked_services.dart' as _i26;
import 'package:studup_app/features/accords/accord_detail_view.dart' as _i12;
import 'package:studup_app/features/accords/mes_accords_view.dart' as _i16;
import 'package:studup_app/features/auth/login/login_view.dart' as _i4;
import 'package:studup_app/features/auth/profil_creation/profil_creation_view.dart'
    as _i6;
import 'package:studup_app/features/auth/register/register_view.dart' as _i5;
import 'package:studup_app/features/avis/avis_view.dart' as _i18;
import 'package:studup_app/features/calendrier/mon_calendrier_view.dart' as _i8;
import 'package:studup_app/features/candidatures/mes_candidatures_view.dart'
    as _i17;
import 'package:studup_app/features/logements/ajouter_logement_view.dart'
    as _i10;
import 'package:studup_app/features/logements/logement_detail_view.dart'
    as _i11;
import 'package:studup_app/features/logements/mes_logements_view.dart' as _i15;
import 'package:studup_app/features/main/main_view.dart' as _i7;
import 'package:studup_app/features/matching/compatibilite_view.dart' as _i9;
import 'package:studup_app/features/messages/chat_view.dart' as _i19;
import 'package:studup_app/features/notifications/notifications_view.dart'
    as _i13;
import 'package:studup_app/features/onboarding/onboarding_view.dart' as _i3;
import 'package:studup_app/features/recherche/recherche_view.dart' as _i14;
import 'package:studup_app/features/startup/startup_view.dart' as _i2;
import 'package:studup_app/shared/models/accord.dart' as _i24;
import 'package:studup_app/shared/models/alternant_profile.dart' as _i21;
import 'package:studup_app/shared/models/conversation_summary.dart' as _i25;
import 'package:studup_app/shared/models/logement.dart' as _i23;
import 'package:studup_app/shared/models/matching_suggestion.dart' as _i22;

class Routes {
  static const startupView = '/';

  static const onboardingView = '/onboarding-view';

  static const loginView = '/login-view';

  static const registerView = '/register-view';

  static const profilCreationView = '/profil-creation-view';

  static const mainView = '/main-view';

  static const monCalendrierView = '/mon-calendrier-view';

  static const compatibiliteView = '/compatibilite-view';

  static const ajouterLogementView = '/ajouter-logement-view';

  static const logementDetailView = '/logement-detail-view';

  static const accordDetailView = '/accord-detail-view';

  static const notificationsView = '/notifications-view';

  static const rechercheView = '/recherche-view';

  static const mesLogementsView = '/mes-logements-view';

  static const mesAccordsView = '/mes-accords-view';

  static const mesCandidaturesView = '/mes-candidatures-view';

  static const avisView = '/avis-view';

  static const chatView = '/chat-view';

  static const all = <String>{
    startupView,
    onboardingView,
    loginView,
    registerView,
    profilCreationView,
    mainView,
    monCalendrierView,
    compatibiliteView,
    ajouterLogementView,
    logementDetailView,
    accordDetailView,
    notificationsView,
    rechercheView,
    mesLogementsView,
    mesAccordsView,
    mesCandidaturesView,
    avisView,
    chatView,
  };
}

class StackedRouter extends _i1.RouterBase {
  final _routes = <_i1.RouteDef>[
    _i1.RouteDef(Routes.startupView, page: _i2.StartupView),
    _i1.RouteDef(Routes.onboardingView, page: _i3.OnboardingView),
    _i1.RouteDef(Routes.loginView, page: _i4.LoginView),
    _i1.RouteDef(Routes.registerView, page: _i5.RegisterView),
    _i1.RouteDef(Routes.profilCreationView, page: _i6.ProfilCreationView),
    _i1.RouteDef(Routes.mainView, page: _i7.MainView),
    _i1.RouteDef(Routes.monCalendrierView, page: _i8.MonCalendrierView),
    _i1.RouteDef(Routes.compatibiliteView, page: _i9.CompatibiliteView),
    _i1.RouteDef(Routes.ajouterLogementView, page: _i10.AjouterLogementView),
    _i1.RouteDef(Routes.logementDetailView, page: _i11.LogementDetailView),
    _i1.RouteDef(Routes.accordDetailView, page: _i12.AccordDetailView),
    _i1.RouteDef(Routes.notificationsView, page: _i13.NotificationsView),
    _i1.RouteDef(Routes.rechercheView, page: _i14.RechercheView),
    _i1.RouteDef(Routes.mesLogementsView, page: _i15.MesLogementsView),
    _i1.RouteDef(Routes.mesAccordsView, page: _i16.MesAccordsView),
    _i1.RouteDef(Routes.mesCandidaturesView, page: _i17.MesCandidaturesView),
    _i1.RouteDef(Routes.avisView, page: _i18.AvisView),
    _i1.RouteDef(Routes.chatView, page: _i19.ChatView),
  ];

  final _pagesMap = <Type, _i1.StackedRouteFactory>{
    _i2.StartupView: (data) {
      final args = data.getArgs<StartupViewArguments>(
        orElse: () => const StartupViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) => _i2.StartupView(key: args.key),
        settings: data,
      );
    },
    _i3.OnboardingView: (data) {
      final args = data.getArgs<OnboardingViewArguments>(
        orElse: () => const OnboardingViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) => _i3.OnboardingView(key: args.key),
        settings: data,
      );
    },
    _i4.LoginView: (data) {
      final args = data.getArgs<LoginViewArguments>(
        orElse: () => const LoginViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) => _i4.LoginView(key: args.key),
        settings: data,
      );
    },
    _i5.RegisterView: (data) {
      final args = data.getArgs<RegisterViewArguments>(
        orElse: () => const RegisterViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) => _i5.RegisterView(key: args.key),
        settings: data,
      );
    },
    _i6.ProfilCreationView: (data) {
      final args = data.getArgs<ProfilCreationViewArguments>(
        orElse: () => const ProfilCreationViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i6.ProfilCreationView(key: args.key, profile: args.profile),
        settings: data,
      );
    },
    _i7.MainView: (data) {
      final args = data.getArgs<MainViewArguments>(
        orElse: () => const MainViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) => _i7.MainView(key: args.key),
        settings: data,
      );
    },
    _i8.MonCalendrierView: (data) {
      final args = data.getArgs<MonCalendrierViewArguments>(
        orElse: () => const MonCalendrierViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) => _i8.MonCalendrierView(key: args.key),
        settings: data,
      );
    },
    _i9.CompatibiliteView: (data) {
      final args = data.getArgs<CompatibiliteViewArguments>(nullOk: false);
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i9.CompatibiliteView(key: args.key, suggestion: args.suggestion),
        settings: data,
      );
    },
    _i10.AjouterLogementView: (data) {
      final args = data.getArgs<AjouterLogementViewArguments>(
        orElse: () => const AjouterLogementViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i10.AjouterLogementView(key: args.key, logement: args.logement),
        settings: data,
      );
    },
    _i11.LogementDetailView: (data) {
      final args = data.getArgs<LogementDetailViewArguments>(nullOk: false);
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i11.LogementDetailView(key: args.key, logement: args.logement),
        settings: data,
      );
    },
    _i12.AccordDetailView: (data) {
      final args = data.getArgs<AccordDetailViewArguments>(nullOk: false);
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i12.AccordDetailView(key: args.key, accord: args.accord),
        settings: data,
      );
    },
    _i13.NotificationsView: (data) {
      final args = data.getArgs<NotificationsViewArguments>(
        orElse: () => const NotificationsViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i13.NotificationsView(key: args.key, standalone: args.standalone),
        settings: data,
      );
    },
    _i14.RechercheView: (data) {
      final args = data.getArgs<RechercheViewArguments>(
        orElse: () => const RechercheViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) => _i14.RechercheView(
          key: args.key,
          standalone: args.standalone,
          onSeeMatches: args.onSeeMatches,
        ),
        settings: data,
      );
    },
    _i15.MesLogementsView: (data) {
      final args = data.getArgs<MesLogementsViewArguments>(
        orElse: () => const MesLogementsViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i15.MesLogementsView(key: args.key, standalone: args.standalone),
        settings: data,
      );
    },
    _i16.MesAccordsView: (data) {
      final args = data.getArgs<MesAccordsViewArguments>(
        orElse: () => const MesAccordsViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i16.MesAccordsView(key: args.key, standalone: args.standalone),
        settings: data,
      );
    },
    _i17.MesCandidaturesView: (data) {
      final args = data.getArgs<MesCandidaturesViewArguments>(
        orElse: () => const MesCandidaturesViewArguments(),
      );
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) => _i17.MesCandidaturesView(
          key: args.key,
          onSearch: args.onSearch,
          standalone: args.standalone,
        ),
        settings: data,
      );
    },
    _i18.AvisView: (data) {
      final args = data.getArgs<AvisViewArguments>(nullOk: false);
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) => _i18.AvisView(key: args.key, accord: args.accord),
        settings: data,
      );
    },
    _i19.ChatView: (data) {
      final args = data.getArgs<ChatViewArguments>(nullOk: false);
      return _i20.MaterialPageRoute<dynamic>(
        builder: (context) =>
            _i19.ChatView(key: args.key, conversation: args.conversation),
        settings: data,
      );
    },
  };

  @override
  List<_i1.RouteDef> get routes => _routes;

  @override
  Map<Type, _i1.StackedRouteFactory> get pagesMap => _pagesMap;
}

class StartupViewArguments {
  const StartupViewArguments({this.key});

  final _i20.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant StartupViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class OnboardingViewArguments {
  const OnboardingViewArguments({this.key});

  final _i20.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant OnboardingViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class LoginViewArguments {
  const LoginViewArguments({this.key});

  final _i20.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant LoginViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class RegisterViewArguments {
  const RegisterViewArguments({this.key});

  final _i20.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant RegisterViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class ProfilCreationViewArguments {
  const ProfilCreationViewArguments({this.key, this.profile});

  final _i20.Key? key;

  final _i21.AlternantProfile? profile;

  @override
  String toString() {
    return '{"key": "$key", "profile": "$profile"}';
  }

  @override
  bool operator ==(covariant ProfilCreationViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.profile == profile;
  }

  @override
  int get hashCode {
    return key.hashCode ^ profile.hashCode;
  }
}

class MainViewArguments {
  const MainViewArguments({this.key});

  final _i20.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant MainViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class MonCalendrierViewArguments {
  const MonCalendrierViewArguments({this.key});

  final _i20.Key? key;

  @override
  String toString() {
    return '{"key": "$key"}';
  }

  @override
  bool operator ==(covariant MonCalendrierViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key;
  }

  @override
  int get hashCode {
    return key.hashCode;
  }
}

class CompatibiliteViewArguments {
  const CompatibiliteViewArguments({this.key, required this.suggestion});

  final _i20.Key? key;

  final _i22.MatchingSuggestion suggestion;

  @override
  String toString() {
    return '{"key": "$key", "suggestion": "$suggestion"}';
  }

  @override
  bool operator ==(covariant CompatibiliteViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.suggestion == suggestion;
  }

  @override
  int get hashCode {
    return key.hashCode ^ suggestion.hashCode;
  }
}

class AjouterLogementViewArguments {
  const AjouterLogementViewArguments({this.key, this.logement});

  final _i20.Key? key;

  final _i23.Logement? logement;

  @override
  String toString() {
    return '{"key": "$key", "logement": "$logement"}';
  }

  @override
  bool operator ==(covariant AjouterLogementViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.logement == logement;
  }

  @override
  int get hashCode {
    return key.hashCode ^ logement.hashCode;
  }
}

class LogementDetailViewArguments {
  const LogementDetailViewArguments({this.key, required this.logement});

  final _i20.Key? key;

  final _i23.Logement logement;

  @override
  String toString() {
    return '{"key": "$key", "logement": "$logement"}';
  }

  @override
  bool operator ==(covariant LogementDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.logement == logement;
  }

  @override
  int get hashCode {
    return key.hashCode ^ logement.hashCode;
  }
}

class AccordDetailViewArguments {
  const AccordDetailViewArguments({this.key, required this.accord});

  final _i20.Key? key;

  final _i24.Accord accord;

  @override
  String toString() {
    return '{"key": "$key", "accord": "$accord"}';
  }

  @override
  bool operator ==(covariant AccordDetailViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.accord == accord;
  }

  @override
  int get hashCode {
    return key.hashCode ^ accord.hashCode;
  }
}

class NotificationsViewArguments {
  const NotificationsViewArguments({this.key, this.standalone = false});

  final _i20.Key? key;

  final bool standalone;

  @override
  String toString() {
    return '{"key": "$key", "standalone": "$standalone"}';
  }

  @override
  bool operator ==(covariant NotificationsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.standalone == standalone;
  }

  @override
  int get hashCode {
    return key.hashCode ^ standalone.hashCode;
  }
}

class RechercheViewArguments {
  const RechercheViewArguments({
    this.key,
    this.standalone = false,
    this.onSeeMatches,
  });

  final _i20.Key? key;

  final bool standalone;

  final void Function()? onSeeMatches;

  @override
  String toString() {
    return '{"key": "$key", "standalone": "$standalone", "onSeeMatches": "$onSeeMatches"}';
  }

  @override
  bool operator ==(covariant RechercheViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.standalone == standalone &&
        other.onSeeMatches == onSeeMatches;
  }

  @override
  int get hashCode {
    return key.hashCode ^ standalone.hashCode ^ onSeeMatches.hashCode;
  }
}

class MesLogementsViewArguments {
  const MesLogementsViewArguments({this.key, this.standalone = false});

  final _i20.Key? key;

  final bool standalone;

  @override
  String toString() {
    return '{"key": "$key", "standalone": "$standalone"}';
  }

  @override
  bool operator ==(covariant MesLogementsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.standalone == standalone;
  }

  @override
  int get hashCode {
    return key.hashCode ^ standalone.hashCode;
  }
}

class MesAccordsViewArguments {
  const MesAccordsViewArguments({this.key, this.standalone = false});

  final _i20.Key? key;

  final bool standalone;

  @override
  String toString() {
    return '{"key": "$key", "standalone": "$standalone"}';
  }

  @override
  bool operator ==(covariant MesAccordsViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.standalone == standalone;
  }

  @override
  int get hashCode {
    return key.hashCode ^ standalone.hashCode;
  }
}

class MesCandidaturesViewArguments {
  const MesCandidaturesViewArguments({
    this.key,
    this.onSearch,
    this.standalone = false,
  });

  final _i20.Key? key;

  final void Function()? onSearch;

  final bool standalone;

  @override
  String toString() {
    return '{"key": "$key", "onSearch": "$onSearch", "standalone": "$standalone"}';
  }

  @override
  bool operator ==(covariant MesCandidaturesViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key &&
        other.onSearch == onSearch &&
        other.standalone == standalone;
  }

  @override
  int get hashCode {
    return key.hashCode ^ onSearch.hashCode ^ standalone.hashCode;
  }
}

class AvisViewArguments {
  const AvisViewArguments({this.key, required this.accord});

  final _i20.Key? key;

  final _i24.Accord accord;

  @override
  String toString() {
    return '{"key": "$key", "accord": "$accord"}';
  }

  @override
  bool operator ==(covariant AvisViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.accord == accord;
  }

  @override
  int get hashCode {
    return key.hashCode ^ accord.hashCode;
  }
}

class ChatViewArguments {
  const ChatViewArguments({this.key, required this.conversation});

  final _i20.Key? key;

  final _i25.ConversationSummary conversation;

  @override
  String toString() {
    return '{"key": "$key", "conversation": "$conversation"}';
  }

  @override
  bool operator ==(covariant ChatViewArguments other) {
    if (identical(this, other)) return true;
    return other.key == key && other.conversation == conversation;
  }

  @override
  int get hashCode {
    return key.hashCode ^ conversation.hashCode;
  }
}

extension NavigatorStateExtension on _i26.NavigationService {
  Future<dynamic> navigateToStartupView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.startupView,
      arguments: StartupViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToOnboardingView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.onboardingView,
      arguments: OnboardingViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToLoginView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.loginView,
      arguments: LoginViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToRegisterView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.registerView,
      arguments: RegisterViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToProfilCreationView({
    _i20.Key? key,
    _i21.AlternantProfile? profile,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.profilCreationView,
      arguments: ProfilCreationViewArguments(key: key, profile: profile),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToMainView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.mainView,
      arguments: MainViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToMonCalendrierView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.monCalendrierView,
      arguments: MonCalendrierViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToCompatibiliteView({
    _i20.Key? key,
    required _i22.MatchingSuggestion suggestion,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.compatibiliteView,
      arguments: CompatibiliteViewArguments(key: key, suggestion: suggestion),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToAjouterLogementView({
    _i20.Key? key,
    _i23.Logement? logement,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.ajouterLogementView,
      arguments: AjouterLogementViewArguments(key: key, logement: logement),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToLogementDetailView({
    _i20.Key? key,
    required _i23.Logement logement,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.logementDetailView,
      arguments: LogementDetailViewArguments(key: key, logement: logement),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToAccordDetailView({
    _i20.Key? key,
    required _i24.Accord accord,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.accordDetailView,
      arguments: AccordDetailViewArguments(key: key, accord: accord),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToNotificationsView({
    _i20.Key? key,
    bool standalone = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.notificationsView,
      arguments: NotificationsViewArguments(key: key, standalone: standalone),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToRechercheView({
    _i20.Key? key,
    bool standalone = false,
    void Function()? onSeeMatches,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.rechercheView,
      arguments: RechercheViewArguments(
        key: key,
        standalone: standalone,
        onSeeMatches: onSeeMatches,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToMesLogementsView({
    _i20.Key? key,
    bool standalone = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.mesLogementsView,
      arguments: MesLogementsViewArguments(key: key, standalone: standalone),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToMesAccordsView({
    _i20.Key? key,
    bool standalone = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.mesAccordsView,
      arguments: MesAccordsViewArguments(key: key, standalone: standalone),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToMesCandidaturesView({
    _i20.Key? key,
    void Function()? onSearch,
    bool standalone = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.mesCandidaturesView,
      arguments: MesCandidaturesViewArguments(
        key: key,
        onSearch: onSearch,
        standalone: standalone,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToAvisView({
    _i20.Key? key,
    required _i24.Accord accord,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.avisView,
      arguments: AvisViewArguments(key: key, accord: accord),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> navigateToChatView({
    _i20.Key? key,
    required _i25.ConversationSummary conversation,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return navigateTo<dynamic>(
      Routes.chatView,
      arguments: ChatViewArguments(key: key, conversation: conversation),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithStartupView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.startupView,
      arguments: StartupViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithOnboardingView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.onboardingView,
      arguments: OnboardingViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithLoginView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.loginView,
      arguments: LoginViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithRegisterView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.registerView,
      arguments: RegisterViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithProfilCreationView({
    _i20.Key? key,
    _i21.AlternantProfile? profile,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.profilCreationView,
      arguments: ProfilCreationViewArguments(key: key, profile: profile),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithMainView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.mainView,
      arguments: MainViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithMonCalendrierView({
    _i20.Key? key,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.monCalendrierView,
      arguments: MonCalendrierViewArguments(key: key),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithCompatibiliteView({
    _i20.Key? key,
    required _i22.MatchingSuggestion suggestion,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.compatibiliteView,
      arguments: CompatibiliteViewArguments(key: key, suggestion: suggestion),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithAjouterLogementView({
    _i20.Key? key,
    _i23.Logement? logement,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.ajouterLogementView,
      arguments: AjouterLogementViewArguments(key: key, logement: logement),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithLogementDetailView({
    _i20.Key? key,
    required _i23.Logement logement,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.logementDetailView,
      arguments: LogementDetailViewArguments(key: key, logement: logement),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithAccordDetailView({
    _i20.Key? key,
    required _i24.Accord accord,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.accordDetailView,
      arguments: AccordDetailViewArguments(key: key, accord: accord),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithNotificationsView({
    _i20.Key? key,
    bool standalone = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.notificationsView,
      arguments: NotificationsViewArguments(key: key, standalone: standalone),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithRechercheView({
    _i20.Key? key,
    bool standalone = false,
    void Function()? onSeeMatches,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.rechercheView,
      arguments: RechercheViewArguments(
        key: key,
        standalone: standalone,
        onSeeMatches: onSeeMatches,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithMesLogementsView({
    _i20.Key? key,
    bool standalone = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.mesLogementsView,
      arguments: MesLogementsViewArguments(key: key, standalone: standalone),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithMesAccordsView({
    _i20.Key? key,
    bool standalone = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.mesAccordsView,
      arguments: MesAccordsViewArguments(key: key, standalone: standalone),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithMesCandidaturesView({
    _i20.Key? key,
    void Function()? onSearch,
    bool standalone = false,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.mesCandidaturesView,
      arguments: MesCandidaturesViewArguments(
        key: key,
        onSearch: onSearch,
        standalone: standalone,
      ),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithAvisView({
    _i20.Key? key,
    required _i24.Accord accord,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.avisView,
      arguments: AvisViewArguments(key: key, accord: accord),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }

  Future<dynamic> replaceWithChatView({
    _i20.Key? key,
    required _i25.ConversationSummary conversation,
    int? routerId,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
    transition,
  }) async {
    return replaceWith<dynamic>(
      Routes.chatView,
      arguments: ChatViewArguments(key: key, conversation: conversation),
      id: routerId,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
      transition: transition,
    );
  }
}
