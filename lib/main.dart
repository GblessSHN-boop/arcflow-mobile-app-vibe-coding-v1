import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ARCFlowApp());
}

class ARCFlowApp extends StatelessWidget {
  const ARCFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARCFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.black,
      ),
      home: const CompanyIntroScreen(),
    );
  }
}

class AppColors {
  const AppColors._();

  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF18008E);
  static const Color accent = Color(0xFF7220D1);
  static const Color highlight = Color(0xFFE182F9);
  static const Color panel = Color(0xD9000000);
  static const Color border = Color(0xFF241B3D);
  static const Color softText = Color(0xFFB8B8C8);
}

class AppAssets {
  const AppAssets._();

  static const String companyIntroVideo =
      'assets/videos/splash/company_intro/arcdev_company_intro_loading_screen_v1_0.mp4';

  static const String loadingRenderingVideo =
      'assets/videos/loading/loading_rendering/loading_screen_rendering.mp4';

  static const String dashboardIcon =
      'assets/brand/arcflow/logo_kit/app_icon/arcflow_app_icon_v1_0.png';
}

class CompanyIntroScreen extends StatefulWidget {
  const CompanyIntroScreen({super.key});

  @override
  State<CompanyIntroScreen> createState() => _CompanyIntroScreenState();
}

class _CompanyIntroScreenState extends State<CompanyIntroScreen> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(AppAssets.companyIntroVideo)
      ..setLooping(false)
      ..addListener(_checkVideoFinished);

    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _initialized = true);
          _controller.play();
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() => _hasError = true);
          Future.delayed(const Duration(seconds: 2), _goToLoadingRendering);
        });
  }

  void _checkVideoFinished() {
    if (!_controller.value.isInitialized || _navigated) return;

    final duration = _controller.value.duration;
    final position = _controller.value.position;

    if (duration != Duration.zero &&
        position >= duration - const Duration(milliseconds: 250)) {
      _goToLoadingRendering();
    }
  }

  void _goToLoadingRendering() {
    if (!mounted || _navigated) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: animation,
            child: const LoadingRenderingScreen(),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_checkVideoFinished);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.black)),
          if (_initialized)
            Positioned.fill(child: FullScreenVideo(controller: _controller)),
          if (_hasError)
            const Center(
              child: Text(
                'ARCDEV',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LoadingRenderingScreen extends StatefulWidget {
  const LoadingRenderingScreen({super.key});

  @override
  State<LoadingRenderingScreen> createState() => _LoadingRenderingScreenState();
}

class _LoadingRenderingScreenState extends State<LoadingRenderingScreen> {
  late final VideoPlayerController _controller;
  Timer? _progressTimer;

  bool _videoReady = false;
  bool _navigated = false;

  double _displayProgress = 0.01;
  double _targetProgress = 0.01;

  int get _percent => (_displayProgress * 100).clamp(1, 100).round();

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(AppAssets.loadingRenderingVideo)
      ..setLooping(true);

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _videoReady = true);
      _controller.play();
    });

    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 28),
      (_) => _updateProgress(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepareApplication();
    });
  }

  Future<void> _prepareApplication() async {
    await Future.delayed(const Duration(milliseconds: 350));
    _setTargetProgress(0.16);

    if (!mounted) return;
    await precacheImage(const AssetImage(AppAssets.dashboardIcon), context);
    _setTargetProgress(0.34);

    await Future.delayed(const Duration(milliseconds: 500));
    _setTargetProgress(0.52);

    await Future.delayed(const Duration(milliseconds: 500));
    _setTargetProgress(0.70);

    await Future.delayed(const Duration(milliseconds: 500));
    _setTargetProgress(0.86);

    await Future.delayed(const Duration(milliseconds: 450));
    _setTargetProgress(1.0);
  }

  void _setTargetProgress(double value) {
    if (!mounted) return;
    setState(() {
      _targetProgress = value.clamp(0.01, 1.0).toDouble();
    });
  }

  void _updateProgress() {
    if (!mounted || _navigated) return;

    if (_displayProgress < _targetProgress) {
      setState(() {
        _displayProgress = (_displayProgress + 0.006)
            .clamp(0.01, _targetProgress)
            .toDouble();
      });
    }

    if (_targetProgress >= 1.0 && _displayProgress >= 0.999) {
      _goToDashboard();
    }
  }

  void _goToDashboard() {
    if (!mounted || _navigated) return;
    _navigated = true;

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 850),
          pageBuilder: (_, animation, __) {
            return FadeTransition(
              opacity: animation,
              child: const HomeDashboardScreen(),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _percent >= 100;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.black)),
          if (_videoReady)
            Align(
              alignment: const Alignment(0, -0.22),
              child: LoadingVideoFrame(controller: _controller),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.black.withOpacity(0.25),
                    Colors.transparent,
                    AppColors.black.withOpacity(0.58),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.70),
            child: LoadingProgressPanel(
              percent: _percent,
              progress: _displayProgress,
              ready: ready,
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingVideoFrame extends StatelessWidget {
  const LoadingVideoFrame({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final value = controller.value;
    final videoSize = value.size;

    final frameWidth = screen.width * 0.82;
    final frameHeight = screen.height * 0.46;

    if (!value.isInitialized || videoSize.width <= 0 || videoSize.height <= 0) {
      return SizedBox(
        width: frameWidth,
        height: frameHeight,
        child: const ColoredBox(color: AppColors.black),
      );
    }

    return SizedBox(
      width: frameWidth,
      height: frameHeight,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: videoSize.width,
          height: videoSize.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class LoadingProgressPanel extends StatelessWidget {
  const LoadingProgressPanel({
    super.key,
    required this.percent,
    required this.progress,
    required this.ready,
  });

  final int percent;
  final double progress;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 286,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(
          color: AppColors.highlight.withOpacity(0.75),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ready ? 'Ready' : 'Rendering Application',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: AppColors.highlight,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            width: double.infinity,
            color: AppColors.border,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0).toDouble(),
              child: Container(height: 3, color: AppColors.highlight),
            ),
          ),
          const SizedBox(height: 9),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Preparing ARCFlow workspace',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.softText,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

C:\Users\Gland Siahaanclass FullScreenVideo extends StatelessWidget {
  const FullScreenVideo({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final value = controller.value;
    final size = value.size;

    if (!value.isInitialized || size.width <= 0 || size.height <= 0) {
      return const ColoredBox(color: AppColors.black);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

