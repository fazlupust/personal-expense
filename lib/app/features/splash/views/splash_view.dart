import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo container with shadow and smooth rounded corners
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: p.income.withOpacity(0.25),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 110,
                      color: p.income,
                      alignment: Alignment.center,
                      child: const Icon(Icons.account_balance_wallet, size: 54, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Name
              Text(
                'Personal Expense'.tr,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Slogan
              Text(
                'Track • Save • Grow',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: p.mute,
                  letterSpacing: 1.2,
                ),
              ),

              const Spacer(),

              // Loading Spinner
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(p.income),
                ),
              ),
              const SizedBox(height: 20),

              // Version Tag
              Obx(
                () => Text(
                  controller.appVersion.value.isNotEmpty
                      ? controller.appVersion.value
                      : 'v1.0.0',
                  style: TextStyle(fontSize: 12, color: p.mute.withOpacity(0.6)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
