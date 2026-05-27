import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/models/cloud_account.dart';
import '../local/database/app_database.dart';
import '../local/secure_storage/token_storage_service.dart';
import '../remote/dropbox/dropbox_api.dart';
import '../remote/dropbox/dropbox_auth_service.dart';
import '../remote/google/google_auth_service.dart';
import '../remote/google/google_drive_api.dart';
import '../remote/apple/apple_auth_service.dart';
import '../remote/apple/icloud_api.dart';
import '../remote/mega/mega_auth_service.dart';
import '../remote/microsoft/microsoft_auth_service.dart';
import '../remote/microsoft/onedrive_api.dart';
import '../remote/terabox/terabox_api.dart';
import '../remote/terabox/terabox_auth_service.dart';
import 'auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.db,
    required this.tokenStorage,
    required this.googleAuthService,
    required this.googleDriveApi,
    required this.microsoftAuthService,
    required this.oneDriveApi,
    required this.dropboxAuthService,
    required this.dropboxApi,
    required this.teraboxAuthService,
    required this.teraboxApi,
    required this.megaAuthService,
    required this.appleAuthService,
    required this.iCloudApi,
  });

  final AppDatabase db;
  final TokenStorageService tokenStorage;
  final GoogleAuthService googleAuthService;
  final GoogleDriveApi googleDriveApi;
  final MicrosoftAuthService microsoftAuthService;
  final OneDriveApi oneDriveApi;
  final DropboxAuthService dropboxAuthService;
  final DropboxApi dropboxApi;
  final TeraboxAuthService teraboxAuthService;
  final TeraboxApi teraboxApi;
  final MegaAuthService megaAuthService;
  final AppleAuthService appleAuthService;
  final ICloudApi iCloudApi;

  final _uuid = const Uuid();

  @override
  Future<CloudAccount> loginGoogle() async {
    final authResult = await googleAuthService.authorize();
    final accountId = _uuid.v4();

    await tokenStorage.saveTokens(
      accountId: accountId,
      accessToken: authResult.accessToken,
      refreshToken: authResult.refreshToken,
      expiry: authResult.accessTokenExpirationDateTime,
      idToken: authResult.idToken,
    );

    DriveAbout? about;
    try {
      about = await googleDriveApi.getAbout(accountId);
    } catch (_) {}

    final email = (about?.email.isNotEmpty == true)
        ? about!.email
        : _jwtClaim(authResult.idToken, 'email') ?? '';
    final displayName = (about?.displayName.isNotEmpty == true)
        ? about!.displayName
        : _jwtClaim(authResult.idToken, 'name') ?? email;
    final photoUrl = about?.photoUrl ?? _jwtClaim(authResult.idToken, 'picture');

    final companion = AccountsTableCompanion.insert(
      id: accountId,
      provider: CloudProvider.google.dbValue,
      email: email,
      displayName: displayName,
      label: 'Google – $email',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      photoUrl: Value(photoUrl),
    );
    await db.accountDao.insertAccount(companion);

    return CloudAccount(
      id: accountId,
      provider: CloudProvider.google,
      email: email,
      displayName: displayName,
      label: 'Google – $email',
      createdAt: DateTime.now(),
      photoUrl: photoUrl,
    );
  }

  @override
  Future<CloudAccount> loginMicrosoft() async {
    const tag = 'AuthRepo/Microsoft';
    logger.log(tag, '─── loginMicrosoft() START ───');

    logger.log(tag, 'Step 1: calling microsoftAuthService.authorize()');
    final authResult = await microsoftAuthService.authorize();
    logger.log(tag, 'Step 1 done — authorize() returned');

    final accountId = _uuid.v4();
    logger.log(tag, 'Step 2: generated accountId=${accountId.substring(0, 8)}…');

    logger.log(tag, 'Step 3: saving tokens to secure storage');
    try {
      await tokenStorage.saveTokens(
        accountId: accountId,
        accessToken: authResult.accessToken,
        refreshToken: authResult.refreshToken,
        expiry: authResult.accessTokenExpirationDateTime,
        idToken: authResult.idToken,
      );
      logger.log(tag, 'Step 3 done — tokens saved  refreshToken=${authResult.refreshToken != null}  idToken=${authResult.idToken != null}  expiry=${authResult.accessTokenExpirationDateTime}');
    } catch (e) {
      logger.error(tag, 'Step 3 FAILED — saveTokens threw: $e', e);
      rethrow;
    }

    logger.log(tag, 'Step 4: fetching user info from Graph API (timeout=10s)');
    OneDriveUserInfo? userInfo;
    try {
      userInfo = await oneDriveApi.getUserInfo(accountId)
          .timeout(const Duration(seconds: 10));
      logger.log(tag, 'Step 4 done — email=${userInfo.email}  displayName=${userInfo.displayName}');
    } catch (e) {
      logger.error(tag, 'Step 4 FAILED — getUserInfo threw (account still saved): $e', e);
    }

    final email = (userInfo?.email.isNotEmpty == true)
        ? userInfo!.email
        : _jwtClaim(authResult.idToken, 'preferred_username') ??
          _jwtClaim(authResult.idToken, 'email') ?? '';
    final displayName = (userInfo?.displayName.isNotEmpty == true)
        ? userInfo!.displayName
        : _jwtClaim(authResult.idToken, 'name') ?? email;
    logger.log(tag, 'Step 4 resolved — email=$email  displayName=$displayName  source=${userInfo != null ? 'API' : 'JWT/fallback'}');

    logger.log(tag, 'Step 5: inserting account row in DB');
    final companion = AccountsTableCompanion.insert(
      id: accountId,
      provider: CloudProvider.microsoft.dbValue,
      email: email,
      displayName: displayName,
      label: 'OneDrive – $email',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    try {
      await db.accountDao.insertAccount(companion);
      logger.log(tag, 'Step 5 done — DB row inserted');
    } catch (e) {
      logger.error(tag, 'Step 5 FAILED — DB insert threw: $e', e);
      rethrow;
    }

    logger.log(tag, '─── loginMicrosoft() END — success ───');
    return CloudAccount(
      id: accountId,
      provider: CloudProvider.microsoft,
      email: email,
      displayName: displayName,
      label: 'OneDrive – $email',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<CloudAccount> loginDropbox() async {
    final authResult = await dropboxAuthService.authorize();
    final accountId = _uuid.v4();

    await tokenStorage.saveTokens(
      accountId: accountId,
      accessToken: authResult.accessToken,
      refreshToken: authResult.refreshToken,
      expiry: authResult.accessTokenExpirationDateTime,
    );

    DropboxUserInfo? userInfo;
    try {
      userInfo = await dropboxApi.getCurrentAccount(accountId);
    } catch (e) {
      logger.error('AuthRepo', 'Dropbox getUserInfo failed', e);
    }

    final email = userInfo?.email ?? '';
    final displayName = userInfo?.displayName ?? email;

    final companion = AccountsTableCompanion.insert(
      id: accountId,
      provider: CloudProvider.dropbox.dbValue,
      email: email,
      displayName: displayName,
      label: 'Dropbox – $email',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await db.accountDao.insertAccount(companion);

    return CloudAccount(
      id: accountId,
      provider: CloudProvider.dropbox,
      email: email,
      displayName: displayName,
      label: 'Dropbox – $email',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<CloudAccount> loginTerabox() async {
    final authResult = await teraboxAuthService.authorize();
    final accountId = _uuid.v4();

    await tokenStorage.saveTokens(
      accountId: accountId,
      accessToken: authResult.accessToken,
      refreshToken: authResult.refreshToken,
      expiry: authResult.accessTokenExpirationDateTime,
    );

    TeraboxUserInfo? userInfo;
    try {
      userInfo = await teraboxApi.getUserInfo(accountId);
    } catch (e) {
      logger.error('AuthRepo', 'TeraBox getUserInfo failed', e);
    }

    final email = userInfo?.email ?? '';
    final displayName = userInfo?.displayName ?? email;

    final companion = AccountsTableCompanion.insert(
      id: accountId,
      provider: CloudProvider.terabox.dbValue,
      email: email,
      displayName: displayName,
      label: 'TeraBox – $email',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await db.accountDao.insertAccount(companion);

    return CloudAccount(
      id: accountId,
      provider: CloudProvider.terabox,
      email: email,
      displayName: displayName,
      label: 'TeraBox – $email',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<CloudAccount> loginMega({
    required String email,
    required String password,
  }) async {
    final authResult = await megaAuthService.authorizeWithCredentials(
      email: email,
      password: password,
    );
    final accountId = _uuid.v4();

    await tokenStorage.saveTokens(
      accountId: accountId,
      accessToken: authResult.accessToken,
      refreshToken: authResult.refreshToken,
      expiry: authResult.accessTokenExpirationDateTime,
    );

    final companion = AccountsTableCompanion.insert(
      id: accountId,
      provider: CloudProvider.mega.dbValue,
      email: email.trim().toLowerCase(),
      displayName: email.trim().toLowerCase(),
      label: 'MEGA – $email',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await db.accountDao.insertAccount(companion);

    return CloudAccount(
      id: accountId,
      provider: CloudProvider.mega,
      email: email.trim().toLowerCase(),
      displayName: email.trim().toLowerCase(),
      label: 'MEGA – $email',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<CloudAccount> loginApple() async {
    final authResult = await appleAuthService.authorize();
    final accountId = _uuid.v4();

    await tokenStorage.saveTokens(
      accountId: accountId,
      accessToken: authResult.accessToken,
      refreshToken: authResult.refreshToken,
      expiry: authResult.accessTokenExpirationDateTime,
      idToken: authResult.idToken,
    );

    // Apple only sends name/email on the very first authorisation for a given
    // app install. Parse whatever the identity token contains; the caller must
    // persist and reuse these values for subsequent sign-ins.
    final userInfo = iCloudApi.getUserInfoFromIdToken(authResult.idToken);
    final email = userInfo.email.isNotEmpty
        ? userInfo.email
        : _jwtClaim(authResult.idToken, 'sub') ?? '';
    final displayName = email.isNotEmpty ? email : 'Apple User';

    final companion = AccountsTableCompanion.insert(
      id: accountId,
      provider: CloudProvider.apple.dbValue,
      email: email,
      displayName: displayName,
      label: 'iCloud – $email',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await db.accountDao.insertAccount(companion);

    return CloudAccount(
      id: accountId,
      provider: CloudProvider.apple,
      email: email,
      displayName: displayName,
      label: 'iCloud – $email',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> logout(String accountId) async {
    final account = await db.accountDao.getAccount(accountId);
    if (account == null) return;

    final provider = CloudProviderExtension.fromDb(account.provider);
    switch (provider) {
      case CloudProvider.google:
        await googleAuthService.revokeTokens(accountId);
      case CloudProvider.microsoft:
        await microsoftAuthService.revokeTokens(accountId);
      case CloudProvider.dropbox:
        await dropboxAuthService.revokeTokens(accountId);
      case CloudProvider.terabox:
        await teraboxAuthService.revokeTokens(accountId);
      case CloudProvider.mega:
        await megaAuthService.revokeTokens(accountId);
      case CloudProvider.apple:
        await appleAuthService.revokeTokens(accountId);
    }

    await db.fileRecordDao.deleteAllForAccount(accountId);
    await db.accountDao.deleteAccount(accountId);
  }

  @override
  Future<void> refreshToken(String accountId) async {
    final account = await db.accountDao.getAccount(accountId);
    if (account == null) return;

    final provider = CloudProviderExtension.fromDb(account.provider);

    Future<void> save(dynamic result) async {
      if (result == null) return;
      await tokenStorage.saveTokens(
        accountId: accountId,
        accessToken: result.accessToken as String,
        refreshToken: result.refreshToken as String?,
        expiry: result.accessTokenExpirationDateTime as DateTime?,
      );
    }

    switch (provider) {
      case CloudProvider.google:
        await save(await googleAuthService.refreshAccessToken(accountId));
      case CloudProvider.microsoft:
        await save(await microsoftAuthService.refreshAccessToken(accountId));
      case CloudProvider.dropbox:
        await save(await dropboxAuthService.refreshAccessToken(accountId));
      case CloudProvider.terabox:
        await save(await teraboxAuthService.refreshAccessToken(accountId));
      case CloudProvider.mega:
        await save(await megaAuthService.refreshAccessToken(accountId));
      case CloudProvider.apple:
        // Apple identity tokens cannot be refreshed programmatically.
        // A new Sign in with Apple prompt is required when the token expires.
        break;
    }
  }

  @override
  Future<List<CloudAccount>> getStoredAccounts() async {
    final rows = await db.accountDao.getAllAccounts();
    return rows.map(_mapAccount).toList();
  }

  @override
  Future<CloudAccount?> getAccount(String accountId) async {
    final row = await db.accountDao.getAccount(accountId);
    return row != null ? _mapAccount(row) : null;
  }

  @override
  Future<void> renameAccount(String accountId, String newLabel) async {
    await db.accountDao.updateAccount(
      AccountsTableCompanion(
        id: Value(accountId),
        label: Value(newLabel),
      ),
    );
  }

  @override
  Future<void> deleteAccount(String accountId) => logout(accountId);

  @override
  Future<void> reauthAccount(String accountId) async {
    final row = await db.accountDao.getAccount(accountId);
    if (row == null) return;

    final provider = CloudProviderExtension.fromDb(row.provider);
    switch (provider) {
      case CloudProvider.google:
        final authResult = await googleAuthService.authorize();
        await tokenStorage.saveTokens(
          accountId: accountId,
          accessToken: authResult.accessToken,
          refreshToken: authResult.refreshToken,
          expiry: authResult.accessTokenExpirationDateTime,
          idToken: authResult.idToken,
        );
        DriveAbout? about;
        try {
          about = await googleDriveApi.getAbout(accountId);
        } catch (_) {}
        final email = (about?.email.isNotEmpty == true)
            ? about!.email
            : _jwtClaim(authResult.idToken, 'email') ?? row.email;
        final displayName = (about?.displayName.isNotEmpty == true)
            ? about!.displayName
            : _jwtClaim(authResult.idToken, 'name') ?? row.displayName;
        await db.accountDao.updateAccount(AccountsTableCompanion(
          id: Value(accountId),
          email: Value(email),
          displayName: Value(displayName),
          label: Value('Google – $email'),
          photoUrl: Value(about?.photoUrl ?? _jwtClaim(authResult.idToken, 'picture')),
        ));

      case CloudProvider.microsoft:
        const tag = 'AuthRepo/MS-Reauth';
        logger.log(tag, 'reauthAccount() Microsoft — accountId=${accountId.substring(0, 8)}…');
        final authResult = await microsoftAuthService.authorize();
        logger.log(tag, 'authorize() returned — saving tokens');
        await tokenStorage.saveTokens(
          accountId: accountId,
          accessToken: authResult.accessToken,
          refreshToken: authResult.refreshToken,
          expiry: authResult.accessTokenExpirationDateTime,
          idToken: authResult.idToken,
        );
        logger.log(tag, 'tokens saved — refreshToken=${authResult.refreshToken != null}');
        logger.log(tag, 'fetching user info…');
        OneDriveUserInfo? userInfo;
        try {
          userInfo = await oneDriveApi.getUserInfo(accountId)
              .timeout(const Duration(seconds: 10));
          logger.log(tag, 'getUserInfo() success — email=${userInfo.email}');
        } catch (e) {
          logger.error(tag, 'getUserInfo() failed: $e', e);
        }
        final msEmail = (userInfo?.email.isNotEmpty == true)
            ? userInfo!.email
            : _jwtClaim(authResult.idToken, 'preferred_username') ??
                _jwtClaim(authResult.idToken, 'email') ?? row.email;
        final msName = (userInfo?.displayName.isNotEmpty == true)
            ? userInfo!.displayName
            : _jwtClaim(authResult.idToken, 'name') ?? row.displayName;
        logger.log(tag, 'updating DB row — email=$msEmail  name=$msName');
        await db.accountDao.updateAccount(AccountsTableCompanion(
          id: Value(accountId),
          email: Value(msEmail),
          displayName: Value(msName),
          label: Value('OneDrive – $msEmail'),
        ));
        logger.log(tag, 'reauthAccount() Microsoft done');

      case CloudProvider.dropbox:
        final authResult = await dropboxAuthService.authorize();
        await tokenStorage.saveTokens(
          accountId: accountId,
          accessToken: authResult.accessToken,
          refreshToken: authResult.refreshToken,
          expiry: authResult.accessTokenExpirationDateTime,
        );
        DropboxUserInfo? userInfo;
        try {
          userInfo = await dropboxApi.getCurrentAccount(accountId);
        } catch (_) {}
        final dbEmail = userInfo?.email ?? row.email;
        final dbName = userInfo?.displayName ?? row.displayName;
        await db.accountDao.updateAccount(AccountsTableCompanion(
          id: Value(accountId),
          email: Value(dbEmail),
          displayName: Value(dbName),
          label: Value('Dropbox – $dbEmail'),
        ));

      case CloudProvider.terabox:
        final authResult = await teraboxAuthService.authorize();
        await tokenStorage.saveTokens(
          accountId: accountId,
          accessToken: authResult.accessToken,
          refreshToken: authResult.refreshToken,
          expiry: authResult.accessTokenExpirationDateTime,
        );

      case CloudProvider.mega:
        // Re-auth for MEGA re-uses stored credentials; show dialog from UI layer.
        break;

      case CloudProvider.apple:
        final authResult = await appleAuthService.authorize();
        await tokenStorage.saveTokens(
          accountId: accountId,
          accessToken: authResult.accessToken,
          refreshToken: authResult.refreshToken,
          expiry: authResult.accessTokenExpirationDateTime,
          idToken: authResult.idToken,
        );
        // Re-use stored email/name — Apple omits them after first sign-in.
        final userInfo = iCloudApi.getUserInfoFromIdToken(authResult.idToken);
        if (userInfo.email.isNotEmpty) {
          await db.accountDao.updateAccount(AccountsTableCompanion(
            id: Value(accountId),
            email: Value(userInfo.email),
            displayName: Value(userInfo.email),
            label: Value('iCloud – ${userInfo.email}'),
          ));
        }
    }
  }

  @override
  Stream<List<CloudAccount>> watchAccounts() {
    return db.accountDao
        .watchAllAccounts()
        .map((rows) => rows.map(_mapAccount).toList());
  }

  String? _jwtClaim(String? token, String claim) {
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      final padded = base64Url.normalize(parts[1]);
      final payload =
          jsonDecode(utf8.decode(base64Url.decode(padded))) as Map<String, dynamic>;
      return payload[claim] as String?;
    } catch (_) {
      return null;
    }
  }

  CloudAccount _mapAccount(AccountsTableData row) {
    return CloudAccount(
      id: row.id,
      provider: CloudProviderExtension.fromDb(row.provider),
      email: row.email,
      displayName: row.displayName,
      label: row.label,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
      lastScanAt: row.lastScanAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastScanAt!)
          : null,
      totalFiles: row.totalFiles,
      totalFolders: row.totalFolders,
      totalBytes: row.totalBytes,
      photoUrl: row.photoUrl,
    );
  }
}
