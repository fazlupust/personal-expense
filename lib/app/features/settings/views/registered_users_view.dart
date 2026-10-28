import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/core/constants/app_constants.dart';
import '../../../../app/core/theme/app_theme.dart';
import '../../../../app/core/utils/formatters.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/transaction_service.dart';

class RegisteredUsersView extends StatefulWidget {
  const RegisteredUsersView({super.key});

  @override
  State<RegisteredUsersView> createState() => _RegisteredUsersViewState();
}

class _RegisteredUsersViewState extends State<RegisteredUsersView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: cleaned));
        if (mounted) {
          Get.snackbar(
            AppConstants.appName.tr,
            'Phone number copied to clipboard'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: cleaned));
      if (mounted) {
        Get.snackbar(
          AppConstants.appName.tr,
          'Phone number copied to clipboard'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  void _showUserDetails(BuildContext context, UserModel u, int txCount, AppPalette p, bool isBn) {
    final joinedDate = u.createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(u.createdAt!)
        : 'N/A';
    final lastLogin = u.lastLoginAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(u.lastLoginAt!)
        : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: Material(
            color: p.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar with Drag Handle and Close
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: p.line,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: p.income.withOpacity(0.15),
                          child: Text(
                            u.displayName(isBn).isNotEmpty
                                ? u.displayName(isBn).substring(0, 1).toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: p.income,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      u.displayName(isBn).isNotEmpty
                                          ? u.displayName(isBn)
                                          : 'Personal Expense User'.tr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: p.ink,
                                      ),
                                    ),
                                  ),
                                  if (u.userNo != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: p.income.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '#${u.userNo}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: p.income,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: u.isDeveloper
                                      ? p.income.withOpacity(0.15)
                                      : p.bg,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: u.isDeveloper ? p.income : p.line,
                                  ),
                                ),
                                child: Text(
                                  u.isDeveloper ? 'Developer' : 'App User',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: u.isDeveloper ? p.income : p.mute,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(ctx).pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: p.bg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close_rounded, color: p.ink, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Divider(color: p.line, height: 1),
                    const SizedBox(height: 16),

                    // Information Rows
                    _buildDetailTile(
                      icon: Icons.badge_outlined,
                      title: 'Name (EN / বাংলা)'.tr,
                      value: '${u.nameEn.isNotEmpty ? u.nameEn : '-'}'
                          '${u.nameBn.isNotEmpty ? ' · ${u.nameBn}' : ''}',
                      p: p,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailTile(
                      icon: Icons.receipt_long_rounded,
                      title: 'Total Transactions'.tr,
                      value: '$txCount ${'entries'.tr}',
                      p: p,
                    ),
                    if (u.phone != null && u.phone!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailTile(
                        icon: Icons.phone_rounded,
                        title: 'Phone Number'.tr,
                        value: u.phone!,
                        p: p,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.call_rounded, color: p.income, size: 20),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Call'.tr,
                              onPressed: () => _makeCall(u.phone!),
                            ),
                            IconButton(
                              icon: Icon(Icons.copy_rounded, color: p.mute, size: 18),
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Copy'.tr,
                              onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: u.phone!));
                                Get.snackbar(
                                  AppConstants.appName.tr,
                                  'Phone number copied'.tr,
                                  snackPosition: SnackPosition.BOTTOM,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (u.email != null && u.email!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailTile(
                        icon: Icons.email_outlined,
                        title: 'Email Address'.tr,
                        value: u.email!,
                        p: p,
                      ),
                    ],
                    if (u.displayDesignation(isBn).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailTile(
                        icon: Icons.work_outline_rounded,
                        title: 'Designation'.tr,
                        value: '${u.designationEn.isNotEmpty ? u.designationEn : ''}'
                            '${u.designationBn.isNotEmpty ? (u.designationEn.isNotEmpty ? ' · ' : '') + u.designationBn : ''}',
                        p: p,
                      ),
                    ],
                    if (u.addressEn != null && u.addressEn!.isNotEmpty ||
                        u.addressBn != null && u.addressBn!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailTile(
                        icon: Icons.location_on_outlined,
                        title: 'Address'.tr,
                        value: (isBn && u.addressBn?.isNotEmpty == true)
                            ? u.addressBn!
                            : (u.addressEn ?? u.addressBn ?? ''),
                        p: p,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildDetailTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Joined Date'.tr,
                      value: joinedDate,
                      p: p,
                    ),
                    if (lastLogin != null) ...[
                      const SizedBox(height: 12),
                      _buildDetailTile(
                        icon: Icons.access_time_rounded,
                        title: 'Last Login'.tr,
                        value: '$lastLogin${u.lastLoginDevice != null ? ' (${u.lastLoginDevice})' : ''}',
                        p: p,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.income,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text('Close'.tr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String title,
    required String value,
    required AppPalette p,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: p.income, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: p.mute),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.ink),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isBn = Get.locale?.languageCode == 'bn';
    final auth = Get.isRegistered<AuthService>() ? Get.find<AuthService>() : null;
    final txService = Get.isRegistered<TransactionService>() ? Get.find<TransactionService>() : null;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.income,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Registered App Users'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: auth == null
          ? Center(child: Text('Service not available'.tr))
          : StreamBuilder<Map<String, int>>(
              stream: txService?.streamAllUserTransactionCounts() ?? const Stream.empty(),
              builder: (context, txSnap) {
                final txCounts = txSnap.data ?? {};

                return StreamBuilder<List<UserModel>>(
                  stream: auth.streamAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: p.income),
                      );
                    }

                    final allUsers = snapshot.data ?? [];
                    final q = _searchQuery.trim().toLowerCase();

                    final filteredUsers = allUsers.where((u) {
                      if (q.isEmpty) return true;
                      final nameEn = u.nameEn.toLowerCase();
                      final nameBn = u.nameBn.toLowerCase();
                      final phone = (u.phone ?? '').toLowerCase();
                      final desigEn = u.designationEn.toLowerCase();
                      final desigBn = u.designationBn.toLowerCase();
                      final numStr = u.userNo != null ? '#${u.userNo}' : '';
                      return nameEn.contains(q) ||
                          nameBn.contains(q) ||
                          phone.contains(q) ||
                          desigEn.contains(q) ||
                          desigBn.contains(q) ||
                          numStr.contains(q);
                    }).toList();

                    final totalTx = txCounts.values.fold<int>(0, (a, b) => a + b);

                    return Column(
                      children: [
                        // Search Bar and Count Header
                        Container(
                          color: p.card,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Column(
                            children: [
                              TextField(
                                controller: _searchCtrl,
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                                style: TextStyle(fontSize: 14, color: p.ink),
                                decoration: InputDecoration(
                                  hintText: 'Search by name, phone, designation...'.tr,
                                  hintStyle: TextStyle(fontSize: 13.5, color: p.mute),
                                  prefixIcon: Icon(Icons.search_rounded, color: p.mute, size: 20),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.close_rounded, color: p.mute, size: 18),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            setState(() {
                                              _searchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  filled: true,
                                  fillColor: p.bg,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: p.line),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: p.line),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(color: p.income, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${'Total Users:'.tr} ${Fmt.count(allUsers.length)} · ${'Total Entries:'.tr} ${Fmt.count(totalTx)}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: p.mute,
                                    ),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    Text(
                                      '${'Found:'.tr} ${Fmt.count(filteredUsers.length)}',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: p.income,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // User List
                        Expanded(
                          child: filteredUsers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.people_outline_rounded, size: 48, color: p.mute),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isNotEmpty
                                            ? 'No matching users found'.tr
                                            : 'No registered users found'.tr,
                                        style: TextStyle(fontSize: 14, color: p.mute, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                                  itemCount: filteredUsers.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final u = filteredUsers[index];
                                    final name = u.displayName(isBn);
                                    final desig = u.displayDesignation(isBn);
                                    final phone = u.phone ?? '';
                                    final txCount = txCounts[u.uid] ?? u.transactionCount ?? 0;

                                    return Material(
                                      color: p.card,
                                      borderRadius: BorderRadius.circular(14),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () => _showUserDetails(context, u, txCount, p, isBn),
                                        child: Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: p.line),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                radius: 22,
                                                backgroundColor: p.income.withOpacity(0.12),
                                                child: Text(
                                                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: p.income,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            name.isEmpty ? 'Personal Expense User'.tr : name,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 14.5,
                                                              fontWeight: FontWeight.w700,
                                                              color: p.ink,
                                                            ),
                                                          ),
                                                        ),
                                                        if (u.userNo != null) ...[
                                                          const SizedBox(width: 6),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 6, vertical: 1),
                                                            decoration: BoxDecoration(
                                                              color: p.bg,
                                                              borderRadius: BorderRadius.circular(4),
                                                              border: Border.all(color: p.line),
                                                            ),
                                                            child: Text(
                                                              '#${u.userNo}',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight: FontWeight.w800,
                                                                color: p.mute,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                        if (u.isDeveloper) ...[
                                                          const SizedBox(width: 6),
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 5, vertical: 1),
                                                            decoration: BoxDecoration(
                                                              color: p.income.withOpacity(0.12),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              'Dev'.tr,
                                                              style: TextStyle(
                                                                fontSize: 9.5,
                                                                fontWeight: FontWeight.w800,
                                                                color: p.income,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                        const SizedBox(width: 6),
                                                        // Transaction count badge beside user
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 6, vertical: 1.5),
                                                          decoration: BoxDecoration(
                                                            color: txCount > 0 ? p.income.withOpacity(0.12) : p.bg,
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(
                                                              color: txCount > 0 ? p.income.withOpacity(0.35) : p.line,
                                                            ),
                                                          ),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(
                                                                Icons.receipt_long_rounded,
                                                                size: 11,
                                                                color: txCount > 0 ? p.income : p.mute,
                                                              ),
                                                              const SizedBox(width: 3),
                                                              Text(
                                                                '$txCount ${'entries'.tr}',
                                                                style: TextStyle(
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w700,
                                                                  color: txCount > 0 ? p.income : p.mute,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    if (desig.isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        desig,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(fontSize: 12, color: p.mute),
                                                      ),
                                                    ],
                                                    if (phone.isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(Icons.phone_outlined, size: 12.5, color: p.income),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            phone,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                              color: p.ink,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Container(
                                                            width: 3,
                                                            height: 3,
                                                            decoration: BoxDecoration(
                                                              color: p.mute.withOpacity(0.6),
                                                              shape: BoxShape.circle,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Icon(
                                                            Icons.receipt_long_rounded,
                                                            size: 12,
                                                            color: txCount > 0 ? p.income : p.mute,
                                                          ),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            '$txCount ${'entries'.tr}',
                                                            style: TextStyle(
                                                              fontSize: 11.5,
                                                              fontWeight: FontWeight.w600,
                                                              color: txCount > 0 ? p.income : p.mute,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ] else ...[
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.receipt_long_rounded,
                                                            size: 12,
                                                            color: txCount > 0 ? p.income : p.mute,
                                                          ),
                                                          const SizedBox(width: 3),
                                                          Text(
                                                            '$txCount ${'entries'.tr}',
                                                            style: TextStyle(
                                                              fontSize: 11.5,
                                                              fontWeight: FontWeight.w600,
                                                              color: txCount > 0 ? p.income : p.mute,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (phone.isNotEmpty)
                                                IconButton(
                                                  icon: Icon(Icons.call_rounded, color: p.income, size: 20),
                                                  tooltip: 'Call'.tr,
                                                  onPressed: () => _makeCall(phone),
                                                ),
                                              Icon(Icons.chevron_right_rounded, color: p.mute, size: 20),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
