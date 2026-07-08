import 'package:stacked/stacked.dart';

/// ViewModel de l'écran de démarrage.
/// Plus tard (APP-63) : vérifiera la présence d'un token valide
/// et redirigera vers Login ou Home.
class StartupViewModel extends BaseViewModel {
  Future<void> runStartupLogic() async {
    // Pour l'instant : rien à faire.
    // APP-63 ajoutera : lecture du token secure storage + redirection.
  }
}
