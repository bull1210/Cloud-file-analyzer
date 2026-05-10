import '../../../domain/models/cloud_account.dart';
import '../../../domain/models/scan_session.dart';
import '../../../services/scan_orchestrator.dart';

class StartScanUseCase {
  const StartScanUseCase(this._orchestrator);

  final ScanOrchestrator _orchestrator;

  Stream<ScanProgress> execute(CloudAccount account) =>
      _orchestrator.startScan(account);
}
