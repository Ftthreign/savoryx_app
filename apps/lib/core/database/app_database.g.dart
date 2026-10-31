// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalAccountsTable extends LocalAccounts
    with TableInfo<$LocalAccountsTable, LocalAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _balanceMeta =
      const VerificationMeta('balance');
  @override
  late final GeneratedColumn<BigInt> balance = GeneratedColumn<BigInt>(
      'balance', aliasedName, false,
      type: DriftSqlType.bigInt,
      requiredDuringInsert: false,
      clientDefault: () => BigInt.zero);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('IDR'));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        balance,
        currency,
        createdAt,
        updatedAt,
        deletedAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_accounts';
  @override
  VerificationContext validateIntegrity(Insertable<LocalAccount> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('balance')) {
      context.handle(_balanceMeta,
          balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAccount(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      balance: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}balance'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalAccountsTable createAlias(String alias) {
    return $LocalAccountsTable(attachedDatabase, alias);
  }
}

class LocalAccount extends DataClass implements Insertable<LocalAccount> {
  final String id;
  final String name;
  final String type;
  final BigInt balance;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isSynced;
  const LocalAccount(
      {required this.id,
      required this.name,
      required this.type,
      required this.balance,
      required this.currency,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['balance'] = Variable<BigInt>(balance);
    map['currency'] = Variable<String>(currency);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalAccountsCompanion toCompanion(bool nullToAbsent) {
    return LocalAccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      balance: Value(balance),
      currency: Value(currency),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalAccount.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAccount(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      balance: serializer.fromJson<BigInt>(json['balance']),
      currency: serializer.fromJson<String>(json['currency']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'balance': serializer.toJson<BigInt>(balance),
      'currency': serializer.toJson<String>(currency),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalAccount copyWith(
          {String? id,
          String? name,
          String? type,
          BigInt? balance,
          String? currency,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? isSynced}) =>
      LocalAccount(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        currency: currency ?? this.currency,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalAccount copyWithCompanion(LocalAccountsCompanion data) {
    return LocalAccount(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      balance: data.balance.present ? data.balance.value : this.balance,
      currency: data.currency.present ? data.currency.value : this.currency,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccount(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('balance: $balance, ')
          ..write('currency: $currency, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, balance, currency, createdAt,
      updatedAt, deletedAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAccount &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.balance == this.balance &&
          other.currency == this.currency &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.isSynced == this.isSynced);
}

class LocalAccountsCompanion extends UpdateCompanion<LocalAccount> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<BigInt> balance;
  final Value<String> currency;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalAccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.balance = const Value.absent(),
    this.currency = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAccountsCompanion.insert({
    required String id,
    required String name,
    required String type,
    this.balance = const Value.absent(),
    this.currency = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalAccount> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<BigInt>? balance,
    Expression<String>? currency,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (balance != null) 'balance': balance,
      if (currency != null) 'currency': currency,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAccountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? type,
      Value<BigInt>? balance,
      Value<String>? currency,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalAccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (balance.present) {
      map['balance'] = Variable<BigInt>(balance.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('balance: $balance, ')
          ..write('currency: $currency, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCategoriesTable extends LocalCategories
    with TableInfo<$LocalCategoriesTable, LocalCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 64),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 7, maxTextLength: 7),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _isWantsMeta =
      const VerificationMeta('isWants');
  @override
  late final GeneratedColumn<bool> isWants = GeneratedColumn<bool>(
      'is_wants', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_wants" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        icon,
        color,
        isWants,
        createdAt,
        updatedAt,
        deletedAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_categories';
  @override
  VerificationContext validateIntegrity(Insertable<LocalCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('is_wants')) {
      context.handle(_isWantsMeta,
          isWants.isAcceptableOrUnknown(data['is_wants']!, _isWantsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
      isWants: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_wants'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalCategoriesTable createAlias(String alias) {
    return $LocalCategoriesTable(attachedDatabase, alias);
  }
}

class LocalCategory extends DataClass implements Insertable<LocalCategory> {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isWants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isSynced;
  const LocalCategory(
      {required this.id,
      required this.name,
      required this.icon,
      required this.color,
      required this.isWants,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['color'] = Variable<String>(color);
    map['is_wants'] = Variable<bool>(isWants);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalCategoriesCompanion toCompanion(bool nullToAbsent) {
    return LocalCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      color: Value(color),
      isWants: Value(isWants),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      color: serializer.fromJson<String>(json['color']),
      isWants: serializer.fromJson<bool>(json['isWants']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'color': serializer.toJson<String>(color),
      'isWants': serializer.toJson<bool>(isWants),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalCategory copyWith(
          {String? id,
          String? name,
          String? icon,
          String? color,
          bool? isWants,
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? isSynced}) =>
      LocalCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        isWants: isWants ?? this.isWants,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalCategory copyWithCompanion(LocalCategoriesCompanion data) {
    return LocalCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      isWants: data.isWants.present ? data.isWants.value : this.isWants,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isWants: $isWants, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, icon, color, isWants, createdAt,
      updatedAt, deletedAt, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.isWants == this.isWants &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.isSynced == this.isSynced);
}

class LocalCategoriesCompanion extends UpdateCompanion<LocalCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<String> color;
  final Value<bool> isWants;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.isWants = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalCategoriesCompanion.insert({
    required String id,
    required String name,
    required String icon,
    required String color,
    this.isWants = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        icon = Value(icon),
        color = Value(color),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<bool>? isWants,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (isWants != null) 'is_wants': isWants,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalCategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? icon,
      Value<String>? color,
      Value<bool>? isWants,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isWants: isWants ?? this.isWants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (isWants.present) {
      map['is_wants'] = Variable<bool>(isWants.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('isWants: $isWants, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTransactionsTable extends LocalTransactions
    with TableInfo<$LocalTransactionsTable, LocalTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTransactionsTable(this.attachedDatabase, [this._alias]);
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
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES local_accounts (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES local_categories (id)'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<BigInt> amount = GeneratedColumn<BigInt>(
      'amount', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 3, maxTextLength: 3),
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('IDR'));
  static const VerificationMeta _exchangeRateToBaseMeta =
      const VerificationMeta('exchangeRateToBase');
  @override
  late final GeneratedColumn<BigInt> exchangeRateToBase =
      GeneratedColumn<BigInt>('exchange_rate_to_base', aliasedName, false,
          type: DriftSqlType.bigInt,
          requiredDuringInsert: false,
          clientDefault: () => BigInt.from(1000000));
  static const VerificationMeta _baseAmountMeta =
      const VerificationMeta('baseAmount');
  @override
  late final GeneratedColumn<BigInt> baseAmount = GeneratedColumn<BigInt>(
      'base_amount', aliasedName, false,
      type: DriftSqlType.bigInt, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transactionTimeMeta =
      const VerificationMeta('transactionTime');
  @override
  late final GeneratedColumn<DateTime> transactionTime =
      GeneratedColumn<DateTime>('transaction_time', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        accountId,
        categoryId,
        amount,
        currency,
        exchangeRateToBase,
        baseAmount,
        type,
        transactionTime,
        note,
        createdAt,
        updatedAt,
        deletedAt,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_transactions';
  @override
  VerificationContext validateIntegrity(Insertable<LocalTransaction> instance,
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
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    }
    if (data.containsKey('exchange_rate_to_base')) {
      context.handle(
          _exchangeRateToBaseMeta,
          exchangeRateToBase.isAcceptableOrUnknown(
              data['exchange_rate_to_base']!, _exchangeRateToBaseMeta));
    }
    if (data.containsKey('base_amount')) {
      context.handle(
          _baseAmountMeta,
          baseAmount.isAcceptableOrUnknown(
              data['base_amount']!, _baseAmountMeta));
    } else if (isInserting) {
      context.missing(_baseAmountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('transaction_time')) {
      context.handle(
          _transactionTimeMeta,
          transactionTime.isAcceptableOrUnknown(
              data['transaction_time']!, _transactionTimeMeta));
    } else if (isInserting) {
      context.missing(_transactionTimeMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTransaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}amount'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      exchangeRateToBase: attachedDatabase.typeMapping.read(DriftSqlType.bigInt,
          data['${effectivePrefix}exchange_rate_to_base'])!,
      baseAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.bigInt, data['${effectivePrefix}base_amount'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      transactionTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}transaction_time'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $LocalTransactionsTable createAlias(String alias) {
    return $LocalTransactionsTable(attachedDatabase, alias);
  }
}

class LocalTransaction extends DataClass
    implements Insertable<LocalTransaction> {
  final String id;
  final String accountId;
  final String? categoryId;
  final BigInt amount;
  final String currency;
  final BigInt exchangeRateToBase;
  final BigInt baseAmount;
  final String type;
  final DateTime transactionTime;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isSynced;
  const LocalTransaction(
      {required this.id,
      required this.accountId,
      this.categoryId,
      required this.amount,
      required this.currency,
      required this.exchangeRateToBase,
      required this.baseAmount,
      required this.type,
      required this.transactionTime,
      this.note,
      required this.createdAt,
      required this.updatedAt,
      this.deletedAt,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['amount'] = Variable<BigInt>(amount);
    map['currency'] = Variable<String>(currency);
    map['exchange_rate_to_base'] = Variable<BigInt>(exchangeRateToBase);
    map['base_amount'] = Variable<BigInt>(baseAmount);
    map['type'] = Variable<String>(type);
    map['transaction_time'] = Variable<DateTime>(transactionTime);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  LocalTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LocalTransactionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amount: Value(amount),
      currency: Value(currency),
      exchangeRateToBase: Value(exchangeRateToBase),
      baseAmount: Value(baseAmount),
      type: Value(type),
      transactionTime: Value(transactionTime),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      isSynced: Value(isSynced),
    );
  }

  factory LocalTransaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTransaction(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      amount: serializer.fromJson<BigInt>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      exchangeRateToBase:
          serializer.fromJson<BigInt>(json['exchangeRateToBase']),
      baseAmount: serializer.fromJson<BigInt>(json['baseAmount']),
      type: serializer.fromJson<String>(json['type']),
      transactionTime: serializer.fromJson<DateTime>(json['transactionTime']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'amount': serializer.toJson<BigInt>(amount),
      'currency': serializer.toJson<String>(currency),
      'exchangeRateToBase': serializer.toJson<BigInt>(exchangeRateToBase),
      'baseAmount': serializer.toJson<BigInt>(baseAmount),
      'type': serializer.toJson<String>(type),
      'transactionTime': serializer.toJson<DateTime>(transactionTime),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  LocalTransaction copyWith(
          {String? id,
          String? accountId,
          Value<String?> categoryId = const Value.absent(),
          BigInt? amount,
          String? currency,
          BigInt? exchangeRateToBase,
          BigInt? baseAmount,
          String? type,
          DateTime? transactionTime,
          Value<String?> note = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> deletedAt = const Value.absent(),
          bool? isSynced}) =>
      LocalTransaction(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
        baseAmount: baseAmount ?? this.baseAmount,
        type: type ?? this.type,
        transactionTime: transactionTime ?? this.transactionTime,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        isSynced: isSynced ?? this.isSynced,
      );
  LocalTransaction copyWithCompanion(LocalTransactionsCompanion data) {
    return LocalTransaction(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      exchangeRateToBase: data.exchangeRateToBase.present
          ? data.exchangeRateToBase.value
          : this.exchangeRateToBase,
      baseAmount:
          data.baseAmount.present ? data.baseAmount.value : this.baseAmount,
      type: data.type.present ? data.type.value : this.type,
      transactionTime: data.transactionTime.present
          ? data.transactionTime.value
          : this.transactionTime,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransaction(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('exchangeRateToBase: $exchangeRateToBase, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('type: $type, ')
          ..write('transactionTime: $transactionTime, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      accountId,
      categoryId,
      amount,
      currency,
      exchangeRateToBase,
      baseAmount,
      type,
      transactionTime,
      note,
      createdAt,
      updatedAt,
      deletedAt,
      isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTransaction &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.exchangeRateToBase == this.exchangeRateToBase &&
          other.baseAmount == this.baseAmount &&
          other.type == this.type &&
          other.transactionTime == this.transactionTime &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.isSynced == this.isSynced);
}

class LocalTransactionsCompanion extends UpdateCompanion<LocalTransaction> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String?> categoryId;
  final Value<BigInt> amount;
  final Value<String> currency;
  final Value<BigInt> exchangeRateToBase;
  final Value<BigInt> baseAmount;
  final Value<String> type;
  final Value<DateTime> transactionTime;
  final Value<String?> note;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const LocalTransactionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.exchangeRateToBase = const Value.absent(),
    this.baseAmount = const Value.absent(),
    this.type = const Value.absent(),
    this.transactionTime = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTransactionsCompanion.insert({
    required String id,
    required String accountId,
    this.categoryId = const Value.absent(),
    required BigInt amount,
    this.currency = const Value.absent(),
    this.exchangeRateToBase = const Value.absent(),
    required BigInt baseAmount,
    required String type,
    required DateTime transactionTime,
    this.note = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        accountId = Value(accountId),
        amount = Value(amount),
        baseAmount = Value(baseAmount),
        type = Value(type),
        transactionTime = Value(transactionTime),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<LocalTransaction> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? categoryId,
    Expression<BigInt>? amount,
    Expression<String>? currency,
    Expression<BigInt>? exchangeRateToBase,
    Expression<BigInt>? baseAmount,
    Expression<String>? type,
    Expression<DateTime>? transactionTime,
    Expression<String>? note,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (exchangeRateToBase != null)
        'exchange_rate_to_base': exchangeRateToBase,
      if (baseAmount != null) 'base_amount': baseAmount,
      if (type != null) 'type': type,
      if (transactionTime != null) 'transaction_time': transactionTime,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? accountId,
      Value<String?>? categoryId,
      Value<BigInt>? amount,
      Value<String>? currency,
      Value<BigInt>? exchangeRateToBase,
      Value<BigInt>? baseAmount,
      Value<String>? type,
      Value<DateTime>? transactionTime,
      Value<String?>? note,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? deletedAt,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return LocalTransactionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      exchangeRateToBase: exchangeRateToBase ?? this.exchangeRateToBase,
      baseAmount: baseAmount ?? this.baseAmount,
      type: type ?? this.type,
      transactionTime: transactionTime ?? this.transactionTime,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isSynced: isSynced ?? this.isSynced,
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
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<BigInt>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (exchangeRateToBase.present) {
      map['exchange_rate_to_base'] = Variable<BigInt>(exchangeRateToBase.value);
    }
    if (baseAmount.present) {
      map['base_amount'] = Variable<BigInt>(baseAmount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (transactionTime.present) {
      map['transaction_time'] = Variable<DateTime>(transactionTime.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('exchangeRateToBase: $exchangeRateToBase, ')
          ..write('baseAmount: $baseAmount, ')
          ..write('type: $type, ')
          ..write('transactionTime: $transactionTime, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalAccountsTable localAccounts = $LocalAccountsTable(this);
  late final $LocalCategoriesTable localCategories =
      $LocalCategoriesTable(this);
  late final $LocalTransactionsTable localTransactions =
      $LocalTransactionsTable(this);
  late final Index idxLocalTxAccTime = Index('idx_local_tx_acc_time',
      'CREATE INDEX idx_local_tx_acc_time ON local_transactions (account_id, transaction_time)');
  late final AccountDao accountDao = AccountDao(this as AppDatabase);
  late final CategoryDao categoryDao = CategoryDao(this as AppDatabase);
  late final TransactionDao transactionDao =
      TransactionDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [localAccounts, localCategories, localTransactions, idxLocalTxAccTime];
}

typedef $$LocalAccountsTableCreateCompanionBuilder = LocalAccountsCompanion
    Function({
  required String id,
  required String name,
  required String type,
  Value<BigInt> balance,
  Value<String> currency,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalAccountsTableUpdateCompanionBuilder = LocalAccountsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> type,
  Value<BigInt> balance,
  Value<String> currency,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LocalAccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalAccountsTable,
    LocalAccount,
    $$LocalAccountsTableFilterComposer,
    $$LocalAccountsTableOrderingComposer,
    $$LocalAccountsTableCreateCompanionBuilder,
    $$LocalAccountsTableUpdateCompanionBuilder> {
  $$LocalAccountsTableTableManager(_$AppDatabase db, $LocalAccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalAccountsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalAccountsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<BigInt> balance = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalAccountsCompanion(
            id: id,
            name: name,
            type: type,
            balance: balance,
            currency: currency,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String type,
            Value<BigInt> balance = const Value.absent(),
            Value<String> currency = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalAccountsCompanion.insert(
            id: id,
            name: name,
            type: type,
            balance: balance,
            currency: currency,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
        ));
}

class $$LocalAccountsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get balance => $state.composableBuilder(
      column: $state.table.balance,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter localTransactionsRefs(
      ComposableFilter Function($$LocalTransactionsTableFilterComposer f) f) {
    final $$LocalTransactionsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.localTransactions,
            getReferencedColumn: (t) => t.accountId,
            builder: (joinBuilder, parentComposers) =>
                $$LocalTransactionsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.localTransactions,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }
}

class $$LocalAccountsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get balance => $state.composableBuilder(
      column: $state.table.balance,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalCategoriesTableCreateCompanionBuilder = LocalCategoriesCompanion
    Function({
  required String id,
  required String name,
  required String icon,
  required String color,
  Value<bool> isWants,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalCategoriesTableUpdateCompanionBuilder = LocalCategoriesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> icon,
  Value<String> color,
  Value<bool> isWants,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LocalCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalCategoriesTable,
    LocalCategory,
    $$LocalCategoriesTableFilterComposer,
    $$LocalCategoriesTableOrderingComposer,
    $$LocalCategoriesTableCreateCompanionBuilder,
    $$LocalCategoriesTableUpdateCompanionBuilder> {
  $$LocalCategoriesTableTableManager(
      _$AppDatabase db, $LocalCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalCategoriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LocalCategoriesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<bool> isWants = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalCategoriesCompanion(
            id: id,
            name: name,
            icon: icon,
            color: color,
            isWants: isWants,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String icon,
            required String color,
            Value<bool> isWants = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalCategoriesCompanion.insert(
            id: id,
            name: name,
            icon: icon,
            color: color,
            isWants: isWants,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
        ));
}

class $$LocalCategoriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isWants => $state.composableBuilder(
      column: $state.table.isWants,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter localTransactionsRefs(
      ComposableFilter Function($$LocalTransactionsTableFilterComposer f) f) {
    final $$LocalTransactionsTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.localTransactions,
            getReferencedColumn: (t) => t.categoryId,
            builder: (joinBuilder, parentComposers) =>
                $$LocalTransactionsTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.localTransactions,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }
}

class $$LocalCategoriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalCategoriesTable> {
  $$LocalCategoriesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get color => $state.composableBuilder(
      column: $state.table.color,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isWants => $state.composableBuilder(
      column: $state.table.isWants,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$LocalTransactionsTableCreateCompanionBuilder
    = LocalTransactionsCompanion Function({
  required String id,
  required String accountId,
  Value<String?> categoryId,
  required BigInt amount,
  Value<String> currency,
  Value<BigInt> exchangeRateToBase,
  required BigInt baseAmount,
  required String type,
  required DateTime transactionTime,
  Value<String?> note,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$LocalTransactionsTableUpdateCompanionBuilder
    = LocalTransactionsCompanion Function({
  Value<String> id,
  Value<String> accountId,
  Value<String?> categoryId,
  Value<BigInt> amount,
  Value<String> currency,
  Value<BigInt> exchangeRateToBase,
  Value<BigInt> baseAmount,
  Value<String> type,
  Value<DateTime> transactionTime,
  Value<String?> note,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$LocalTransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalTransactionsTable,
    LocalTransaction,
    $$LocalTransactionsTableFilterComposer,
    $$LocalTransactionsTableOrderingComposer,
    $$LocalTransactionsTableCreateCompanionBuilder,
    $$LocalTransactionsTableUpdateCompanionBuilder> {
  $$LocalTransactionsTableTableManager(
      _$AppDatabase db, $LocalTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LocalTransactionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$LocalTransactionsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<BigInt> amount = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<BigInt> exchangeRateToBase = const Value.absent(),
            Value<BigInt> baseAmount = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<DateTime> transactionTime = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTransactionsCompanion(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            currency: currency,
            exchangeRateToBase: exchangeRateToBase,
            baseAmount: baseAmount,
            type: type,
            transactionTime: transactionTime,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String accountId,
            Value<String?> categoryId = const Value.absent(),
            required BigInt amount,
            Value<String> currency = const Value.absent(),
            Value<BigInt> exchangeRateToBase = const Value.absent(),
            required BigInt baseAmount,
            required String type,
            required DateTime transactionTime,
            Value<String?> note = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> deletedAt = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalTransactionsCompanion.insert(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            currency: currency,
            exchangeRateToBase: exchangeRateToBase,
            baseAmount: baseAmount,
            type: type,
            transactionTime: transactionTime,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            isSynced: isSynced,
            rowid: rowid,
          ),
        ));
}

class $$LocalTransactionsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get exchangeRateToBase => $state.composableBuilder(
      column: $state.table.exchangeRateToBase,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<BigInt> get baseAmount => $state.composableBuilder(
      column: $state.table.baseAmount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get transactionTime => $state.composableBuilder(
      column: $state.table.transactionTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$LocalAccountsTableFilterComposer get accountId {
    final $$LocalAccountsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $state.db.localAccounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$LocalAccountsTableFilterComposer(ComposerState($state.db,
                $state.db.localAccounts, joinBuilder, parentComposers)));
    return composer;
  }

  $$LocalCategoriesTableFilterComposer get categoryId {
    final $$LocalCategoriesTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryId,
            referencedTable: $state.db.localCategories,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$LocalCategoriesTableFilterComposer(ComposerState($state.db,
                    $state.db.localCategories, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$LocalTransactionsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalTransactionsTable> {
  $$LocalTransactionsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get amount => $state.composableBuilder(
      column: $state.table.amount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get currency => $state.composableBuilder(
      column: $state.table.currency,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get exchangeRateToBase => $state.composableBuilder(
      column: $state.table.exchangeRateToBase,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<BigInt> get baseAmount => $state.composableBuilder(
      column: $state.table.baseAmount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get transactionTime => $state.composableBuilder(
      column: $state.table.transactionTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get note => $state.composableBuilder(
      column: $state.table.note,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get deletedAt => $state.composableBuilder(
      column: $state.table.deletedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isSynced => $state.composableBuilder(
      column: $state.table.isSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$LocalAccountsTableOrderingComposer get accountId {
    final $$LocalAccountsTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.accountId,
            referencedTable: $state.db.localAccounts,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$LocalAccountsTableOrderingComposer(ComposerState($state.db,
                    $state.db.localAccounts, joinBuilder, parentComposers)));
    return composer;
  }

  $$LocalCategoriesTableOrderingComposer get categoryId {
    final $$LocalCategoriesTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryId,
            referencedTable: $state.db.localCategories,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$LocalCategoriesTableOrderingComposer(ComposerState($state.db,
                    $state.db.localCategories, joinBuilder, parentComposers)));
    return composer;
  }
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalAccountsTableTableManager get localAccounts =>
      $$LocalAccountsTableTableManager(_db, _db.localAccounts);
  $$LocalCategoriesTableTableManager get localCategories =>
      $$LocalCategoriesTableTableManager(_db, _db.localCategories);
  $$LocalTransactionsTableTableManager get localTransactions =>
      $$LocalTransactionsTableTableManager(_db, _db.localTransactions);
}
