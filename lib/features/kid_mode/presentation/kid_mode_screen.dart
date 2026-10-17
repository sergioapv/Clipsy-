import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/pin_dialog.dart';
import '../domain/kid_player.dart';
import '../domain/kid_session.dart';
import 'kid_mode_controller.dart';
import 'time_up_view.dart';
import 'widgets/hold_to_exit_button.dart';
import 'widgets/kid_thumbnail_strip.dart';
import 'widgets/time_badge.dart';

/// The child-facing player, locked to one playlist.
///
/// Exit paths blocked here: system back (PopScope), system bars (immersive
/// mode), taps into the YouTube player (see YoutubeKidPlayer), and on Android
/// Home/Recents via screen pinning. Leaving needs a long press plus the PIN.
class KidModeScreen extends ConsumerStatefulWidget {
  const KidModeScreen({super.key});

  @override
  ConsumerState<KidModeScreen> createState() => _KidModeScreenState();
}

class _KidModeScreenState extends ConsumerState<KidModeScreen> {
  late final ProviderSubscription<KidPlayer> _playerSub;
  late final KidPlayer _player;
  StreamSubscription<KidPlayerEvent>? _events;
  Timer? _ticker;
  late final AppLifecycleListener _lifecycle;
  int _loaded = 0;

  KidMode get _controller => ref.read(kidModeProvider.notifier);

  @override
  void initState() {
    super.initState();
    // Holding the subscription keeps the (auto-dispose) player alive for as
    // long as this screen exists.
    _playerSub = ref.listenManual(kidPlayerProvider, (_, _) {});
    _player = _playerSub.read();
    _events = _player.events.listen(_controller.onPlayerEvent);
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _controller.tick(),
    );
    _lifecycle = AppLifecycleListener(
      // No background playback (YouTube terms), and nothing plays unattended.
      onHide: () => unawaited(_player.pause()),
    );
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    unawaited(WakelockPlus.enable().catchError((Object _) {}));
    unawaited(ref.read(deviceLockProvider).startPinning());
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPlayer());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_events?.cancel());
    _lifecycle.dispose();
    _playerSub.close();
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    unawaited(WakelockPlus.disable().catchError((Object _) {}));
    super.dispose();
  }

  /// Loads the current video whenever the controller asks for it.
  void _syncPlayer() {
    final s = ref.read(kidModeProvider);
    final video = s?.session.currentVideo;
    if (s == null || video == null || s.loadRequest == _loaded) return;
    _loaded = s.loadRequest;
    unawaited(_player.load(video.youtubeId, autoplay: s.autoplay));
  }

  Future<void> _askPinThen(Future<void> Function() action) async {
    await _player.pause();
    if (!mounted) return;
    if (await showPinDialog(context)) await action();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(kidModeProvider, (prev, next) {
      if (next == null) return;
      if (next.loadRequest != prev?.loadRequest) _syncPlayer();
      if (next.session.isTimeUp && !(prev?.session.isTimeUp ?? false)) {
        unawaited(_player.pause());
      }
    });
    final state = ref.watch(kidModeProvider);
    final exitHold = ref.watch(kidSettingsProvider.select((s) => s.exitHold));

    return PopScope(
      canPop: false,
      child: Theme(
        data: AppTheme.kid(),
        child: Builder(
          builder: (context) {
            if (state == null) return const Scaffold();
            final exit = HoldToExitButton(
              holdDuration: exitHold,
              onHeld: () => unawaited(_askPinThen(_controller.exit)),
            );
            if (state.session.isTimeUp) {
              return TimeUpView(
                exitButton: exit,
                onParent: () => unawaited(
                  _askPinThen(() => showTimeUpParentOptions(context, ref)),
                ),
              );
            }
            return Scaffold(
              body: SafeArea(
                child: _KidLayout(
                  state: state,
                  player: _player.buildView(context),
                  exitButton: exit,
                  onPlayPause: () => unawaited(
                    state.isPlaying ? _player.pause() : _player.play(),
                  ),
                  onSelect: _controller.select,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _KidLayout extends StatelessWidget {
  const _KidLayout({
    required this.state,
    required this.player,
    required this.exitButton,
    required this.onPlayPause,
    required this.onSelect,
  });

  final KidModeState state;
  final Widget player;
  final Widget exitButton;
  final VoidCallback onPlayPause;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final session = state.session;

    final topBar = Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: TimeBadge(
                remaining: state.remaining,
                limit: session.clock.limit,
                almostDone: state.isAlmostDone,
                lastVideo: session.status == KidSessionStatus.finishingVideo,
              ),
            ),
          ),
        ),
        exitButton,
      ],
    );
    final playerBox = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(aspectRatio: 16 / 9, child: player),
    );
    final playButton = _PlayPauseButton(
      isPlaying: state.isPlaying,
      onPressed: onPlayPause,
    );
    final strip = KidThumbnailStrip(
      videos: session.videos,
      currentIndex: session.currentIndex,
      enabled: session.status == KidSessionStatus.watching,
      axis: landscape ? Axis.vertical : Axis.horizontal,
      onSelect: onSelect,
    );

    if (landscape) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  Expanded(child: Center(child: playerBox)),
                  const SizedBox(height: 8),
                  playButton,
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 260,
              child: Column(
                children: [
                  topBar,
                  const SizedBox(height: 8),
                  Expanded(child: strip),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          topBar,
          const SizedBox(height: 12),
          playerBox,
          const SizedBox(height: 20),
          playButton,
          const SizedBox(height: 20),
          Expanded(child: strip),
        ],
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.isPlaying, required this.onPressed});

  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: isPlaying ? l10n.kidPause : l10n.kidPlay,
      child: Material(
        key: const Key('kid-play-pause'),
        color: BrandColors.coral,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 96,
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 64,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
