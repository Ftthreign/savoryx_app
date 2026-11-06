import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:savoryx/features/transaction/domain/entities/transaction_entity.dart';

part 'search_result_entity.freezed.dart';

@freezed
class SearchResultEntity with _$SearchResultEntity {
  const factory SearchResultEntity({
    required TransactionEntity transaction,
    @Default(0.0) double relevanceRank,
    String? matchedSnippet,
    @Default([]) List<String> matchedFields,
  }) = _SearchResultEntity;
}
