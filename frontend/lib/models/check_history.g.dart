// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_history.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCheckHistoryCollection on Isar {
  IsarCollection<CheckHistory> get checkHistorys => this.collection();
}

const CheckHistorySchema = CollectionSchema(
  name: r'CheckHistory',
  id: -567034101829865882,
  properties: {
    r'accessibleDomains': PropertySchema(
      id: 0,
      name: r'accessibleDomains',
      type: IsarType.long,
    ),
    r'isBsDetected': PropertySchema(
      id: 1,
      name: r'isBsDetected',
      type: IsarType.bool,
    ),
    r'isCustom': PropertySchema(
      id: 2,
      name: r'isCustom',
      type: IsarType.bool,
    ),
    r'timestamp': PropertySchema(
      id: 3,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'totalDomains': PropertySchema(
      id: 4,
      name: r'totalDomains',
      type: IsarType.long,
    )
  },
  estimateSize: _checkHistoryEstimateSize,
  serialize: _checkHistorySerialize,
  deserialize: _checkHistoryDeserialize,
  deserializeProp: _checkHistoryDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _checkHistoryGetId,
  getLinks: _checkHistoryGetLinks,
  attach: _checkHistoryAttach,
  version: '3.1.0+1',
);

int _checkHistoryEstimateSize(
  CheckHistory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _checkHistorySerialize(
  CheckHistory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.accessibleDomains);
  writer.writeBool(offsets[1], object.isBsDetected);
  writer.writeBool(offsets[2], object.isCustom);
  writer.writeDateTime(offsets[3], object.timestamp);
  writer.writeLong(offsets[4], object.totalDomains);
}

CheckHistory _checkHistoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CheckHistory();
  object.accessibleDomains = reader.readLong(offsets[0]);
  object.id = id;
  object.isBsDetected = reader.readBool(offsets[1]);
  object.isCustom = reader.readBool(offsets[2]);
  object.timestamp = reader.readDateTime(offsets[3]);
  object.totalDomains = reader.readLong(offsets[4]);
  return object;
}

P _checkHistoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _checkHistoryGetId(CheckHistory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _checkHistoryGetLinks(CheckHistory object) {
  return [];
}

void _checkHistoryAttach(
    IsarCollection<dynamic> col, Id id, CheckHistory object) {
  object.id = id;
}

extension CheckHistoryQueryWhereSort
    on QueryBuilder<CheckHistory, CheckHistory, QWhere> {
  QueryBuilder<CheckHistory, CheckHistory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CheckHistoryQueryWhere
    on QueryBuilder<CheckHistory, CheckHistory, QWhereClause> {
  QueryBuilder<CheckHistory, CheckHistory, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CheckHistoryQueryFilter
    on QueryBuilder<CheckHistory, CheckHistory, QFilterCondition> {
  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      accessibleDomainsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accessibleDomains',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      accessibleDomainsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accessibleDomains',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      accessibleDomainsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accessibleDomains',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      accessibleDomainsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accessibleDomains',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      isBsDetectedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isBsDetected',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      isCustomEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCustom',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      timestampEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      totalDomainsEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'totalDomains',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      totalDomainsGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'totalDomains',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      totalDomainsLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'totalDomains',
        value: value,
      ));
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterFilterCondition>
      totalDomainsBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'totalDomains',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension CheckHistoryQueryObject
    on QueryBuilder<CheckHistory, CheckHistory, QFilterCondition> {}

extension CheckHistoryQueryLinks
    on QueryBuilder<CheckHistory, CheckHistory, QFilterCondition> {}

extension CheckHistoryQuerySortBy
    on QueryBuilder<CheckHistory, CheckHistory, QSortBy> {
  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy>
      sortByAccessibleDomains() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessibleDomains', Sort.asc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy>
      sortByAccessibleDomainsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessibleDomains', Sort.desc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> sortByIsBsDetected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBsDetected', Sort.asc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy>
      sortByIsBsDetectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBsDetected', Sort.desc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> sortByIsCustom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.asc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> sortByIsCustomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.desc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> sortByTotalDomains() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDomains', Sort.asc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy>
      sortByTotalDomainsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDomains', Sort.desc);
    });
  }
}

extension CheckHistoryQuerySortThenBy
    on QueryBuilder<CheckHistory, CheckHistory, QSortThenBy> {
  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy>
      thenByAccessibleDomains() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessibleDomains', Sort.asc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy>
      thenByAccessibleDomainsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessibleDomains', Sort.desc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> thenByIsBsDetected() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBsDetected', Sort.asc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy>
      thenByIsBsDetectedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isBsDetected', Sort.desc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> thenByIsCustom() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.asc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> thenByIsCustomDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCustom', Sort.desc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy> thenByTotalDomains() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDomains', Sort.asc);
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QAfterSortBy>
      thenByTotalDomainsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'totalDomains', Sort.desc);
    });
  }
}

extension CheckHistoryQueryWhereDistinct
    on QueryBuilder<CheckHistory, CheckHistory, QDistinct> {
  QueryBuilder<CheckHistory, CheckHistory, QDistinct>
      distinctByAccessibleDomains() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accessibleDomains');
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QDistinct> distinctByIsBsDetected() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isBsDetected');
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QDistinct> distinctByIsCustom() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCustom');
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<CheckHistory, CheckHistory, QDistinct> distinctByTotalDomains() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'totalDomains');
    });
  }
}

extension CheckHistoryQueryProperty
    on QueryBuilder<CheckHistory, CheckHistory, QQueryProperty> {
  QueryBuilder<CheckHistory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CheckHistory, int, QQueryOperations>
      accessibleDomainsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accessibleDomains');
    });
  }

  QueryBuilder<CheckHistory, bool, QQueryOperations> isBsDetectedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isBsDetected');
    });
  }

  QueryBuilder<CheckHistory, bool, QQueryOperations> isCustomProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCustom');
    });
  }

  QueryBuilder<CheckHistory, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<CheckHistory, int, QQueryOperations> totalDomainsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'totalDomains');
    });
  }
}
