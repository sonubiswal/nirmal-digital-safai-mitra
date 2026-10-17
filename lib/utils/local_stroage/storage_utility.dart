import 'package:get_storage/get_storage.dart';

class TLocalStorage {
  static final TLocalStorage _instance = TLocalStorage._internal();
  
  factory TLocalStorage() {
    return _instance;
  }
  
  TLocalStorage._internal();

  static GetStorage? _storage;

  // Initialize GetStorage
  static Future<void> init() async {
    await GetStorage.init();
    _storage = GetStorage();
  }

  // Save data
  static Future<void> saveData<T>(String key, T value) async {
    await _storage?.write(key, value);
  }

  // Read data
  static T? readData<T>(String key) {
    return _storage?.read<T>(key);
  }

  // Delete data
  static Future<void> removeData(String key) async {
    await _storage?.remove(key);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _storage?.erase();
  }

  // Check if key exists
  static bool containsKey(String key) {
    return _storage?.hasData(key) ?? false;
  }

  // Get all keys
  static List<String> getKeys() {
    return _storage?.getKeys().toList() ?? [];
  }

  // Get storage instance
  static GetStorage? get instance => _storage;
  
  // Check if initialized
  static bool get isInitialized => _storage != null;
}