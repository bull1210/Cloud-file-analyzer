import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database/app_database.dart';
import '../../data/local/secure_storage/token_storage_service.dart';
import '../../data/remote/apple/apple_auth_service.dart';
import '../../data/remote/apple/icloud_api.dart';
import '../../data/remote/dropbox/dropbox_api.dart';
import '../../data/remote/dropbox/dropbox_auth_service.dart';
import '../../data/remote/dropbox/dropbox_client.dart';
import '../../data/remote/google/google_auth_service.dart';
import '../../data/remote/google/google_drive_api.dart';
import '../../data/remote/google/google_drive_client.dart';
import '../../data/remote/mega/mega_api.dart';
import '../../data/remote/mega/mega_auth_service.dart';
import '../../data/remote/mega/mega_client.dart';
import '../../data/remote/microsoft/microsoft_auth_service.dart';
import '../../data/remote/microsoft/onedrive_api.dart';
import '../../data/remote/microsoft/onedrive_client.dart';
import '../../data/remote/terabox/terabox_api.dart';
import '../../data/remote/terabox/terabox_auth_service.dart';
import '../../data/remote/terabox/terabox_client.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/file_repository.dart';
import '../../data/repositories/file_repository_impl.dart';
import '../../domain/usecases/analytics/get_access_time_stats_usecase.dart';
import '../../domain/usecases/analytics/get_file_type_breakdown_usecase.dart';
import '../../domain/usecases/analytics/get_folder_rankings_usecase.dart';
import '../../domain/usecases/analytics/get_largest_files_usecase.dart';
import '../../domain/usecases/analytics/get_storage_summary_usecase.dart';
import '../../domain/usecases/auth/login_apple_usecase.dart';
import '../../domain/usecases/auth/login_dropbox_usecase.dart';
import '../../domain/usecases/auth/login_google_usecase.dart';
import '../../domain/usecases/auth/login_mega_usecase.dart';
import '../../domain/usecases/auth/login_microsoft_usecase.dart';
import '../../domain/usecases/auth/login_terabox_usecase.dart';
import '../../domain/usecases/auth/logout_account_usecase.dart';
import '../../domain/usecases/duplicates/find_duplicates_usecase.dart';
import '../../domain/usecases/files/get_files_usecase.dart';
import '../../domain/usecases/scan/cancel_scan_usecase.dart';
import '../../domain/usecases/scan/start_scan_usecase.dart';
import '../../services/cloud_delete_service.dart';
import '../../services/export_service.dart';
import '../../services/scan_orchestrator.dart';

// ── Infrastructure ───────────────────────────────────────────────────────────

final dbProvider = Provider<AppDatabase>((_) => AppDatabase());

final tokenStorageProvider =
    Provider<TokenStorageService>((_) => TokenStorageService());

final googleAuthServiceProvider = Provider<GoogleAuthService>((ref) =>
    GoogleAuthService(tokenStorage: ref.read(tokenStorageProvider)));

final googleDriveClientProvider = Provider<GoogleDriveClient>((ref) =>
    GoogleDriveClient(
      tokenStorage: ref.read(tokenStorageProvider),
      authService: ref.read(googleAuthServiceProvider),
    ));

final googleDriveApiProvider = Provider<GoogleDriveApi>(
    (ref) => GoogleDriveApi(client: ref.read(googleDriveClientProvider)));

final microsoftAuthServiceProvider = Provider<MicrosoftAuthService>((ref) =>
    MicrosoftAuthService(tokenStorage: ref.read(tokenStorageProvider)));

final oneDriveClientProvider = Provider<OneDriveClient>((ref) =>
    OneDriveClient(
      tokenStorage: ref.read(tokenStorageProvider),
      authService: ref.read(microsoftAuthServiceProvider),
    ));

final oneDriveApiProvider = Provider<OneDriveApi>(
    (ref) => OneDriveApi(client: ref.read(oneDriveClientProvider)));

final dropboxAuthServiceProvider = Provider<DropboxAuthService>((ref) =>
    DropboxAuthService(tokenStorage: ref.read(tokenStorageProvider)));

final dropboxClientProvider = Provider<DropboxClient>((ref) =>
    DropboxClient(
      tokenStorage: ref.read(tokenStorageProvider),
      authService: ref.read(dropboxAuthServiceProvider),
    ));

final dropboxApiProvider = Provider<DropboxApi>(
    (ref) => DropboxApi(client: ref.read(dropboxClientProvider)));

final teraboxAuthServiceProvider = Provider<TeraboxAuthService>((ref) =>
    TeraboxAuthService(tokenStorage: ref.read(tokenStorageProvider)));

final teraboxClientProvider = Provider<TeraboxClient>((ref) =>
    TeraboxClient(
      tokenStorage: ref.read(tokenStorageProvider),
      authService: ref.read(teraboxAuthServiceProvider),
    ));

final teraboxApiProvider = Provider<TeraboxApi>(
    (ref) => TeraboxApi(client: ref.read(teraboxClientProvider)));

final megaAuthServiceProvider = Provider<MegaAuthService>((ref) =>
    MegaAuthService(tokenStorage: ref.read(tokenStorageProvider)));

final megaClientProvider = Provider<MegaClient>((ref) =>
    MegaClient(
      tokenStorage: ref.read(tokenStorageProvider),
      authService: ref.read(megaAuthServiceProvider),
    ));

