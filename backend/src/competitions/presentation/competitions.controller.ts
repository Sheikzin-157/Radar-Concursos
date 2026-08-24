import { BadRequestException, Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { GetCompetitionUseCase } from '../application/use-cases/get-competition.use-case';
import { ListCompetitionsUseCase } from '../application/use-cases/list-competitions.use-case';
import { ListCompetitionsHttpQuery } from './list-competitions.query';

const competitionIdPipe = new ParseUUIDPipe({
  version: 'all',
  exceptionFactory: () => new BadRequestException({
    code: 'INVALID_UUID',
    message: 'Identificador inválido.',
  }),
});

@Controller('competitions')
export class CompetitionsController {
  constructor(
    private readonly listCompetitions: ListCompetitionsUseCase,
    private readonly getCompetition: GetCompetitionUseCase,
  ) {}

  @Get()
  async list(@Query() query: ListCompetitionsHttpQuery) {
    const items = await this.listCompetitions.execute(query);
    return {
      items,
      page: {
        nextCursor: null,
        hasMore: false,
      },
    };
  }

  @Get(':competitionId')
  getById(@Param('competitionId', competitionIdPipe) competitionId: string) {
    return this.getCompetition.execute(competitionId);
  }
}
