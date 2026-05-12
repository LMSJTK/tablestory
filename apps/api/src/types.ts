import { z } from 'zod';
import {
  GameEventEnvelope,
  RecapOutput,
  Uuid
} from '../../../schemas/contracts';

export const CreateSessionRequest = z.object({
  title: z.string().min(1),
  session_number: z.number().int().positive().optional(),
  scheduled_for: z.string().datetime({ offset: true }).optional()
});

export const RollDiceRequest = z.object({
  actor_participant_id: Uuid,
  expression: z.string().min(1),
  context: z.string().min(1),
  label: z.string().optional(),
  metadata: z.record(z.string(), z.unknown()).default({}),
  client_request_id: Uuid
});

export const GenerateRecapRequest = z.object({
  mode: z.enum(['standard', 'detailed']).default('standard'),
  prompt_version: z.string().default('recap-v1')
});

export const TimelineResponse = z.object({
  items: z.array(GameEventEnvelope),
  next_cursor: z.string().nullable()
});

export const RecapResponse = z.object({
  id: Uuid,
  session_id: Uuid,
  status: z.string(),
  short_recap_markdown: z.string().nullable(),
  long_recap_markdown: z.string().nullable(),
  source_coverage: z.record(z.string(), z.unknown()).nullable(),
  model_name: z.string().nullable(),
  prompt_version: z.string().nullable(),
  token_input: z.number().int().nullable(),
  token_output: z.number().int().nullable(),
  estimated_cost_usd: z.number().nullable(),
  completed_at: z.string().datetime({ offset: true }).nullable()
});

export type CreateSessionRequest = z.infer<typeof CreateSessionRequest>;
export type RollDiceRequest = z.infer<typeof RollDiceRequest>;
export type GenerateRecapRequest = z.infer<typeof GenerateRecapRequest>;
export type TimelineResponse = z.infer<typeof TimelineResponse>;
export type RecapResponse = z.infer<typeof RecapResponse>;
export type RecapOutput = z.infer<typeof RecapOutput>;
