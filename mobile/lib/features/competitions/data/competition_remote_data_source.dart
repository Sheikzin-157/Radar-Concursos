import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../domain/competition.dart';
import 'competition_dto.dart';

class CompetitionRemoteDataSource {
  const CompetitionRemoteDataSource(this._client);
  final ApiClient _client;

  Future<List<CompetitionSummary>> list({
    int limit = 20,
    String? search,
    String? state,
    String? status,
    String? organizationId,
    String? examBoardId,
  }) async {
    final response = await _client.getMap(
      '/competitions',
      queryParameters: {
        'limit': limit,
        'search': ?search,
        'state': ?state,
        'status': ?status,
        'organizationId': ?organizationId,
        'examBoardId': ?examBoardId,
      },
    );
    final rawItems = response['items'];
    if (rawItems is! List) {
      throw const AppException(
        code: 'INVALID_RESPONSE',
        message: 'A lista de concursos recebida é inválida.',
      );
    }
    try {
      return rawItems
          .map(
            (item) => competitionSummaryFromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false);
    } on FormatException {
      throw const AppException(
        code: 'INVALID_RESPONSE',
        message: 'Os dados recebidos não puderam ser interpretados.',
      );
    } on TypeError {
      throw const AppException(
        code: 'INVALID_RESPONSE',
        message: 'Os dados recebidos não puderam ser interpretados.',
      );
    }
  }

  Future<CompetitionDetail> getById(String competitionId) async {
    final response = await _client.getMap('/competitions/$competitionId');
    return competitionDetailFromJson(response);
  }
}
