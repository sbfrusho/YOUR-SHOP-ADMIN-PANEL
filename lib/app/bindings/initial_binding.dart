import 'package:get/get.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/session_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/order_repository.dart';

/// App-wide dependencies. Repositories are lazy singletons (`fenix`
/// recreates them if disposed).
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(AuthRepository.new, fenix: true);
    Get.lazyPut(OrderRepository.new, fenix: true);
    final auth = Get.put(AuthService(), permanent: true);
    Get.put(SessionService(auth, Get.find()), permanent: true);
  }
}
