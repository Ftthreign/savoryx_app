abstract final class TransactionsFtsTable {
  static const String tableName = 'transactions_fts';

  static const String createTableSql = '''
CREATE VIRTUAL TABLE IF NOT EXISTS transactions_fts USING fts5(
  id UNINDEXED,
  note,
  tokenize='unicode61'
);
''';

  static const String createInsertTriggerSql = '''
CREATE TRIGGER IF NOT EXISTS trig_transactions_ai AFTER INSERT ON local_transactions
BEGIN
  INSERT INTO transactions_fts(id, note)
  VALUES (new.id, coalesce(new.note, ''));
END;
''';

  static const String createUpdateTriggerSql = '''
CREATE TRIGGER IF NOT EXISTS trig_transactions_au AFTER UPDATE ON local_transactions
BEGIN
  UPDATE transactions_fts
  SET note = coalesce(new.note, '')
  WHERE id = old.id;
END;
''';

  static const String createDeleteTriggerSql = '''
CREATE TRIGGER IF NOT EXISTS trig_transactions_ad AFTER DELETE ON local_transactions
BEGIN
  DELETE FROM transactions_fts WHERE id = old.id;
END;
''';

  static const String backfillSql = '''
INSERT INTO transactions_fts(id, note)
SELECT id, coalesce(note, '')
FROM local_transactions
WHERE deleted_at IS NULL
  AND id NOT IN (SELECT id FROM transactions_fts);
''';
}
