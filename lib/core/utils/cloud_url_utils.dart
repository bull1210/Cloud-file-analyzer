import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/cloud_account.dart';
import '../../domain/models/cloud_file.dart';

class CloudUrlUtils {
  CloudUrlUtils._();

  static String buildWebUrl(CloudFile file) {
    switch (file.provider) {
      case CloudProvider.google:
        if (file.isFolder) {
          return 'https://drive.google.com/drive/folders/${file.providerFileId}';
        }
        return 'https://drive.google.com/file/d/${file.providerFileId}/view';
      case CloudProvider.microsoft:
        final q = Uri.encodeComponent(file.name);
        return 'https://onedrive.live.com/?qt=search&q=$q';
      case CloudProvider.dropbox:
        return 'https://www.dropbox.com/home${file.path}';
      case CloudProvider.terabox:
        return 'https://www.terabox.com/';
      case CloudProvider.mega:
        return 'https://mega.nz/';
      case CloudProvider.apple:
        return 'https://www.icloud.com/';
    }
  }

  static Future<void> openFile(CloudFile file) async {
    final uri = Uri.parse(buildWebUrl(file));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
