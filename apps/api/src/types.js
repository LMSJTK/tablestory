import { z } from 'zod';

const Uuid = z.string().uuid();
const DateTime = z.string().datetime({ offset: true });

export const CreateSessionRequest = z.object({
  title: z.string().min(1),
  session_number: z.number().int().positive().optional(),
  scheduled_for: DateTime.optional()
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
