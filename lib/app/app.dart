import 'package:flutter/material.dart';
import 'package:tuko_kadi_iebc_locator/app/router/app_router.dart';
import 'package:tuko_kadi_iebc_locator/app/theme/app_theme.dart';

class TukoKadiApp extends StatefulWidget {
  const TukoKadiApp({super.key});

  @override
  State<TukoKadiApp> createState() => _TukoKadiAppState();
}

class _TukoKadiAppState extends State<TukoKadiApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showSplash = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TUKO KADI IEBC Locator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      builder: (BuildContext context, Widget? child) {
        return Stack(
          children: <Widget>[
            if (child != null) child,
            IgnorePointer(
              ignoring: !_showSplash,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                opacity: _showSplash ? 1 : 0,
                child: const _StartupSplash(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StartupSplash extends StatefulWidget {
  const _StartupSplash();

  @override
  State<_StartupSplash> createState() => _StartupSplashState();
}

class _StartupSplashState extends State<_StartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    final Animation<Offset> slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    return ColoredBox(
      color: AppTheme.offWhite,
      child: Center(
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: Image.asset(
              'assets/branding/splash_logo.png',
              width: 190,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
