import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import {
  COMPETITION_REPOSITORY,
  CompetitionDetail,
  CompetitionRepository,
} from '../ports/competition.repository';

@Injectable()
export class GetCompetitionUseCase {
  constructor(
    @Inject(COMPETITION_REPOSITORY)
    private readonly competitions: CompetitionRepository,
  ) {}

  async execute(id: string): Promise<CompetitionDetail> {
    const competition = await this.competitions.findPublicById(id);

    if (!competition) {
      throw new NotFoundException({
        code: 'COMPETITION_NOT_FOUND',
        message: 'Concurso não encontrado.',
      });
    }

    return competition;
  }
}
