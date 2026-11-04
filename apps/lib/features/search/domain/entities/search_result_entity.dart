import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

class SearchResultEntity {
  const SearchResultEntity({
    required this.transaction,
    this.relevanceRank = 0.0,
    this.matchedSnippet,
    this.matchedFields = const [],
  });

  final TransactionEntity transaction;
  final double relevanceRank;
  final String? matchedSnippet;
  final List<String> matchedFields;

  SearchResultEntity copyWith({
    TransactionEntity? transaction,
    double? relevanceRank,
    String? matchedSnippet,
    List<String>? matchedFields,
  }) {
    return SearchResultEntity(
      transaction: transaction ?? this.transaction,
      relevanceRank: relevanceRank ?? this.relevanceRank,
      matchedSnippet: matchedSnippet ?? this.matchedSnippet,
      matchedFields: matchedFields ?? this.matchedFields,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResultEntity &&
          runtimeType == other.runtimeType &&
          transaction.id == other.transaction.id &&
          relevanceRank == other.relevanceRank;

  @override
  int get hashCode => transaction.id.hashCode ^ relevanceRank.hashCode;
}
