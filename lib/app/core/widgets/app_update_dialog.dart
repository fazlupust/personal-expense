import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/app_update_model.dart';
import '../../data/services/app_update_service.dart';
import '../theme/app_theme.dart';

class AppUpdateDialog extends StatelessWidget {
  const AppUpdateDialog({
    super.key,
    required this.updateModel,
    required this.currentVersion,
  });

  final AppUpdateModel updateModel;
  final String currentVersion;

  Future<void> _launchUpdateUrl(BuildContext context) async {
    final rawUrl = updateModel.playStoreUrl.trim();
    if (rawUrl.isEmpty) return;

    final uri = Uri.tryParse(rawUrl);
    if (uri != null) {
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          Get.snackbar(
            'Error'.tr,
            'Unable to open link'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (_) {
        Get.snackbar(
          'Error'.tr,
          'Unable to open link'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isForce = updateModel.isForceUpdate;

    return PopScope(
      canPop: !isForce,
      onPopInvokedWithResult: (didPop, _) {
        // If force update, do not allow dismiss
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Icon with soft gradient background
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        isForce ? const Color(0xFFDC2626) : const Color(0xFF0D9488),
                        isForce ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isForce ? const Color(0xFFDC2626) : const Color(0xFF10B981)).withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.rocket_launch_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Badge (Mandatory or New Version)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isForce
                        ? p.expense.withOpacity(0.12)
                        : p.income.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    (isForce ? 'Mandatory Update' : 'New Version Available').tr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isForce ? p.expense : p.income,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  updateModel.title.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 8),

                // Version Badge (Current -> Latest)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: p.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: p.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'v$currentVersion',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: p.mute,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: p.acc),
                      const SizedBox(width: 8),
                      Text(
                        'v${updateModel.latestVersion}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: p.income,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Message description
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 160),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.bg.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.line.withOpacity(0.5)),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      updateModel.message,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: p.ink.withOpacity(0.85),
                      ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                if (isForce) ...[
                  // Single Button for Force Update
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDC2626).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _launchUpdateUrl(context),
                      icon: const Icon(Icons.system_update_rounded, size: 20, color: Colors.white),
                      label: Text(
                        'Update Now'.tr,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Two Buttons: Update Later and Update Now
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE11D48).withOpacity(0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (Get.isRegistered<AppUpdateService>()) {
                                AppUpdateService.to.dismissOptional(updateModel.latestVersion);
                              }
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Update Later'.tr,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D9488), Color(0xFF10B981)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _launchUpdateUrl(context),
                            icon: const Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.white),
                            label: Text(
                              'Update Now'.tr,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
