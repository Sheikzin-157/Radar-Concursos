import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import type { Response } from 'express';

@Catch()
export class ApiExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    const correlationId = response.locals.correlationId as string;

    const status = exception instanceof HttpException
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR;

    const payload = exception instanceof HttpException ? exception.getResponse() : null;
    const message = this.resolveMessage(payload, status);
    const code = this.resolveCode(payload, status);

    response.status(status).json({ code, message, correlationId });
  }

  private resolveMessage(payload: string | object | null, status: number): string {
    if (typeof payload === 'string') return payload;
    if (payload && 'message' in payload) {
      const message = (payload as { message?: unknown }).message;
      if (typeof message === 'string') return message;
    }
    return status === 500 ? 'Erro interno do servidor.' : 'A requisição não pôde ser processada.';
  }

  private resolveCode(payload: string | object | null, status: number): string {
    if (payload && typeof payload === 'object' && 'code' in payload) {
      const code = (payload as { code?: unknown }).code;
      if (typeof code === 'string') return code;
    }

    const byStatus: Record<number, string> = {
      400: 'VALIDATION_ERROR',
      401: 'AUTHENTICATION_REQUIRED',
      403: 'FORBIDDEN',
      404: 'RESOURCE_NOT_FOUND',
      409: 'STATE_CONFLICT',
      429: 'RATE_LIMIT_EXCEEDED',
      500: 'INTERNAL_ERROR',
    };
    return byStatus[status] ?? 'INTERNAL_ERROR';
  }
}
