import '../../../core/errors/app_exception.dart';
import '../../../core/logging/app_logger.dart';
import 'mega_client.dart';

class MegaApi {
  MegaApi({required this.client});

  final MegaClient client;

  Future<void> testConnection() async {
    logger.log('MegaApi', 'testConnection() — MEGA SDK integration pending');
    throw const ScanException(
      'MEGA scanning requires additional setup.\n\n'
      'MEGA uses end-to-end encryption with proprietary key derivation. '
      'Full file metadata access requires integrating the mega_sdk package.\n\n'
      'Your MEGA account has been added and will scan automatically once '
      'the mega_sdk integration is complete in a future update.',
    );
  }
}
