import { Controller, Get, Query } from '@nestjs/common';
import { ListCompetitionsUseCase } from '../application/use-cases/list-competitions.use-case';
import { ListCompetitionsHttpQuery } from './list-competitions.query';

@Controller('competitions')
export class CompetitionsController {
  constructor(private readonly listCompetitions: ListCompetitionsUseCase) {}

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
}
