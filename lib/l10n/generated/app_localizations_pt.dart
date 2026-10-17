// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Clipsy';

  @override
  String get tagline =>
      'Cada vídeo escolhido por um pai ou mãe. Quando o tempo acaba, para.';

  @override
  String get navPlaylists => 'Listas';

  @override
  String get navCommunity => 'Comunidade';

  @override
  String get navSettings => 'Definições';

  @override
  String get cancel => 'Cancelar';

  @override
  String get next => 'Seguinte';

  @override
  String get skip => 'Saltar';

  @override
  String get getStarted => 'Começar';

  @override
  String get or => 'ou';

  @override
  String get errorNetwork =>
      'Sem ligação. Verifique a internet e tente novamente.';

  @override
  String get signInParentsOnly =>
      'Inicie sessão como pai ou mãe. As crianças não precisam de conta.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailInvalid => 'Introduza um endereço de email válido';

  @override
  String get sendMagicLink => 'Enviar link de início de sessão';

  @override
  String get continueWithGoogle => 'Continuar com Google';

  @override
  String get checkYourEmail => 'Verifique o seu email';

  @override
  String magicLinkSent(String email) {
    return 'Enviámos um link de início de sessão para $email. Abra-o neste dispositivo.';
  }

  @override
  String get useDifferentEmail => 'Usar outro email';

  @override
  String get signInFailed =>
      'Não foi possível iniciar sessão. Tente novamente.';

  @override
  String get signInRateLimited =>
      'Demasiados pedidos. Aguarde um minuto e tente novamente.';

  @override
  String get signOut => 'Terminar sessão';

  @override
  String get signOutConfirmTitle => 'Terminar sessão?';

  @override
  String get signOutConfirmBody =>
      'Isto também remove o PIN parental deste dispositivo. Vai definir um novo da próxima vez que iniciar sessão.';

  @override
  String get signedInAs => 'Sessão iniciada como';

  @override
  String get pinCreateTitle => 'Crie um PIN parental';

  @override
  String get pinCreateSubtitle =>
      'Vai precisar destes 4 dígitos para sair do Modo Criança e abrir as definições. Mantenha-o em segredo das crianças!';

  @override
  String get pinConfirmTitle => 'Introduza o PIN novamente';

  @override
  String get pinMismatch => 'Os PINs não coincidem. Tente novamente.';

  @override
  String get pinEnterCurrent => 'Introduza o PIN atual';

  @override
  String get pinChooseNew => 'Escolha um novo PIN';

  @override
  String get pinChanged => 'PIN alterado';

  @override
  String get changePin => 'Alterar PIN';

  @override
  String get pinWrong => 'PIN incorreto';

  @override
  String pinWrongAttemptsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'PIN incorreto. Restam $count tentativas antes de uma pequena espera.',
      one: 'PIN incorreto. Resta 1 tentativa antes de uma pequena espera.',
    );
    return '$_temp0';
  }

  @override
  String pinLockedOut(String time) {
    return 'Demasiadas tentativas. Tente novamente dentro de $time.';
  }

  @override
  String pinDigitsEntered(int entered, int total) {
    return '$entered de $total dígitos introduzidos';
  }

  @override
  String get pinBackspace => 'Apagar o último dígito';

  @override
  String get unlockTitle => 'Introduza o PIN parental';

  @override
  String get forgotPin => 'Esqueceu-se do PIN?';

  @override
  String get forgotPinTitle => 'Repor o PIN';

  @override
  String get forgotPinBody =>
      'Para repor o PIN, inicie sessão novamente com a sua conta e escolha um novo PIN.';

  @override
  String get forgotPinConfirm => 'Iniciar sessão novamente';

  @override
  String get onboardingWelcomeTitle => 'Bem-vindo ao Clipsy';

  @override
  String get onboardingWelcomeBody =>
      'Crie listas de vídeos do YouTube escolhidos por si e entregue o dispositivo sabendo exatamente o que a criança vai ver e durante quanto tempo.';

  @override
  String get onboardingKidModeTitle => 'Como funciona o Modo Criança';

  @override
  String get onboardingKidModeBody =>
      'O Modo Criança reproduz uma única lista com controlos grandes e simples. Sem pesquisa e sem sugestões.';

  @override
  String get onboardingKidModeStep1 =>
      'Escolha uma lista e um limite de tempo.';

  @override
  String get onboardingKidModeStep2 =>
      'Confirme com o seu PIN e entregue o dispositivo.';

  @override
  String get onboardingKidModeStep3 =>
      'Quando o tempo acaba, a reprodução para. Só o seu PIN dá mais tempo ou permite sair.';

  @override
  String get onboardingPinningTitle => 'Fixe o ecrã no Clipsy';

  @override
  String get onboardingPinningBody =>
      'Quando o Modo Criança começar, o Android vai pedir para fixar o Clipsy no ecrã. Aceite: os botões Início e Recentes ficam bloqueados até sair do Modo Criança com o PIN.';

  @override
  String get onboardingGuidedAccessTitle => 'Ative o Acesso Guiado';

  @override
  String get onboardingGuidedAccessBody =>
      'As apps de iPhone e iPad não se conseguem bloquear sozinhas. O Acesso Guiado, incluído no iOS, mantém a criança dentro do Clipsy. O Modo Criança funciona sem ele, apenas com as proteções da app.';

  @override
  String get onboardingGuidedAccessStep1 =>
      'Abra Definições → Acessibilidade → Acesso Guiado e ative-o.';

  @override
  String get onboardingGuidedAccessStep2 =>
      'Defina um código para o Acesso Guiado.';

  @override
  String get onboardingGuidedAccessStep3 =>
      'No Modo Criança, prima três vezes o botão lateral (ou o botão principal) e toque em Iniciar.';

  @override
  String onboardingPageOf(int current, int total) {
    return 'Página $current de $total';
  }

  @override
  String get playlistsEmptyTitle => 'Ainda não há listas';

  @override
  String get playlistsEmptyBody =>
      'As suas listas vão aparecer aqui. A criação de listas chega na próxima atualização.';

  @override
  String get communityComingTitle => 'Biblioteca da comunidade';

  @override
  String get communityComingBody =>
      'Explore, guarde e avalie listas criadas por outros pais. Brevemente.';

  @override
  String get settingsSecurity => 'Segurança';

  @override
  String get settingsAccount => 'Conta';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get lockParentMode => 'Bloquear o modo parental agora';

  @override
  String get lockParentModeHint => 'É preciso o PIN para voltar a entrar';

  @override
  String get privacyPolicy => 'Política de privacidade';
}
