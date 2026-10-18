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
      'Crie a sua primeira lista e adicione vídeos colando links do YouTube.';

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

  @override
  String get retry => 'Tentar novamente';

  @override
  String get errorGeneric => 'Algo correu mal. Tente novamente.';

  @override
  String get delete => 'Eliminar';

  @override
  String get create => 'Criar';

  @override
  String get save => 'Guardar';

  @override
  String get undo => 'Anular';

  @override
  String get paste => 'Colar';

  @override
  String get moreOptions => 'Mais opções';

  @override
  String get dragToReorder => 'Arraste para reordenar';

  @override
  String get newPlaylist => 'Nova lista';

  @override
  String get editDetails => 'Editar detalhes';

  @override
  String get deletePlaylist => 'Eliminar lista';

  @override
  String deletePlaylistTitle(String title) {
    return 'Eliminar “$title”?';
  }

  @override
  String get deletePlaylistBody =>
      'A lista e os seus vídeos serão removidos. Os vídeos continuam no YouTube.';

  @override
  String videoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vídeos',
      one: '1 vídeo',
      zero: 'Sem vídeos',
    );
    return '$_temp0';
  }

  @override
  String ageRange(int min, int max) {
    return 'Idades $min–$max';
  }

  @override
  String ageYears(int years) {
    return '$years anos';
  }

  @override
  String get playlistTitleLabel => 'Título';

  @override
  String get playlistTitleHint => 'ex.: Factos sobre dinossauros';

  @override
  String get playlistTitleRequired => 'Dê um título à lista';

  @override
  String get playlistDescriptionLabel => 'Descrição (opcional)';

  @override
  String get ageRangeTitle => 'Faixa etária';

  @override
  String get labelsTitle => 'Etiquetas';

  @override
  String labelsHint(int max) {
    return 'Escolha até $max. Ajudam outros pais a encontrar a sua lista se a partilhar mais tarde.';
  }

  @override
  String get createPlaylist => 'Criar lista';

  @override
  String get saveChanges => 'Guardar alterações';

  @override
  String get playlistEmptyTitle => 'Ainda não há vídeos';

  @override
  String get playlistEmptyBody =>
      'Toque em “Adicionar vídeo” e cole um link do YouTube. Em breve também poderá partilhar vídeos da app do YouTube para o Clipsy.';

  @override
  String get reorderHint =>
      'Arraste ☰ para reordenar · deslize para a esquerda para remover';

  @override
  String get videoRemoved => 'Vídeo removido';

  @override
  String get removeVideo => 'Remover vídeo';

  @override
  String get videoUnavailable => 'Já não está disponível no YouTube';

  @override
  String get addVideo => 'Adicionar vídeo';

  @override
  String get addVideoHint =>
      'Cole um link do YouTube. Vamos confirmar que pode ser reproduzido no Clipsy.';

  @override
  String get youtubeLink => 'Link do YouTube';

  @override
  String get checkVideo => 'Verificar vídeo';

  @override
  String get addToPlaylist => 'Adicionar à lista';

  @override
  String videosAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vídeos adicionados',
      one: '1 vídeo adicionado',
    );
    return '$_temp0';
  }

  @override
  String get videoErrorInvalidUrl =>
      'Isto não parece um link para um vídeo do YouTube.';

  @override
  String get videoErrorNotFound =>
      'Não encontrámos esse vídeo. Pode ter sido removido ou tornado privado.';

  @override
  String get videoErrorNotEmbeddable =>
      'O dono deste vídeo não permite que seja reproduzido fora do YouTube, por isso não pode ser adicionado.';

  @override
  String get videoErrorDuplicate => 'Este vídeo já está na lista.';

  @override
  String get playlistErrorTooManyVideos =>
      'Esta lista está cheia. Remova um vídeo para adicionar outro.';

  @override
  String get playlistErrorTooManyLabels =>
      'Uma lista pode ter no máximo 3 etiquetas.';

  @override
  String get playlistErrorNotFound => 'Esta lista já não existe.';

  @override
  String get labelScience => 'Ciência';

  @override
  String get labelNature => 'Natureza';

  @override
  String get labelAnimals => 'Animais';

  @override
  String get labelFootball => 'Futebol';

  @override
  String get labelSports => 'Desporto';

  @override
  String get labelMusic => 'Música';

  @override
  String get labelArt => 'Arte';

  @override
  String get labelLanguages => 'Línguas';

  @override
  String get labelMaths => 'Matemática';

  @override
  String get labelStories => 'Histórias';

  @override
  String get labelBedtime => 'Hora de dormir';

  @override
  String get labelCartoons => 'Desenhos animados';

  @override
  String get labelHistory => 'História';

  @override
  String get labelSpace => 'Espaço';

  @override
  String get labelCooking => 'Culinária';

  @override
  String get labelCrafts => 'Trabalhos manuais';

  @override
  String get ok => 'OK';

  @override
  String get gotIt => 'Percebi';

  @override
  String get startKidMode => 'Iniciar Modo Criança';

  @override
  String get kidNeedsVideos =>
      'Adicione pelo menos um vídeo antes de iniciar o Modo Criança.';

  @override
  String get kidConfirmPin => 'Introduza o PIN para iniciar o Modo Criança';

  @override
  String useDefaultLimit(int minutes) {
    return 'Usar predefinição: $minutes min';
  }

  @override
  String get orChooseLimit => 'Ou escolha um limite de tempo';

  @override
  String get customLimit => 'Personalizar…';

  @override
  String minutesShort(int minutes) {
    return '$minutes min';
  }

  @override
  String minutesLeft(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Faltam $minutes minutos',
      one: 'Falta 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String get pinningDialogTitle => 'O Clipsy vai fixar-se no ecrã';

  @override
  String get pinningDialogBody =>
      'O Android vai pedir para fixar o Clipsy no ecrã. Toque em “Fixar” (ou “Percebi”). Enquanto estiver fixado, os botões Início e Recentes ficam bloqueados.\n\nPara sair do Modo Criança, mantenha premido o pequeno cadeado no canto e introduza o PIN.\n\nDica: em Definições do Android → Segurança → Fixação de apps, ative “Pedir PIN antes de soltar” para mais segurança.';

  @override
  String get guidedAccessOffBody =>
      'O Acesso Guiado está desativado, por isso a criança pode sair do Clipsy com o gesto de Início. O Modo Criança continua a bloquear tudo dentro da app.';

  @override
  String get startAnyway => 'Iniciar mesmo assim';

  @override
  String get kidPlay => 'Reproduzir';

  @override
  String get kidPause => 'Pausa';

  @override
  String get kidAlmostDone => 'Quase a acabar!';

  @override
  String get kidLastVideo => 'Último vídeo!';

  @override
  String kidExitHint(int seconds) {
    return 'Saída para pais. Mantenha premido $seconds segundos.';
  }

  @override
  String get timeUpTitle => 'Por agora acabou!';

  @override
  String get timeUpBody =>
      'Viste muito bem! Agora é hora de fazer outra coisa.';

  @override
  String get timeUpParent => 'Pais';

  @override
  String get timeUpParentTitle => 'Mais tempo ou terminar?';

  @override
  String addMinutes(int minutes) {
    return '+$minutes min';
  }

  @override
  String get exitKidMode => 'Sair do Modo Criança';

  @override
  String get settingsKidMode => 'Modo Criança';

  @override
  String get defaultTimeLimit => 'Limite de tempo predefinido';

  @override
  String get timerModeTitle => 'Contar';

  @override
  String get timerModeWallClock => 'Tempo de relógio (inclui pausas)';

  @override
  String get timerModePlayback => 'Só o tempo a ver';

  @override
  String get endBehaviourTitle => 'Quando o tempo acaba';

  @override
  String get endHardStop => 'Parar imediatamente';

  @override
  String endFinishVideo(int minutes) {
    return 'Deixar acabar o vídeo atual (até $minutes min)';
  }

  @override
  String get exitGestureTitle => 'Botão de saída';

  @override
  String exitGestureValue(int seconds) {
    return 'Manter premido $seconds segundos e depois PIN';
  }

  @override
  String get guidedAccessOn => 'Ativado';

  @override
  String get guidedAccessOffShort => 'Desativado · toque para ver como ativar';

  @override
  String get browseYouTube => 'Explorar o YouTube';

  @override
  String get orPasteLink => 'ou cole um link';

  @override
  String get close => 'Fechar';

  @override
  String get back => 'Voltar';

  @override
  String get inPlaylist => 'Já está nesta lista';

  @override
  String addToNamedPlaylist(String title) {
    return 'Adicionar a “$title”';
  }

  @override
  String videoAddedNamed(String title) {
    return '“$title” adicionado';
  }
}
