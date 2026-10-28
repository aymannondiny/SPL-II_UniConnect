import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uniconnect/core/theme/theme_preference.dart';
import 'package:uniconnect/features/authentication/view/gateway/iut_gateway_scene.dart';

/// Theme-aware transition shown exactly once after a successful login.
class PostLoginGatewayPage extends StatefulWidget {
  const PostLoginGatewayPage({required this.onComplete, super.key});

  /// The reference animation lasts 18.5 seconds. The approved playback speed
  /// is 2.5x, so construction lasts 7.4 seconds.
  static const originalDuration = Duration(milliseconds: 18500);
  static const playbackSpeed = 2.5;
  static const constructionDuration = Duration(milliseconds: 7400);
  static const completedFrameHold = Duration(milliseconds: 550);
  static const transitionDuration = Duration(milliseconds: 7950);
  static const reducedMotionHold = Duration(milliseconds: 250);

  final VoidCallback onComplete;

  static String backgroundAsset(AppearanceMode mode) => switch (mode) {
    AppearanceMode.light => 'assets/gateway/light.png',
    AppearanceMode.dark => 'assets/gateway/dark.png',
    AppearanceMode.engineering => 'assets/gateway/engineering.png',
  };

  @override
  State<PostLoginGatewayPage> createState() => _PostLoginGatewayPageState();
}

class _PostLoginGatewayPageState extends State<PostLoginGatewayPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: PostLoginGatewayPage.transitionDuration,
  );
  late final Animation<double> _constructionProgress = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 0, end: 1),
      weight: PostLoginGatewayPage.constructionDuration.inMilliseconds
          .toDouble(),
    ),
    TweenSequenceItem(
      tween: ConstantTween<double>(1),
      weight: PostLoginGatewayPage.completedFrameHold.inMilliseconds.toDouble(),
    ),
  ]).animate(_controller);
  Timer? _completionTimer;
  bool _started = false;
  bool _completed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mode = _appearanceMode(context);
    unawaited(
      precacheImage(
        AssetImage(PostLoginGatewayPage.backgroundAsset(mode)),
        context,
      ),
    );
    if (_started) return;
    _started = true;
    final reducedMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (reducedMotion) {
      _controller.value = 1;
      _completionTimer = Timer(
        PostLoginGatewayPage.reducedMotionHold,
        _complete,
      );
      return;
    }
    unawaited(
      _controller.forward().then((_) {
        _complete();
      }),
    );
  }

  @override
  void dispose() {
    _completionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _complete() {
    if (_completed || !mounted) return;
    _completed = true;
    _completionTimer?.cancel();
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final mode = _appearanceMode(context);
    final asset = PostLoginGatewayPage.backgroundAsset(mode);
    return Scaffold(
      key: const Key('post-login-gateway'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            key: Key('post-login-gateway-background-${mode.name}'),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
          SafeArea(
            minimum: const EdgeInsets.all(12),
            child: IutGatewayScene(progress: _constructionProgress),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Semantics(
                  button: true,
                  label: 'Skip welcome animation',
                  child: TextButton(
                    key: const Key('post-login-gateway-skip'),
                    onPressed: _complete,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0x66000000),
                      minimumSize: const Size(48, 40),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static AppearanceMode _appearanceMode(BuildContext context) {
    final preference = ThemePreference.maybeOf(context);
    if (preference != null) return preference.value;
    return Theme.of(context).brightness == Brightness.light
        ? AppearanceMode.light
        : AppearanceMode.dark;
  }
}
