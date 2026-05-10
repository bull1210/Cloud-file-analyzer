class GoogleDriveEndpoints {
  GoogleDriveEndpoints._();

  static const String baseUrl = 'https://www.googleapis.com';
  static const String filesList = '/drive/v3/files';
  static const String aboutDrive = '/drive/v3/about';
  static const String userInfo = '/oauth2/v2/userinfo';

  // Fields to fetch per file (metadata only — no content).
  // md5Checksum is included for exact-match duplicate detection.
  // It is null for Google-native formats (Docs/Sheets/Slides) which have no binary content.
  static const String fileFields =
      'id,name,mimeType,size,md5Checksum,modifiedTime,viewedByMeTime,parents,trashed,shortcutDetails';

  static const String listFields =
      'nextPageToken,files($fileFields)';
}

class DropboxEndpoints {
  DropboxEndpoints._();

  static const String baseUrl = 'https://api.dropboxapi.com/2';
  static const String listFolder = '/files/list_folder';
  static const String listFolderContinue = '/files/list_folder/continue';
  static const String getCurrentAccount = '/users/get_current_account';
  static const String revokeToken = '/auth/token/revoke';
}

class TeraboxEndpoints {
  TeraboxEndpoints._();

  static const String baseUrl = 'https://openapi.terabox.com';
  static const String fileList = '/rest/2.0/xpan/file';
  static const String userInfo = '/rest/2.0/passport/users/info';
}

class MegaEndpoints {
  MegaEndpoints._();

  static const String apiBase = 'https://g.api.mega.co.nz';
  static const String cs = '/cs';
}

class OneDriveEndpoints {
  OneDriveEndpoints._();

  static const String baseUrl = 'https://graph.microsoft.com/v1.0';
  static const String driveRoot = '/me/drive/root/children';
  static const String driveItems = '/me/drive/items';
  static const String driveInfo = '/me/drive';
  static const String userInfo = '/me';

  // Fields to fetch (metadata only — no file content).
  // 'file' object includes 'hashes' sub-object with md5Hash/sha1Hash/sha256Hash/quickXorHash.
  static const String itemFields =
      'id,name,size,file,folder,lastModifiedDateTime,parentReference,fileSystemInfo,deleted';
}
