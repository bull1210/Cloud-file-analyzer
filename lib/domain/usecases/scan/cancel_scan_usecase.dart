import '../../../services/scan_orchestrator.dart';

class CancelScanUseCase {
  const CancelScanUseCase(this._orchestrator);

  final ScanOrchestrator _orchestrator;

  void execute() => _orchestrator.cancelScan();
}
