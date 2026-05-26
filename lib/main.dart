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

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HomeHeader(),
              const SizedBox(height: 16),
              const _TodayScoreCard(),
              const SizedBox(height: 12),
              const _QuickActions(),
              const SizedBox(height: 12),
              const _TodaySection(),
              const SizedBox(height: 12),
              const _ContributionCard(),
              const SizedBox(height: 12),
              const _InsightCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            AppAssets.dashboardIcon,
            width: 182,
            height: 78,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 8),
          const Text(
            'Offline productivity workspace',
            style: TextStyle(
              color: Color(0xFF444444),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 2,
            width: double.infinity,
            color: const Color(0xFF111111),
          ),
        ],
      ),
    );
  }
}

class _TodayScoreCard extends StatelessWidget {
  const _TodayScoreCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('TODAY SCORE'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                '72%',
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Your daily workspace is clear and ready.',
                    style: TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _ProgressText(title: '5 of 7 habits completed', value: '71%'),
          const SizedBox(height: 8),
          const _ProgressText(
            title: '3 priority tasks completed',
            value: '60%',
          ),
        ],
      ),
    );
  }
}

class _ProgressText extends StatelessWidget {
  const _ProgressText({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _ActionBox(icon: Icons.add, text: 'Add Habit'),
        ),
        SizedBox(width: 9),
        Expanded(
          child: _ActionBox(icon: Icons.task_alt, text: 'Add Task'),
        ),
        SizedBox(width: 9),
        Expanded(
          child: _ActionBox(icon: Icons.checklist, text: 'Check Today'),
        ),
      ],
    );
  }
}

class _ActionBox extends StatelessWidget {
  const _ActionBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF111111), size: 22),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111111),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  const _TodaySection();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Label('TODAY HABITS'),
          SizedBox(height: 12),
          _ListItem(title: 'Read 20 pages', subtitle: 'Habit', status: 'Done'),
          _Line(),
          _ListItem(
            title: 'Workout 30 minutes',
            subtitle: 'Habit',
            status: 'Pending',
          ),
          _Line(),
          _ListItem(title: 'Study Flutter', subtitle: 'Habit', status: 'Today'),
          SizedBox(height: 16),
          _Label('PRIORITY TASKS'),
          SizedBox(height: 12),
          _ListItem(
            title: 'Finish loading screen UI',
            subtitle: 'Task',
            status: 'High',
          ),
          _Line(),
          _ListItem(
            title: 'Prepare asset folder',
            subtitle: 'Task',
            status: 'Medium',
          ),
          _Line(),
          _ListItem(
            title: 'Review dashboard layout',
            subtitle: 'Task',
            status: 'Medium',
          ),
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  const _ListItem({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    final bool done = status == 'Done' || status == 'High';

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          color: done ? const Color(0xFF111111) : const Color(0xFFCFCFCF),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          status,
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ContributionCard extends StatelessWidget {
  const _ContributionCard();

  @override
  Widget build(BuildContext context) {
    final values = <int>[4, 3, 1, 0, 2, 4, 3, 1, 2, 0, 4, 3, 2, 1];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('MINI CONTRIBUTION PREVIEW'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values.map((value) {
              return Container(width: 16, height: 16, color: _shade(value));
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            'Last 14 days activity based on habit and task completion.',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _shade(int value) {
    if (value <= 0) return const Color(0xFFEDEDED);
    if (value == 1) return const Color(0xFFCFCFCF);
    if (value == 2) return const Color(0xFF9E9E9E);
    if (value == 3) return const Color(0xFF555555);
    return const Color(0xFF111111);
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.trending_up, color: Color(0xFF111111), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are more consistent than last week. Complete the remaining priority items and keep today clean.',
              style: TextStyle(
                color: Color(0xFF111111),
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = const EdgeInsets.all(15)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: const Color(0xFFD6D6D6), width: 1),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF111111),
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFFE0E0E0),
    );
  }
}

class FullScreenVideo extends StatelessWidget {
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
