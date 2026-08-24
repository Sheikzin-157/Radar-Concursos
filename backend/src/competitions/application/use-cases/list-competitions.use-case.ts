import { Inject, Injectable } from '@nestjs/common';
import {
  COMPETITION_REPOSITORY,
  CompetitionRepository,
  CompetitionSummary,
  ListCompetitionsQuery,
} from '../ports/competition.repository';

@Injectable()
export class ListCompetitionsUseCase {
  constructor(
    @Inject(COMPETITION_REPOSITORY)
    private readonly repository: CompetitionRepository,
  ) {}

  async execute(query: ListCompetitionsQuery): Promise<CompetitionSummary[]> {
    return this.repository.listPublic(query);
  }
}
