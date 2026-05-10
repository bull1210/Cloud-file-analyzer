// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTableTable extends AccountsTable
    with TableInfo<$AccountsTableTable, AccountsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastScanAtMeta =
      const VerificationMeta('lastScanAt');
  @override
  late final GeneratedColumn<int> lastScanAt = GeneratedColumn<int>(
      'last_scan_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalFilesMeta =
      const VerificationMeta('totalFiles');
  @override
  late final GeneratedColumn<int> totalFiles = GeneratedColumn<int>(
      'total_files', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalFoldersMeta =
      const VerificationMeta('totalFolders');
  @override
  late final GeneratedColumn<int> totalFolders = GeneratedColumn<int>(
      'total_folders', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalBytesMeta =
      const VerificationMeta('totalBytes');
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
      'total_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _photoUrlMeta =
      const VerificationMeta('photoUrl');
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
      'photo_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        provider,
        email,
        displayName,
        label,
        createdAt,
        lastScanAt,
        totalFiles,
        totalFolders,
        totalBytes,
        photoUrl
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<AccountsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_scan_at')) {
      context.handle(
          _lastScanAtMeta,
          lastScanAt.isAcceptableOrUnknown(
              data['last_scan_at']!, _lastScanAtMeta));
    }
    if (data.containsKey('total_files')) {
      context.handle(
          _totalFilesMeta,
          totalFiles.isAcceptableOrUnknown(
              data['total_files']!, _totalFilesMeta));
    }
    if (data.containsKey('total_folders')) {
      context.handle(
          _totalFoldersMeta,
          totalFolders.isAcceptableOrUnknown(
              data['total_folders']!, _totalFoldersMeta));
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
          _totalBytesMeta,
          totalBytes.isAcceptableOrUnknown(
              data['total_bytes']!, _totalBytesMeta));
    }
    if (data.containsKey('photo_url')) {
      context.handle(_photoUrlMeta,
          photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      lastScanAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_scan_at']),
      totalFiles: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_files'])!,
      totalFolders: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_folders'])!,
      totalBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_bytes'])!,
      photoUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_url']),
    );
  }

  @override
  $AccountsTableTable createAlias(String alias) {
    return $AccountsTableTable(attachedDatabase, alias);
  }
}

