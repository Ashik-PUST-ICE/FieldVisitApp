import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

class OfflineQueueService {
  static const String _boxName = 'offline_queue';
  final Uuid _uuid = const Uuid();

  Future<void> enqueue(Map<String, dynamic> task) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_uuid.v4(), {
      'endpoint': task['endpoint'],
      'method': task['method'] ?? 'POST',
      'body': task['body'],
      'headers': task['headers'] ?? {},
      'queued_at': DateTime.now().toIso8601String(),
      'retries': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPending() async {
    final box = await Hive.openBox(_boxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> remove(String key) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(key);
  }

  Future<void> clear() async {
    final box = await Hive.openBox(_boxName);
    await box.clear();
  }
}
