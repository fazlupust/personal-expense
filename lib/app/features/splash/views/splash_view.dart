import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is created
    Get.put(SplashController());
    final p = context.pal;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient glowing radial aura behind logo
            Positioned(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      p.income.withOpacity(0.14),
                      p.income.withOpacity(0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Animated entrance for logo and branding
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.85, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Luxury Wallet Logo Container with multi-layered glow
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: p.income.withOpacity(0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: p.income.withOpacity(0.35),
                                blurRadius: 36,
                                offset: const Offset(0, 14),
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28.5),
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 120,
                                height: 120,
                                color: p.income,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  size: 58,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // App Name
                        Text(
                          AppConstants.appName.tr,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: p.ink,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Slogan Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: p.income.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: p.income.withOpacity(0.2)),
                          ),
                          child: Text(
                            'Smart Money • Effortless Control'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.income,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Loading Spinner
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation<Color>(p.income),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Version Tag
                  Obx(
                    () => Text(
                      controller.appVersion.value.isNotEmpty
                          ? '${AppConstants.appName} ${controller.appVersion.value}'
                          : AppConstants.appName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: p.mute.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Privacy & Security indicator
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 12, color: p.mute.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        '100% Private & Secure',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: p.mute.withOpacity(0.5),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
