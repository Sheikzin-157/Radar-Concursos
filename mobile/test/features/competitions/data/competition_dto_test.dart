import 'package:flutter_test/flutter_test.dart';
import 'package:radar_concursos/features/competitions/data/competition_dto.dart';

void main() {
  test('converts competition summary response into domain model', () {
    final model = competitionSummaryFromJson({
      'id': '00000000-0000-0000-0000-000000000001',
      'title': 'Concurso de exemplo',
      'organization': {
        'id': '00000000-0000-0000-0000-000000000002',
        'officialName': 'Órgão Exemplo',
        'acronym': 'OE',
        'governmentSphere': 'federal',
        'state': 'PI',
      },
      'examBoard': null,
      'currentStatus': 'edital_publicado',
      'totalVacancies': 120,
      'reserveRegistration': true,
      'salary': {'min': 3500, 'max': 6200.5, 'currency': 'BRL'},
      'lastOfficialUpdateAt': '2026-10-10T12:00:00.000Z',
      'lastValidatedAt': null,
    });

    expect(model.title, 'Concurso de exemplo');
    expect(model.organization.acronym, 'OE');
    expect(model.totalVacancies, 120);
    expect(model.salary.max, 6200.5);
    expect(model.lastOfficialUpdateAt, isNotNull);
  });

  test('converts competition detail response into domain model', () {
    final model = competitionDetailFromJson({
      'id': '00000000-0000-0000-0000-000000000001',
      'title': 'Concurso de exemplo',
      'organization': {
        'id': '00000000-0000-0000-0000-000000000002',
        'officialName': 'Órgão Exemplo',
        'acronym': 'OE',
        'governmentSphere': 'federal',
        'state': 'PI',
      },
      'examBoard': {
        'id': '00000000-0000-0000-0000-000000000003',
        'officialName': 'Banca Exemplo',
        'acronym': 'BE',
      },
      'currentStatus': 'inscricoes_abertas',
      'totalVacancies': 10,
      'reserveRegistration': false,
      'salary': {'min': 5000, 'max': 5000, 'currency': 'BRL'},
      'lastOfficialUpdateAt': null,
      'lastValidatedAt': '2026-10-11T09:30:00.000Z',
      'competitionType': 'concurso_publico',
      'governmentSphere': 'federal',
      'summary': 'Resumo.',
      'career': {
        'id': '00000000-0000-0000-0000-000000000004',
        'name': 'Administrativa',
      },
      'registrationFee': {'min': 80, 'max': 120, 'currency': 'BRL'},
      'officialUrl': 'https://example.gov.br',
    });

    expect(model.examBoard?.acronym, 'BE');
    expect(model.career?.name, 'Administrativa');
    expect(model.registrationFee.min, 80);
    expect(model.officialUrl, 'https://example.gov.br');
  });
}
