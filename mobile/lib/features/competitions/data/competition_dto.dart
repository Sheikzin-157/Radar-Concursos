import '../domain/competition.dart';

CompetitionSummary competitionSummaryFromJson(Map<String, dynamic> json) {
  final organization = _requiredMap(json, 'organization');
  final salary = _requiredMap(json, 'salary');
  final examBoardJson = _optionalMap(json['examBoard']);
  return CompetitionSummary(
    id: _requiredString(json, 'id'),
    title: _requiredString(json, 'title'),
    organization: CompetitionOrganization(
      id: _requiredString(organization, 'id'),
      officialName: _requiredString(organization, 'officialName'),
      acronym: _nullableString(organization['acronym']),
      governmentSphere: _nullableString(organization['governmentSphere']),
      state: _nullableString(organization['state']),
    ),
    examBoard: examBoardJson == null ? null : CompetitionExamBoard(
      id: _requiredString(examBoardJson, 'id'),
      officialName: _requiredString(examBoardJson, 'officialName'),
      acronym: _nullableString(examBoardJson['acronym']),
    ),
    currentStatus: _requiredString(json, 'currentStatus'),
    totalVacancies: _nullableInt(json['totalVacancies']),
    reserveRegistration: json['reserveRegistration'] as bool?,
    salary: _moneyRangeFromJson(salary),
    lastOfficialUpdateAt: _nullableDate(json['lastOfficialUpdateAt']),
    lastValidatedAt: _nullableDate(json['lastValidatedAt']),
  );
}

CompetitionDetail competitionDetailFromJson(Map<String, dynamic> json) {
  final base = competitionSummaryFromJson(json);
  final careerJson = _optionalMap(json['career']);
  final fee = _requiredMap(json, 'registrationFee');
  return CompetitionDetail(
    id: base.id,
    title: base.title,
    organization: base.organization,
    examBoard: base.examBoard,
    currentStatus: base.currentStatus,
    totalVacancies: base.totalVacancies,
    reserveRegistration: base.reserveRegistration,
    salary: base.salary,
    lastOfficialUpdateAt: base.lastOfficialUpdateAt,
    lastValidatedAt: base.lastValidatedAt,
    competitionType: _nullableString(json['competitionType']),
    governmentSphere: _nullableString(json['governmentSphere']),
    summary: _nullableString(json['summary']),
    career: careerJson == null ? null : CompetitionCareer(id: _requiredString(careerJson, 'id'), name: _requiredString(careerJson, 'name')),
    registrationFee: _moneyRangeFromJson(fee),
    officialUrl: _nullableString(json['officialUrl']),
  );
}

MoneyRange _moneyRangeFromJson(Map<String, dynamic> json) => MoneyRange(min: _nullableDouble(json['min']), max: _nullableDouble(json['max']), currency: _requiredString(json, 'currency'));

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final map = _optionalMap(json[key]);
  if (map == null) throw FormatException('Campo obrigatório inválido: $key');
  return map;
}

Map<String, dynamic>? _optionalMap(Object? value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw FormatException('Campo obrigatório inválido: $key');
}

String? _nullableString(Object? value) => value is String ? value : null;
int? _nullableInt(Object? value) => value is int ? value : value is num ? value.toInt() : null;
double? _nullableDouble(Object? value) => value is num ? value.toDouble() : null;
DateTime? _nullableDate(Object? value) => value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
