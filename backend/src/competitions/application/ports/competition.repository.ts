export interface OrganizationSummary {
  id: string;
  officialName: string;
  acronym: string | null;
  governmentSphere: string | null;
  state: string | null;
}

export interface ExamBoardSummary {
  id: string;
  officialName: string;
  acronym: string | null;
}

export interface MoneyRange {
  min: number | null;
  max: number | null;
  currency: 'BRL';
}

export interface CompetitionSummary {
  id: string;
  title: string;
  organization: OrganizationSummary;
  examBoard: ExamBoardSummary | null;
  currentStatus: string;
  totalVacancies: number | null;
  reserveRegistration: boolean | null;
  salary: MoneyRange;
  lastOfficialUpdateAt: string | null;
  lastValidatedAt: string | null;
}

export interface CompetitionDetail extends CompetitionSummary {
  competitionType: string | null;
  governmentSphere: string | null;
  summary: string | null;
  career: { id: string; name: string } | null;
  registrationFee: MoneyRange;
  officialUrl: string | null;
}

export interface ListCompetitionsQuery {
  organizationId?: string;
  examBoardId?: string;
  status?: string;
  state?: string;
  limit: number;
}

export interface CompetitionRepository {
  listPublic(query: ListCompetitionsQuery): Promise<CompetitionSummary[]>;
  findPublicById(id: string): Promise<CompetitionDetail | null>;
}

export const COMPETITION_REPOSITORY = Symbol('COMPETITION_REPOSITORY');