final megaApiProvider = Provider<MegaApi>(
    (ref) => MegaApi(client: ref.read(megaClientProvider)));

final appleAuthServiceProvider = Provider<AppleAuthService>((ref) =>
    AppleAuthService(tokenStorage: ref.read(tokenStorageProvider)));

final iCloudApiProvider = Provider<ICloudApi>((_) => ICloudApi());

// ── Repositories ─────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) =>
    AuthRepositoryImpl(
      db: ref.read(dbProvider),
      tokenStorage: ref.read(tokenStorageProvider),
      googleAuthService: ref.read(googleAuthServiceProvider),
      googleDriveApi: ref.read(googleDriveApiProvider),
      microsoftAuthService: ref.read(microsoftAuthServiceProvider),
      oneDriveApi: ref.read(oneDriveApiProvider),
      dropboxAuthService: ref.read(dropboxAuthServiceProvider),
      dropboxApi: ref.read(dropboxApiProvider),
      teraboxAuthService: ref.read(teraboxAuthServiceProvider),
      teraboxApi: ref.read(teraboxApiProvider),
      megaAuthService: ref.read(megaAuthServiceProvider),
      appleAuthService: ref.read(appleAuthServiceProvider),
      iCloudApi: ref.read(iCloudApiProvider),
    ));

final fileRepositoryProvider = Provider<FileRepository>(
    (ref) => FileRepositoryImpl(db: ref.read(dbProvider)));

// ── Services ─────────────────────────────────────────────────────────────────

final scanOrchestratorProvider = Provider<ScanOrchestrator>((ref) =>
    ScanOrchestrator(
      db: ref.read(dbProvider),
      tokenStorage: ref.read(tokenStorageProvider),
      googleDriveApi: ref.read(googleDriveApiProvider),
      oneDriveApi: ref.read(oneDriveApiProvider),
      dropboxApi: ref.read(dropboxApiProvider),
      teraboxApi: ref.read(teraboxApiProvider),
      megaApi: ref.read(megaApiProvider),
    ));

final exportServiceProvider = Provider<ExportService>((_) => ExportService());

final cloudDeleteServiceProvider = Provider<CloudDeleteService>((ref) =>
    CloudDeleteService(
      googleDriveApi: ref.read(googleDriveApiProvider),
      oneDriveApi: ref.read(oneDriveApiProvider),
      db: ref.read(dbProvider),
    ));

// ── Use Cases ─────────────────────────────────────────────────────────────────

final loginAppleUseCaseProvider = Provider<LoginAppleUseCase>(
    (ref) => LoginAppleUseCase(ref.read(authRepositoryProvider)));

final loginGoogleUseCaseProvider = Provider<LoginGoogleUseCase>(
    (ref) => LoginGoogleUseCase(ref.read(authRepositoryProvider)));

final loginMicrosoftUseCaseProvider = Provider<LoginMicrosoftUseCase>(
    (ref) => LoginMicrosoftUseCase(ref.read(authRepositoryProvider)));

final loginDropboxUseCaseProvider = Provider<LoginDropboxUseCase>(
    (ref) => LoginDropboxUseCase(ref.read(authRepositoryProvider)));

final loginTeraboxUseCaseProvider = Provider<LoginTeraboxUseCase>(
    (ref) => LoginTeraboxUseCase(ref.read(authRepositoryProvider)));

final loginMegaUseCaseProvider = Provider<LoginMegaUseCase>(
    (ref) => LoginMegaUseCase(ref.read(authRepositoryProvider)));

final logoutAccountUseCaseProvider = Provider<LogoutAccountUseCase>(
    (ref) => LogoutAccountUseCase(ref.read(authRepositoryProvider)));

final startScanUseCaseProvider = Provider<StartScanUseCase>(
    (ref) => StartScanUseCase(ref.read(scanOrchestratorProvider)));

final cancelScanUseCaseProvider = Provider<CancelScanUseCase>(
    (ref) => CancelScanUseCase(ref.read(scanOrchestratorProvider)));

final getFilesUseCaseProvider = Provider<GetFilesUseCase>(
    (ref) => GetFilesUseCase(ref.read(fileRepositoryProvider)));

final findDuplicatesUseCaseProvider = Provider<FindDuplicatesUseCase>(
    (ref) => FindDuplicatesUseCase(ref.read(fileRepositoryProvider)));

final getStorageSummaryUseCaseProvider = Provider<GetStorageSummaryUseCase>(
    (ref) => GetStorageSummaryUseCase(ref.read(fileRepositoryProvider)));

final getLargestFilesUseCaseProvider = Provider<GetLargestFilesUseCase>(
    (ref) => GetLargestFilesUseCase(ref.read(fileRepositoryProvider)));

final getFileTypeBreakdownUseCaseProvider =
    Provider<GetFileTypeBreakdownUseCase>(
        (ref) => GetFileTypeBreakdownUseCase(ref.read(fileRepositoryProvider)));

final getFolderRankingsUseCaseProvider = Provider<GetFolderRankingsUseCase>(
    (ref) => GetFolderRankingsUseCase(ref.read(fileRepositoryProvider)));

final getAccessTimeStatsUseCaseProvider = Provider<GetAccessTimeStatsUseCase>(
    (ref) => GetAccessTimeStatsUseCase(ref.read(fileRepositoryProvider)));
