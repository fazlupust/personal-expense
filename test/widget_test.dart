import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense/app/data/services/app_update_service.dart';

void main() {
  test('AppUpdateService version comparison test', () {
    expect(AppUpdateService.isVersionHigher('1.1.0', '1.0.0'), isTrue);
    expect(AppUpdateService.isVersionHigher('2.0.0', '1.9.9'), isTrue);
    expect(AppUpdateService.isVersionHigher('1.0.1', '1.0.0'), isTrue);
    expect(AppUpdateService.isVersionHigher('1.0.0', '1.0.0'), isFalse);
    expect(AppUpdateService.isVersionHigher('1.0.0', '1.1.0'), isFalse);
    expect(AppUpdateService.isVersionHigher('v1.2.0', '1.1.0'), isTrue);
  });
}
