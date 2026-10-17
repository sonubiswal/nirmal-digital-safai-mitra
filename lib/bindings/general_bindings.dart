import 'package:get/get.dart';
import 'package:nirmal/common/widgets/network_manager.dart';

class GeneralBindings extends Bindings{

  @override
  void dependencies() {
    Get.put(NetworkManager());
    
  }
}
