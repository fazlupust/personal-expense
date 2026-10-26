import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  AuthService get auth => Get.find<AuthService>();

  // Login controllers
  final phoneLoginCtrl = TextEditingController();
  final passwordLoginCtrl = TextEditingController();

  // Register controllers
  final phoneRegCtrl = TextEditingController();
  final passwordRegCtrl = TextEditingController();
  final nameBnCtrl = TextEditingController();
  final nameEnCtrl = TextEditingController();
  final designationBnCtrl = TextEditingController();
  final designationEnCtrl = TextEditingController();
  final addressBnCtrl = TextEditingController();
  final addressEnCtrl = TextEditingController();

  final RxBool obscurePassword = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onClose() {
    phoneLoginCtrl.dispose();
    passwordLoginCtrl.dispose();
    phoneRegCtrl.dispose();
    passwordRegCtrl.dispose();
    nameBnCtrl.dispose();
    nameEnCtrl.dispose();
    designationBnCtrl.dispose();
    designationEnCtrl.dispose();
    addressBnCtrl.dispose();
    addressEnCtrl.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.toggle();
  }

  Future<void> login() async {
    final phone = phoneLoginCtrl.text.trim();
    final pass = passwordLoginCtrl.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      errorMessage.value = 'Please enter phone number and password'.tr;
      return;
    }

    try {
      errorMessage.value = '';
      await auth.loginWithPhone(phone: phone, password: pass);
      Get.offAllNamed(AppRoutes.navigation);
    } catch (e) {
      errorMessage.value = 'Login failed. Please check phone & password.'.tr;
    }
  }

  Future<void> register() async {
    final phone = phoneRegCtrl.text.trim();
    final pass = passwordRegCtrl.text.trim();
    final nameBn = nameBnCtrl.text.trim();
    final nameEn = nameEnCtrl.text.trim();
    final designationBn = designationBnCtrl.text.trim();
    final designationEn = designationEnCtrl.text.trim();

    if (phone.isEmpty || pass.isEmpty) {
      errorMessage.value = 'Phone and password are required'.tr;
      return;
    }
    if (nameBn.isEmpty && nameEn.isEmpty) {
      errorMessage.value = 'Please provide a name'.tr;
      return;
    }

    try {
      errorMessage.value = '';
      await auth.registerWithPhone(
        phone: phone,
        password: pass,
        nameBn: nameBn,
        nameEn: nameEn,
        designationBn: designationBn,
        designationEn: designationEn,
        addressBn: addressBnCtrl.text.trim(),
        addressEn: addressEnCtrl.text.trim(),
      );
      Get.offAllNamed(AppRoutes.navigation);
    } catch (e) {
      errorMessage.value = 'Registration failed. $e';
    }
  }
}
