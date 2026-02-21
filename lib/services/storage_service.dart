import 'dart:io';
import 'supabase_client.dart';

class StorageService {
  static Future<String?> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      await SupabaseConfig.client.storage.from(bucket).upload(path, file);
      final url = SupabaseConfig.client.storage.from(bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      // bom para debug; depois troque por logger
      print('Erro ao fazer upload: $e');
      return null;
    }
  }
}