class AccountsTableData extends DataClass
    implements Insertable<AccountsTableData> {
  final String id;
  final String provider;
  final String email;
  final String displayName;
  final String label;
  final int createdAt;
  final int? lastScanAt;
  final int totalFiles;
  final int totalFolders;
  final int totalBytes;
  final String? photoUrl;
  const AccountsTableData(
      {required this.id,
      required this.provider,
      required this.email,
      required this.displayName,
      required this.label,
      required this.createdAt,
      this.lastScanAt,
      required this.totalFiles,
      required this.totalFolders,
      required this.totalBytes,
      this.photoUrl});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider'] = Variable<String>(provider);
    map['email'] = Variable<String>(email);
    map['display_name'] = Variable<String>(displayName);
    map['label'] = Variable<String>(label);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastScanAt != null) {
      map['last_scan_at'] = Variable<int>(lastScanAt);
    }
    map['total_files'] = Variable<int>(totalFiles);
    map['total_folders'] = Variable<int>(totalFolders);
    map['total_bytes'] = Variable<int>(totalBytes);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    return map;
  }

  AccountsTableCompanion toCompanion(bool nullToAbsent) {
    return AccountsTableCompanion(
      id: Value(id),
      provider: Value(provider),
      email: Value(email),
      displayName: Value(displayName),
      label: Value(label),
      createdAt: Value(createdAt),
      lastScanAt: lastScanAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastScanAt),
      totalFiles: Value(totalFiles),
      totalFolders: Value(totalFolders),
      totalBytes: Value(totalBytes),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
    );
  }

  factory AccountsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountsTableData(
      id: serializer.fromJson<String>(json['id']),
      provider: serializer.fromJson<String>(json['provider']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String>(json['displayName']),
      label: serializer.fromJson<String>(json['label']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastScanAt: serializer.fromJson<int?>(json['lastScanAt']),
      totalFiles: serializer.fromJson<int>(json['totalFiles']),
      totalFolders: serializer.fromJson<int>(json['totalFolders']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'provider': serializer.toJson<String>(provider),
      'email': serializer.toJson<String>(email),
      'displayName': serializer.toJson<String>(displayName),
      'label': serializer.toJson<String>(label),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastScanAt': serializer.toJson<int?>(lastScanAt),
      'totalFiles': serializer.toJson<int>(totalFiles),
      'totalFolders': serializer.toJson<int>(totalFolders),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'photoUrl': serializer.toJson<String?>(photoUrl),
    };
  }

  AccountsTableData copyWith(
          {String? id,
          String? provider,
          String? email,
          String? displayName,
          String? label,
          int? createdAt,
          Value<int?> lastScanAt = const Value.absent(),
          int? totalFiles,
          int? totalFolders,
          int? totalBytes,
          Value<String?> photoUrl = const Value.absent()}) =>
      AccountsTableData(
        id: id ?? this.id,
        provider: provider ?? this.provider,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        label: label ?? this.label,
        createdAt: createdAt ?? this.createdAt,
        lastScanAt: lastScanAt.present ? lastScanAt.value : this.lastScanAt,
        totalFiles: totalFiles ?? this.totalFiles,
        totalFolders: totalFolders ?? this.totalFolders,
        totalBytes: totalBytes ?? this.totalBytes,
        photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
      );
  AccountsTableData copyWithCompanion(AccountsTableCompanion data) {
    return AccountsTableData(
      id: data.id.present ? data.id.value : this.id,
      provider: data.provider.present ? data.provider.value : this.provider,
      email: data.email.present ? data.email.value : this.email,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      label: data.label.present ? data.label.value : this.label,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastScanAt:
          data.lastScanAt.present ? data.lastScanAt.value : this.lastScanAt,
      totalFiles:
          data.totalFiles.present ? data.totalFiles.value : this.totalFiles,
      totalFolders: data.totalFolders.present
          ? data.totalFolders.value
          : this.totalFolders,
      totalBytes:
          data.totalBytes.present ? data.totalBytes.value : this.totalBytes,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountsTableData(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastScanAt: $lastScanAt, ')
          ..write('totalFiles: $totalFiles, ')
          ..write('totalFolders: $totalFolders, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('photoUrl: $photoUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, provider, email, displayName, label,
      createdAt, lastScanAt, totalFiles, totalFolders, totalBytes, photoUrl);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountsTableData &&
          other.id == this.id &&
          other.provider == this.provider &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.label == this.label &&
          other.createdAt == this.createdAt &&
          other.lastScanAt == this.lastScanAt &&
          other.totalFiles == this.totalFiles &&
          other.totalFolders == this.totalFolders &&
          other.totalBytes == this.totalBytes &&
          other.photoUrl == this.photoUrl);
}

class AccountsTableCompanion extends UpdateCompanion<AccountsTableData> {
  final Value<String> id;
  final Value<String> provider;
  final Value<String> email;
  final Value<String> displayName;
  final Value<String> label;
  final Value<int> createdAt;
  final Value<int?> lastScanAt;
  final Value<int> totalFiles;
  final Value<int> totalFolders;
  final Value<int> totalBytes;
  final Value<String?> photoUrl;
  final Value<int> rowid;
  const AccountsTableCompanion({
    this.id = const Value.absent(),
    this.provider = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.label = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastScanAt = const Value.absent(),
    this.totalFiles = const Value.absent(),
    this.totalFolders = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsTableCompanion.insert({
    required String id,
    required String provider,
    required String email,
    required String displayName,
    required String label,
    required int createdAt,
    this.lastScanAt = const Value.absent(),
    this.totalFiles = const Value.absent(),
    this.totalFolders = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        provider = Value(provider),
        email = Value(email),
        displayName = Value(displayName),
        label = Value(label),
        createdAt = Value(createdAt);
  static Insertable<AccountsTableData> custom({
    Expression<String>? id,
    Expression<String>? provider,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? label,
    Expression<int>? createdAt,
    Expression<int>? lastScanAt,
    Expression<int>? totalFiles,
    Expression<int>? totalFolders,
    Expression<int>? totalBytes,
    Expression<String>? photoUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (provider != null) 'provider': provider,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (label != null) 'label': label,
      if (createdAt != null) 'created_at': createdAt,
      if (lastScanAt != null) 'last_scan_at': lastScanAt,
      if (totalFiles != null) 'total_files': totalFiles,
      if (totalFolders != null) 'total_folders': totalFolders,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? provider,
      Value<String>? email,
      Value<String>? displayName,
      Value<String>? label,
      Value<int>? createdAt,
      Value<int?>? lastScanAt,
      Value<int>? totalFiles,
      Value<int>? totalFolders,
      Value<int>? totalBytes,
      Value<String?>? photoUrl,
      Value<int>? rowid}) {
    return AccountsTableCompanion(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      lastScanAt: lastScanAt ?? this.lastScanAt,
      totalFiles: totalFiles ?? this.totalFiles,
      totalFolders: totalFolders ?? this.totalFolders,
      totalBytes: totalBytes ?? this.totalBytes,
      photoUrl: photoUrl ?? this.photoUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastScanAt.present) {
      map['last_scan_at'] = Variable<int>(lastScanAt.value);
    }
    if (totalFiles.present) {
      map['total_files'] = Variable<int>(totalFiles.value);
    }
    if (totalFolders.present) {
      map['total_folders'] = Variable<int>(totalFolders.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsTableCompanion(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('label: $label, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastScanAt: $lastScanAt, ')
          ..write('totalFiles: $totalFiles, ')
          ..write('totalFolders: $totalFolders, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FileRecordsTableTable extends FileRecordsTable
    with TableInfo<$FileRecordsTableTable, FileRecordsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileRecordsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerMeta =
      const VerificationMeta('provider');
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
      'provider', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _mimeTypeMeta =
      const VerificationMeta('mimeType');
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
      'mime_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isFolderMeta =
      const VerificationMeta('isFolder');
  @override
  late final GeneratedColumn<bool> isFolder = GeneratedColumn<bool>(
      'is_folder', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_folder" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _modifiedAtMeta =
      const VerificationMeta('modifiedAt');
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
      'modified_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _accessedAtMeta =
      const VerificationMeta('accessedAt');
  @override
  late final GeneratedColumn<int> accessedAt = GeneratedColumn<int>(
      'accessed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _providerFileIdMeta =
      const VerificationMeta('providerFileId');
  @override
  late final GeneratedColumn<String> providerFileId = GeneratedColumn<String>(
      'provider_file_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentHashMeta =
      const VerificationMeta('contentHash');
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
      'content_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        accountId,
        provider,
        name,
        path,
        sizeBytes,
        mimeType,
        category,
        isFolder,
        modifiedAt,
        accessedAt,
        parentId,
        providerFileId,
        contentHash
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_records';
  @override
  VerificationContext validateIntegrity(
      Insertable<FileRecordsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(_providerMeta,
          provider.isAcceptableOrUnknown(data['provider']!, _providerMeta));
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('mime_type')) {
      context.handle(_mimeTypeMeta,
          mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta));
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('is_folder')) {
      context.handle(_isFolderMeta,
          isFolder.isAcceptableOrUnknown(data['is_folder']!, _isFolderMeta));
    }
    if (data.containsKey('modified_at')) {
      context.handle(
          _modifiedAtMeta,
          modifiedAt.isAcceptableOrUnknown(
              data['modified_at']!, _modifiedAtMeta));
    } else if (isInserting) {
      context.missing(_modifiedAtMeta);
    }
    if (data.containsKey('accessed_at')) {
      context.handle(
          _accessedAtMeta,
          accessedAt.isAcceptableOrUnknown(
              data['accessed_at']!, _accessedAtMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('provider_file_id')) {
      context.handle(
          _providerFileIdMeta,
          providerFileId.isAcceptableOrUnknown(
              data['provider_file_id']!, _providerFileIdMeta));
    } else if (isInserting) {
      context.missing(_providerFileIdMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
          _contentHashMeta,
          contentHash.isAcceptableOrUnknown(
              data['content_hash']!, _contentHashMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FileRecordsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileRecordsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      provider: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes']),
      mimeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mime_type'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      isFolder: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_folder'])!,
      modifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}modified_at'])!,
      accessedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}accessed_at']),
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      providerFileId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}provider_file_id'])!,
      contentHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_hash']),
    );
  }

  @override
  $FileRecordsTableTable createAlias(String alias) {
    return $FileRecordsTableTable(attachedDatabase, alias);
  }
}

class FileRecordsTableData extends DataClass
    implements Insertable<FileRecordsTableData> {
  final String id;
  final String accountId;
  final String provider;
  final String name;
  final String path;
  final int? sizeBytes;
  final String mimeType;
  final String category;
  final bool isFolder;
  final int modifiedAt;
  final int? accessedAt;
  final String? parentId;
  final String providerFileId;
  final String? contentHash;
  const FileRecordsTableData(
      {required this.id,
      required this.accountId,
      required this.provider,
      required this.name,
      required this.path,
      this.sizeBytes,
      required this.mimeType,
      required this.category,
      required this.isFolder,
      required this.modifiedAt,
      this.accessedAt,
      this.parentId,
      required this.providerFileId,
      this.contentHash});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['provider'] = Variable<String>(provider);
    map['name'] = Variable<String>(name);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    map['mime_type'] = Variable<String>(mimeType);
    map['category'] = Variable<String>(category);
    map['is_folder'] = Variable<bool>(isFolder);
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || accessedAt != null) {
      map['accessed_at'] = Variable<int>(accessedAt);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['provider_file_id'] = Variable<String>(providerFileId);
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = Variable<String>(contentHash);
    }
    return map;
  }

  FileRecordsTableCompanion toCompanion(bool nullToAbsent) {
    return FileRecordsTableCompanion(
      id: Value(id),
      accountId: Value(accountId),
      provider: Value(provider),
      name: Value(name),
      path: Value(path),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      mimeType: Value(mimeType),
      category: Value(category),
      isFolder: Value(isFolder),
      modifiedAt: Value(modifiedAt),
      accessedAt: accessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(accessedAt),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      providerFileId: Value(providerFileId),
      contentHash: contentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHash),
    );
  }

  factory FileRecordsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileRecordsTableData(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      provider: serializer.fromJson<String>(json['provider']),
      name: serializer.fromJson<String>(json['name']),
      path: serializer.fromJson<String>(json['path']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      category: serializer.fromJson<String>(json['category']),
      isFolder: serializer.fromJson<bool>(json['isFolder']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      accessedAt: serializer.fromJson<int?>(json['accessedAt']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      providerFileId: serializer.fromJson<String>(json['providerFileId']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'provider': serializer.toJson<String>(provider),
      'name': serializer.toJson<String>(name),
      'path': serializer.toJson<String>(path),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'mimeType': serializer.toJson<String>(mimeType),
      'category': serializer.toJson<String>(category),
      'isFolder': serializer.toJson<bool>(isFolder),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'accessedAt': serializer.toJson<int?>(accessedAt),
      'parentId': serializer.toJson<String?>(parentId),
      'providerFileId': serializer.toJson<String>(providerFileId),
      'contentHash': serializer.toJson<String?>(contentHash),
    };
  }

  FileRecordsTableData copyWith(
          {String? id,
          String? accountId,
          String? provider,
          String? name,
          String? path,
          Value<int?> sizeBytes = const Value.absent(),
          String? mimeType,
          String? category,
          bool? isFolder,
          int? modifiedAt,
          Value<int?> accessedAt = const Value.absent(),
          Value<String?> parentId = const Value.absent(),
          String? providerFileId,
          Value<String?> contentHash = const Value.absent()}) =>
      FileRecordsTableData(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        provider: provider ?? this.provider,
        name: name ?? this.name,
        path: path ?? this.path,
        sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
        mimeType: mimeType ?? this.mimeType,
        category: category ?? this.category,
        isFolder: isFolder ?? this.isFolder,
        modifiedAt: modifiedAt ?? this.modifiedAt,
        accessedAt: accessedAt.present ? accessedAt.value : this.accessedAt,
        parentId: parentId.present ? parentId.value : this.parentId,
        providerFileId: providerFileId ?? this.providerFileId,
        contentHash: contentHash.present ? contentHash.value : this.contentHash,
      );
  FileRecordsTableData copyWithCompanion(FileRecordsTableCompanion data) {
    return FileRecordsTableData(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      provider: data.provider.present ? data.provider.value : this.provider,
      name: data.name.present ? data.name.value : this.name,
      path: data.path.present ? data.path.value : this.path,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      category: data.category.present ? data.category.value : this.category,
      isFolder: data.isFolder.present ? data.isFolder.value : this.isFolder,
      modifiedAt:
          data.modifiedAt.present ? data.modifiedAt.value : this.modifiedAt,
      accessedAt:
          data.accessedAt.present ? data.accessedAt.value : this.accessedAt,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      providerFileId: data.providerFileId.present
          ? data.providerFileId.value
          : this.providerFileId,
      contentHash:
          data.contentHash.present ? data.contentHash.value : this.contentHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileRecordsTableData(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('provider: $provider, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('category: $category, ')
          ..write('isFolder: $isFolder, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('accessedAt: $accessedAt, ')
          ..write('parentId: $parentId, ')
          ..write('providerFileId: $providerFileId, ')
          ..write('contentHash: $contentHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      accountId,
      provider,
      name,
      path,
      sizeBytes,
      mimeType,
      category,
      isFolder,
      modifiedAt,
      accessedAt,
      parentId,
      providerFileId,
      contentHash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileRecordsTableData &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.provider == this.provider &&
          other.name == this.name &&
          other.path == this.path &&
          other.sizeBytes == this.sizeBytes &&
          other.mimeType == this.mimeType &&
          other.category == this.category &&
          other.isFolder == this.isFolder &&
          other.modifiedAt == this.modifiedAt &&
          other.accessedAt == this.accessedAt &&
          other.parentId == this.parentId &&
          other.providerFileId == this.providerFileId &&
          other.contentHash == this.contentHash);
}

class FileRecordsTableCompanion extends UpdateCompanion<FileRecordsTableData> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> provider;
  final Value<String> name;
  final Value<String> path;
  final Value<int?> sizeBytes;
  final Value<String> mimeType;
  final Value<String> category;
  final Value<bool> isFolder;
  final Value<int> modifiedAt;
  final Value<int?> accessedAt;
  final Value<String?> parentId;
  final Value<String> providerFileId;
  final Value<String?> contentHash;
  final Value<int> rowid;
  const FileRecordsTableCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.provider = const Value.absent(),
    this.name = const Value.absent(),
    this.path = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.category = const Value.absent(),
    this.isFolder = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.accessedAt = const Value.absent(),
    this.parentId = const Value.absent(),
    this.providerFileId = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FileRecordsTableCompanion.insert({
    required String id,
    required String accountId,
    required String provider,
    required String name,
    required String path,
    this.sizeBytes = const Value.absent(),
    required String mimeType,
    required String category,
    this.isFolder = const Value.absent(),
    required int modifiedAt,
    this.accessedAt = const Value.absent(),
    this.parentId = const Value.absent(),
    required String providerFileId,
    this.contentHash = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        accountId = Value(accountId),
        provider = Value(provider),
        name = Value(name),
        path = Value(path),
        mimeType = Value(mimeType),
        category = Value(category),
        modifiedAt = Value(modifiedAt),
        providerFileId = Value(providerFileId);
  static Insertable<FileRecordsTableData> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? provider,
    Expression<String>? name,
    Expression<String>? path,
    Expression<int>? sizeBytes,
    Expression<String>? mimeType,
    Expression<String>? category,
    Expression<bool>? isFolder,
    Expression<int>? modifiedAt,
    Expression<int>? accessedAt,
    Expression<String>? parentId,
    Expression<String>? providerFileId,
    Expression<String>? contentHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (provider != null) 'provider': provider,
      if (name != null) 'name': name,
      if (path != null) 'path': path,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (category != null) 'category': category,
      if (isFolder != null) 'is_folder': isFolder,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (accessedAt != null) 'accessed_at': accessedAt,
      if (parentId != null) 'parent_id': parentId,
      if (providerFileId != null) 'provider_file_id': providerFileId,
      if (contentHash != null) 'content_hash': contentHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FileRecordsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? accountId,
      Value<String>? provider,
      Value<String>? name,
      Value<String>? path,
      Value<int?>? sizeBytes,
      Value<String>? mimeType,
      Value<String>? category,
      Value<bool>? isFolder,
      Value<int>? modifiedAt,
      Value<int?>? accessedAt,
      Value<String?>? parentId,
      Value<String>? providerFileId,
      Value<String?>? contentHash,
      Value<int>? rowid}) {
    return FileRecordsTableCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      provider: provider ?? this.provider,
      name: name ?? this.name,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      category: category ?? this.category,
      isFolder: isFolder ?? this.isFolder,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      accessedAt: accessedAt ?? this.accessedAt,
      parentId: parentId ?? this.parentId,
      providerFileId: providerFileId ?? this.providerFileId,
      contentHash: contentHash ?? this.contentHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isFolder.present) {
      map['is_folder'] = Variable<bool>(isFolder.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (accessedAt.present) {
      map['accessed_at'] = Variable<int>(accessedAt.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (providerFileId.present) {
      map['provider_file_id'] = Variable<String>(providerFileId.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileRecordsTableCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('provider: $provider, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('category: $category, ')
          ..write('isFolder: $isFolder, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('accessedAt: $accessedAt, ')
          ..write('parentId: $parentId, ')
          ..write('providerFileId: $providerFileId, ')
          ..write('contentHash: $contentHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScanSessionsTableTable extends ScanSessionsTable
    with TableInfo<$ScanSessionsTableTable, ScanSessionsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScanSessionsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
      'started_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalFilesMeta =
      const VerificationMeta('totalFiles');
  @override
  late final GeneratedColumn<int> totalFiles = GeneratedColumn<int>(
      'total_files', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalFoldersMeta =
      const VerificationMeta('totalFolders');
  @override
  late final GeneratedColumn<int> totalFolders = GeneratedColumn<int>(
      'total_folders', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalBytesMeta =
      const VerificationMeta('totalBytes');
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
      'total_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        accountId,
        startedAt,
        completedAt,
        status,
        totalFiles,
        totalFolders,
        totalBytes,
        errorMessage
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_sessions';
  @override
  VerificationContext validateIntegrity(
      Insertable<ScanSessionsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_files')) {
      context.handle(
          _totalFilesMeta,
          totalFiles.isAcceptableOrUnknown(
              data['total_files']!, _totalFilesMeta));
    }
    if (data.containsKey('total_folders')) {
      context.handle(
          _totalFoldersMeta,
          totalFolders.isAcceptableOrUnknown(
              data['total_folders']!, _totalFoldersMeta));
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
          _totalBytesMeta,
          totalBytes.isAcceptableOrUnknown(
              data['total_bytes']!, _totalBytesMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanSessionsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanSessionsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_at']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      totalFiles: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_files'])!,
      totalFolders: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_folders'])!,
      totalBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_bytes'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
    );
  }

  @override
  $ScanSessionsTableTable createAlias(String alias) {
    return $ScanSessionsTableTable(attachedDatabase, alias);
  }
}

class ScanSessionsTableData extends DataClass
    implements Insertable<ScanSessionsTableData> {
  final String id;
  final String accountId;
  final int startedAt;
  final int? completedAt;
  final String status;
  final int totalFiles;
  final int totalFolders;
  final int totalBytes;
  final String? errorMessage;
  const ScanSessionsTableData(
      {required this.id,
      required this.accountId,
      required this.startedAt,
      this.completedAt,
      required this.status,
      required this.totalFiles,
      required this.totalFolders,
      required this.totalBytes,
      this.errorMessage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['status'] = Variable<String>(status);
    map['total_files'] = Variable<int>(totalFiles);
    map['total_folders'] = Variable<int>(totalFolders);
    map['total_bytes'] = Variable<int>(totalBytes);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  ScanSessionsTableCompanion toCompanion(bool nullToAbsent) {
    return ScanSessionsTableCompanion(
      id: Value(id),
      accountId: Value(accountId),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      status: Value(status),
      totalFiles: Value(totalFiles),
      totalFolders: Value(totalFolders),
      totalBytes: Value(totalBytes),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory ScanSessionsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanSessionsTableData(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      status: serializer.fromJson<String>(json['status']),
      totalFiles: serializer.fromJson<int>(json['totalFiles']),
      totalFolders: serializer.fromJson<int>(json['totalFolders']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'startedAt': serializer.toJson<int>(startedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'status': serializer.toJson<String>(status),
      'totalFiles': serializer.toJson<int>(totalFiles),
      'totalFolders': serializer.toJson<int>(totalFolders),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  ScanSessionsTableData copyWith(
          {String? id,
          String? accountId,
          int? startedAt,
          Value<int?> completedAt = const Value.absent(),
          String? status,
          int? totalFiles,
          int? totalFolders,
          int? totalBytes,
          Value<String?> errorMessage = const Value.absent()}) =>
      ScanSessionsTableData(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        status: status ?? this.status,
        totalFiles: totalFiles ?? this.totalFiles,
        totalFolders: totalFolders ?? this.totalFolders,
        totalBytes: totalBytes ?? this.totalBytes,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
      );
  ScanSessionsTableData copyWithCompanion(ScanSessionsTableCompanion data) {
    return ScanSessionsTableData(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      status: data.status.present ? data.status.value : this.status,
      totalFiles:
          data.totalFiles.present ? data.totalFiles.value : this.totalFiles,
      totalFolders: data.totalFolders.present
          ? data.totalFolders.value
          : this.totalFolders,
      totalBytes:
          data.totalBytes.present ? data.totalBytes.value : this.totalBytes,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanSessionsTableData(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('status: $status, ')
          ..write('totalFiles: $totalFiles, ')
          ..write('totalFolders: $totalFolders, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accountId, startedAt, completedAt, status,
      totalFiles, totalFolders, totalBytes, errorMessage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanSessionsTableData &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.status == this.status &&
          other.totalFiles == this.totalFiles &&
          other.totalFolders == this.totalFolders &&
          other.totalBytes == this.totalBytes &&
          other.errorMessage == this.errorMessage);
}

class ScanSessionsTableCompanion
    extends UpdateCompanion<ScanSessionsTableData> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<int> startedAt;
  final Value<int?> completedAt;
  final Value<String> status;
  final Value<int> totalFiles;
  final Value<int> totalFolders;
  final Value<int> totalBytes;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const ScanSessionsTableCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.totalFiles = const Value.absent(),
    this.totalFolders = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScanSessionsTableCompanion.insert({
    required String id,
    required String accountId,
    required int startedAt,
    this.completedAt = const Value.absent(),
    required String status,
    this.totalFiles = const Value.absent(),
    this.totalFolders = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        accountId = Value(accountId),
        startedAt = Value(startedAt),
        status = Value(status);
  static Insertable<ScanSessionsTableData> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<int>? startedAt,
    Expression<int>? completedAt,
    Expression<String>? status,
    Expression<int>? totalFiles,
    Expression<int>? totalFolders,
    Expression<int>? totalBytes,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (status != null) 'status': status,
      if (totalFiles != null) 'total_files': totalFiles,
      if (totalFolders != null) 'total_folders': totalFolders,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScanSessionsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? accountId,
      Value<int>? startedAt,
      Value<int?>? completedAt,
      Value<String>? status,
      Value<int>? totalFiles,
      Value<int>? totalFolders,
      Value<int>? totalBytes,
      Value<String?>? errorMessage,
      Value<int>? rowid}) {
    return ScanSessionsTableCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      totalFiles: totalFiles ?? this.totalFiles,
      totalFolders: totalFolders ?? this.totalFolders,
      totalBytes: totalBytes ?? this.totalBytes,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalFiles.present) {
      map['total_files'] = Variable<int>(totalFiles.value);
    }
    if (totalFolders.present) {
      map['total_folders'] = Variable<int>(totalFolders.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanSessionsTableCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('status: $status, ')
          ..write('totalFiles: $totalFiles, ')
          ..write('totalFolders: $totalFolders, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTableTable accountsTable = $AccountsTableTable(this);
  late final $FileRecordsTableTable fileRecordsTable =
      $FileRecordsTableTable(this);
  late final $ScanSessionsTableTable scanSessionsTable =
      $ScanSessionsTableTable(this);
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final FileRecordDao fileRecordDao = FileRecordDao(this as AppDatabase);
  late final ScanSessionDao scanSessionDao =
      ScanSessionDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [accountsTable, fileRecordsTable, scanSessionsTable];
}

typedef $$AccountsTableTableCreateCompanionBuilder = AccountsTableCompanion
    Function({
  required String id,
  required String provider,
  required String email,
  required String displayName,
  required String label,
  required int createdAt,
  Value<int?> lastScanAt,
  Value<int> totalFiles,
  Value<int> totalFolders,
  Value<int> totalBytes,
  Value<String?> photoUrl,
  Value<int> rowid,
});
typedef $$AccountsTableTableUpdateCompanionBuilder = AccountsTableCompanion
    Function({
  Value<String> id,
  Value<String> provider,
  Value<String> email,
  Value<String> displayName,
  Value<String> label,
  Value<int> createdAt,
  Value<int?> lastScanAt,
  Value<int> totalFiles,
  Value<int> totalFolders,
  Value<int> totalBytes,
  Value<String?> photoUrl,
  Value<int> rowid,
});

class $$AccountsTableTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastScanAt => $composableBuilder(
      column: $table.lastScanAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalFiles => $composableBuilder(
      column: $table.totalFiles, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalFolders => $composableBuilder(
      column: $table.totalFolders, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnFilters(column));
}

class $$AccountsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastScanAt => $composableBuilder(
      column: $table.lastScanAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalFiles => $composableBuilder(
      column: $table.totalFiles, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalFolders => $composableBuilder(
      column: $table.totalFolders,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoUrl => $composableBuilder(
      column: $table.photoUrl, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTableTable> {
  $$AccountsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastScanAt => $composableBuilder(
      column: $table.lastScanAt, builder: (column) => column);

  GeneratedColumn<int> get totalFiles => $composableBuilder(
      column: $table.totalFiles, builder: (column) => column);

  GeneratedColumn<int> get totalFolders => $composableBuilder(
      column: $table.totalFolders, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);
}

class $$AccountsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTableTable,
    AccountsTableData,
    $$AccountsTableTableFilterComposer,
    $$AccountsTableTableOrderingComposer,
    $$AccountsTableTableAnnotationComposer,
    $$AccountsTableTableCreateCompanionBuilder,
    $$AccountsTableTableUpdateCompanionBuilder,
    (
      AccountsTableData,
      BaseReferences<_$AppDatabase, $AccountsTableTable, AccountsTableData>
    ),
    AccountsTableData,
    PrefetchHooks Function()> {
  $$AccountsTableTableTableManager(_$AppDatabase db, $AccountsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> provider = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> lastScanAt = const Value.absent(),
            Value<int> totalFiles = const Value.absent(),
            Value<int> totalFolders = const Value.absent(),
            Value<int> totalBytes = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsTableCompanion(
            id: id,
            provider: provider,
            email: email,
            displayName: displayName,
            label: label,
            createdAt: createdAt,
            lastScanAt: lastScanAt,
            totalFiles: totalFiles,
            totalFolders: totalFolders,
            totalBytes: totalBytes,
            photoUrl: photoUrl,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String provider,
            required String email,
            required String displayName,
            required String label,
            required int createdAt,
            Value<int?> lastScanAt = const Value.absent(),
            Value<int> totalFiles = const Value.absent(),
            Value<int> totalFolders = const Value.absent(),
            Value<int> totalBytes = const Value.absent(),
            Value<String?> photoUrl = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsTableCompanion.insert(
            id: id,
            provider: provider,
            email: email,
            displayName: displayName,
            label: label,
            createdAt: createdAt,
            lastScanAt: lastScanAt,
            totalFiles: totalFiles,
            totalFolders: totalFolders,
            totalBytes: totalBytes,
            photoUrl: photoUrl,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AccountsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTableTable,
    AccountsTableData,
    $$AccountsTableTableFilterComposer,
    $$AccountsTableTableOrderingComposer,
    $$AccountsTableTableAnnotationComposer,
    $$AccountsTableTableCreateCompanionBuilder,
    $$AccountsTableTableUpdateCompanionBuilder,
    (
      AccountsTableData,
      BaseReferences<_$AppDatabase, $AccountsTableTable, AccountsTableData>
    ),
    AccountsTableData,
    PrefetchHooks Function()>;
typedef $$FileRecordsTableTableCreateCompanionBuilder
    = FileRecordsTableCompanion Function({
  required String id,
  required String accountId,
  required String provider,
  required String name,
  required String path,
  Value<int?> sizeBytes,
  required String mimeType,
  required String category,
  Value<bool> isFolder,
  required int modifiedAt,
  Value<int?> accessedAt,
  Value<String?> parentId,
  required String providerFileId,
  Value<String?> contentHash,
  Value<int> rowid,
});
typedef $$FileRecordsTableTableUpdateCompanionBuilder
    = FileRecordsTableCompanion Function({
  Value<String> id,
  Value<String> accountId,
  Value<String> provider,
  Value<String> name,
  Value<String> path,
  Value<int?> sizeBytes,
  Value<String> mimeType,
  Value<String> category,
  Value<bool> isFolder,
  Value<int> modifiedAt,
  Value<int?> accessedAt,
  Value<String?> parentId,
  Value<String> providerFileId,
  Value<String?> contentHash,
  Value<int> rowid,
});

class $$FileRecordsTableTableFilterComposer
    extends Composer<_$AppDatabase, $FileRecordsTableTable> {
  $$FileRecordsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFolder => $composableBuilder(
      column: $table.isFolder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get accessedAt => $composableBuilder(
      column: $table.accessedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerFileId => $composableBuilder(
      column: $table.providerFileId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => ColumnFilters(column));
}

class $$FileRecordsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $FileRecordsTableTable> {
  $$FileRecordsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get provider => $composableBuilder(
      column: $table.provider, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get path => $composableBuilder(
      column: $table.path, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mimeType => $composableBuilder(
      column: $table.mimeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFolder => $composableBuilder(
      column: $table.isFolder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get accessedAt => $composableBuilder(
      column: $table.accessedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerFileId => $composableBuilder(
      column: $table.providerFileId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => ColumnOrderings(column));
}

class $$FileRecordsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $FileRecordsTableTable> {
  $$FileRecordsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isFolder =>
      $composableBuilder(column: $table.isFolder, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
      column: $table.modifiedAt, builder: (column) => column);

  GeneratedColumn<int> get accessedAt => $composableBuilder(
      column: $table.accessedAt, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get providerFileId => $composableBuilder(
      column: $table.providerFileId, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
      column: $table.contentHash, builder: (column) => column);
}

class $$FileRecordsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FileRecordsTableTable,
    FileRecordsTableData,
    $$FileRecordsTableTableFilterComposer,
    $$FileRecordsTableTableOrderingComposer,
    $$FileRecordsTableTableAnnotationComposer,
    $$FileRecordsTableTableCreateCompanionBuilder,
    $$FileRecordsTableTableUpdateCompanionBuilder,
    (
      FileRecordsTableData,
      BaseReferences<_$AppDatabase, $FileRecordsTableTable,
          FileRecordsTableData>
    ),
    FileRecordsTableData,
    PrefetchHooks Function()> {
  $$FileRecordsTableTableTableManager(
      _$AppDatabase db, $FileRecordsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileRecordsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileRecordsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileRecordsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String> provider = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<int?> sizeBytes = const Value.absent(),
            Value<String> mimeType = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<bool> isFolder = const Value.absent(),
            Value<int> modifiedAt = const Value.absent(),
            Value<int?> accessedAt = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<String> providerFileId = const Value.absent(),
            Value<String?> contentHash = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FileRecordsTableCompanion(
            id: id,
            accountId: accountId,
            provider: provider,
            name: name,
            path: path,
            sizeBytes: sizeBytes,
            mimeType: mimeType,
            category: category,
            isFolder: isFolder,
            modifiedAt: modifiedAt,
            accessedAt: accessedAt,
            parentId: parentId,
            providerFileId: providerFileId,
            contentHash: contentHash,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String accountId,
            required String provider,
            required String name,
            required String path,
            Value<int?> sizeBytes = const Value.absent(),
            required String mimeType,
            required String category,
            Value<bool> isFolder = const Value.absent(),
            required int modifiedAt,
            Value<int?> accessedAt = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            required String providerFileId,
            Value<String?> contentHash = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FileRecordsTableCompanion.insert(
            id: id,
            accountId: accountId,
            provider: provider,
            name: name,
            path: path,
            sizeBytes: sizeBytes,
            mimeType: mimeType,
            category: category,
            isFolder: isFolder,
            modifiedAt: modifiedAt,
            accessedAt: accessedAt,
            parentId: parentId,
            providerFileId: providerFileId,
            contentHash: contentHash,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FileRecordsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FileRecordsTableTable,
    FileRecordsTableData,
    $$FileRecordsTableTableFilterComposer,
    $$FileRecordsTableTableOrderingComposer,
    $$FileRecordsTableTableAnnotationComposer,
    $$FileRecordsTableTableCreateCompanionBuilder,
    $$FileRecordsTableTableUpdateCompanionBuilder,
    (
      FileRecordsTableData,
      BaseReferences<_$AppDatabase, $FileRecordsTableTable,
          FileRecordsTableData>
    ),
    FileRecordsTableData,
    PrefetchHooks Function()>;
typedef $$ScanSessionsTableTableCreateCompanionBuilder
    = ScanSessionsTableCompanion Function({
  required String id,
  required String accountId,
  required int startedAt,
  Value<int?> completedAt,
  required String status,
  Value<int> totalFiles,
  Value<int> totalFolders,
  Value<int> totalBytes,
  Value<String?> errorMessage,
  Value<int> rowid,
});
typedef $$ScanSessionsTableTableUpdateCompanionBuilder
    = ScanSessionsTableCompanion Function({
  Value<String> id,
  Value<String> accountId,
  Value<int> startedAt,
  Value<int?> completedAt,
  Value<String> status,
  Value<int> totalFiles,
  Value<int> totalFolders,
  Value<int> totalBytes,
  Value<String?> errorMessage,
  Value<int> rowid,
});

class $$ScanSessionsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ScanSessionsTableTable> {
  $$ScanSessionsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalFiles => $composableBuilder(
      column: $table.totalFiles, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalFolders => $composableBuilder(
      column: $table.totalFolders, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));
}

class $$ScanSessionsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ScanSessionsTableTable> {
  $$ScanSessionsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalFiles => $composableBuilder(
      column: $table.totalFiles, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalFolders => $composableBuilder(
      column: $table.totalFolders,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));
}

class $$ScanSessionsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScanSessionsTableTable> {
  $$ScanSessionsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalFiles => $composableBuilder(
      column: $table.totalFiles, builder: (column) => column);

  GeneratedColumn<int> get totalFolders => $composableBuilder(
      column: $table.totalFolders, builder: (column) => column);

  GeneratedColumn<int> get totalBytes => $composableBuilder(
      column: $table.totalBytes, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);
}

class $$ScanSessionsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ScanSessionsTableTable,
    ScanSessionsTableData,
    $$ScanSessionsTableTableFilterComposer,
    $$ScanSessionsTableTableOrderingComposer,
    $$ScanSessionsTableTableAnnotationComposer,
    $$ScanSessionsTableTableCreateCompanionBuilder,
    $$ScanSessionsTableTableUpdateCompanionBuilder,
    (
      ScanSessionsTableData,
      BaseReferences<_$AppDatabase, $ScanSessionsTableTable,
          ScanSessionsTableData>
    ),
    ScanSessionsTableData,
    PrefetchHooks Function()> {
  $$ScanSessionsTableTableTableManager(
      _$AppDatabase db, $ScanSessionsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScanSessionsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScanSessionsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScanSessionsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<int> startedAt = const Value.absent(),
            Value<int?> completedAt = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> totalFiles = const Value.absent(),
            Value<int> totalFolders = const Value.absent(),
            Value<int> totalBytes = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScanSessionsTableCompanion(
            id: id,
            accountId: accountId,
            startedAt: startedAt,
            completedAt: completedAt,
            status: status,
            totalFiles: totalFiles,
            totalFolders: totalFolders,
            totalBytes: totalBytes,
            errorMessage: errorMessage,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String accountId,
            required int startedAt,
            Value<int?> completedAt = const Value.absent(),
            required String status,
            Value<int> totalFiles = const Value.absent(),
            Value<int> totalFolders = const Value.absent(),
            Value<int> totalBytes = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ScanSessionsTableCompanion.insert(
            id: id,
            accountId: accountId,
            startedAt: startedAt,
            completedAt: completedAt,
            status: status,
            totalFiles: totalFiles,
            totalFolders: totalFolders,
            totalBytes: totalBytes,
            errorMessage: errorMessage,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ScanSessionsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ScanSessionsTableTable,
    ScanSessionsTableData,
    $$ScanSessionsTableTableFilterComposer,
    $$ScanSessionsTableTableOrderingComposer,
    $$ScanSessionsTableTableAnnotationComposer,
    $$ScanSessionsTableTableCreateCompanionBuilder,
    $$ScanSessionsTableTableUpdateCompanionBuilder,
    (
      ScanSessionsTableData,
      BaseReferences<_$AppDatabase, $ScanSessionsTableTable,
          ScanSessionsTableData>
    ),
    ScanSessionsTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableTableManager get accountsTable =>
      $$AccountsTableTableTableManager(_db, _db.accountsTable);
  $$FileRecordsTableTableTableManager get fileRecordsTable =>
      $$FileRecordsTableTableTableManager(_db, _db.fileRecordsTable);
  $$ScanSessionsTableTableTableManager get scanSessionsTable =>
      $$ScanSessionsTableTableTableManager(_db, _db.scanSessionsTable);
}
