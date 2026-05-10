import '../../../core/logging/app_logger.dart';
import 'terabox_client.dart';

class TeraboxUserInfo {
  const TeraboxUserInfo({
    required this.userId,
    required this.displayName,
    required this.email,
  });

  final String userId;
  final String displayName;
  final String email;
}

class TeraboxFileItem {
  const TeraboxFileItem({
    required this.fsId,
    required this.name,
    required this.path,
    required this.isFolder,
    required this.modifiedAt,
    this.sizeBytes,
  });

  final String fsId;
  final String name;
  final String path;
  final bool isFolder;
  final DateTime modifiedAt;
  final int? sizeBytes;
}

class TeraboxApi {
  TeraboxApi({required this.client});

  final TeraboxClient client;

  Future<TeraboxUserInfo> getUserInfo() async {
    final resp = await client.get<Map<String, dynamic>>(
      '/rest/2.0/passport/users/info',
    );
    final data = resp.data!;
    return TeraboxUserInfo(
      userId: data['uk']?.toString() ?? '',
      displayName: data['baidu_name'] as String? ?? data['netdisk_name'] as String? ?? '',
      email: data['email'] as String? ?? '',
    );
  }

  Future<void> testConnection() async {
    logger.log('TeraboxApi', 'testConnection() starting…');
    await getUserInfo();
    logger.log('TeraboxApi', 'testConnection() OK');
  }

  Stream<List<TeraboxFileItem>> streamAllFiles({String dir = '/'}) async* {
    logger.log('TeraboxApi', 'streamAllFiles() dir=$dir');
    int page = 1;
    int totalItems = 0;

    while (true) {
      final resp = await client.get<Map<String, dynamic>>(
        '/rest/2.0/xpan/file',
        queryParameters: {
          'method': 'list',
          'dir': dir,
          'order': 'name',
          'start': ((page - 1) * 100).toString(),
          'limit': '100',
          'web': 'web',
        },
      );

      final data = resp.data!;
      final errno = data['errno'] as int? ?? 0;
      if (errno != 0) {
        logger.error('TeraboxApi', 'API error errno=$errno');
        break;
      }

      final list = (data['list'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      if (list.isEmpty) break;

      final items = list.map(_mapItem).toList();
      totalItems += items.length;
      logger.log('TeraboxApi', 'streamAllFiles() page=$page items=${items.length} total=$totalItems');
      yield items;

      // Recurse into subdirectories
      for (final item in items.where((i) => i.isFolder)) {
        yield* streamAllFiles(dir: item.path);
      }

      if (list.length < 100) break;
      page++;
    }

    logger.log('TeraboxApi', 'streamAllFiles() done dir=$dir total=$totalItems');
  }

  TeraboxFileItem _mapItem(Map<String, dynamic> e) {
    final isFolder = (e['isdir'] as int? ?? 0) == 1;
    final mtime = e['server_mtime'] as int? ?? 0;
    return TeraboxFileItem(
      fsId: e['fs_id']?.toString() ?? '',
      name: e['server_filename'] as String? ?? '',
      path: e['path'] as String? ?? '/',
      isFolder: isFolder,
      modifiedAt: DateTime.fromMillisecondsSinceEpoch(mtime * 1000),
      sizeBytes: isFolder ? null : e['size'] as int?,
    );
  }
}
