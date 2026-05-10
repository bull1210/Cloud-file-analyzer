import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/accounts_table.dart';

part 'account_dao.g.dart';

@DriftAccessor(tables: [AccountsTable])
class AccountDao extends DatabaseAccessor<AppDatabase> with _$AccountDaoMixin {
  AccountDao(super.db);

  Future<List<AccountsTableData>> getAllAccounts() =>
      select(accountsTable).get();

  Stream<List<AccountsTableData>> watchAllAccounts() =>
      select(accountsTable).watch();

  Future<AccountsTableData?> getAccount(String id) =>
      (select(accountsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertAccount(AccountsTableCompanion account) =>
      into(accountsTable).insertOnConflictUpdate(account);

  Future<void> updateAccount(AccountsTableCompanion account) =>
      (update(accountsTable)..where((t) => t.id.equals(account.id.value)))
          .write(account);

  Future<void> deleteAccount(String id) =>
      (delete(accountsTable)..where((t) => t.id.equals(id))).go();

  Future<void> updateScanStats({
    required String accountId,
    required int totalFiles,
    required int totalFolders,
    required int totalBytes,
    required DateTime lastScanAt,
  }) =>
      (update(accountsTable)..where((t) => t.id.equals(accountId))).write(
        AccountsTableCompanion(
          totalFiles: Value(totalFiles),
          totalFolders: Value(totalFolders),
          totalBytes: Value(totalBytes),
          lastScanAt: Value(lastScanAt.millisecondsSinceEpoch),
        ),
      );
}
