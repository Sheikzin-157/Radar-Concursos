class MoneyRange {
  const MoneyRange({required this.min, required this.max, required this.currency});
  final double? min;
  final double? max;
  final String currency;
}

class CompetitionOrganization {
  const CompetitionOrganization({required this.id, required this.officialName, required this.acronym, required this.governmentSphere, required this.state});
  final String id;
  final String officialName;
  final String? acronym;
  final String? governmentSphere;
  final String? state;
}

class CompetitionExamBoard {
  const CompetitionExamBoard({required this.id, required this.officialName, required this.acronym});
  final String id;
  final String officialName;
  final String? acronym;
}

class CompetitionCareer {
  const CompetitionCareer({required this.id, required this.name});
  final String id;
  final String name;
}

class CompetitionSummary {
  const CompetitionSummary({required this.id, required this.title, required this.organization, required this.examBoard, required this.currentStatus, required this.totalVacancies, required this.reserveRegistration, required this.salary, required this.lastOfficialUpdateAt, required this.lastValidatedAt});
  final String id;
  final String title;
  final CompetitionOrganization organization;
  final CompetitionExamBoard? examBoard;
  final String currentStatus;
  final int? totalVacancies;
  final bool? reserveRegistration;
  final MoneyRange salary;
  final DateTime? lastOfficialUpdateAt;
  final DateTime? lastValidatedAt;
}

class CompetitionDetail extends CompetitionSummary {
  const CompetitionDetail({required super.id, required super.title, required super.organization, required super.examBoard, required super.currentStatus, required super.totalVacancies, required super.reserveRegistration, required super.salary, required super.lastOfficialUpdateAt, required super.lastValidatedAt, required this.competitionType, required this.governmentSphere, required this.summary, required this.career, required this.registrationFee, required this.officialUrl});
  final String? competitionType;
  final String? governmentSphere;
  final String? summary;
  final CompetitionCareer? career;
  final MoneyRange registrationFee;
  final String? officialUrl;
}
