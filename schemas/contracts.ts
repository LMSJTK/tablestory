import { z } from 'zod';

export const Uuid = z.string().uuid();
export const IsoDateTime = z.string().datetime({ offset: true });

export const GameEventType = z.enum([
  'session.started',
  'session.ended',
  'chat.message.created',
  'dice.roll.requested',
  'dice.roll.resolved',
  'combat.turn.started',
  'combat.turn.ended',
  'narration.beat',
  'quest.updated'
]);

export const DiceRollPayload = z.object({
  expression: z.string().min(1),
  context: z.enum(['attack', 'damage', 'save', 'skill_check', 'initiative', 'custom']),
  roller_character_id: Uuid.optional(),
  modifier_total: z.number().int().default(0),
  rolls: z.array(z.number().int().min(1)),
  kept_rolls: z.array(z.number().int().min(1)).optional(),
  total: z.number().int(),
  critical: z.enum(['none', 'critical_success', 'critical_failure']).default('none')
});

export const GameEventEnvelope = z.object({
  id: Uuid,
  campaign_id: Uuid,
  session_id: Uuid,
  event_type: GameEventType,
  actor_participant_id: Uuid.nullable().optional(),
  schema_version: z.string().default('1.0.0'),
  ts: IsoDateTime,
  payload: z.record(z.string(), z.unknown())
});

export const TimelineEvent = z.object({
  summary: z.string().min(1),
  type: z.enum(['combat', 'social', 'exploration', 'travel', 'downtime']),
  importance: z.number().int().min(1).max(5),
  source_event_ids: z.array(Uuid).min(1),
  confidence: z.number().min(0).max(1)
});

export const ExtractedEntity = z.object({
  name: z.string().min(1),
  entity_type: z.enum(['npc', 'location', 'item', 'faction', 'quest']),
  attributes: z.record(z.string(), z.union([z.string(), z.number(), z.boolean()])).default({}),
  source_event_ids: z.array(Uuid).min(1),
  confidence: z.number().min(0).max(1)
});

export const QuestUpdate = z.object({
  quest_name: z.string(),
  status: z.enum(['new', 'advanced', 'blocked', 'completed', 'failed']),
  details: z.string(),
  source_event_ids: z.array(Uuid).min(1),
  confidence: z.number().min(0).max(1)
});

export const UnresolvedThread = z.object({
  thread: z.string().min(1),
  source_event_ids: z.array(Uuid).min(1),
  confidence: z.number().min(0).max(1)
});

export const ExtractionOutput = z.object({
  timeline_events: z.array(TimelineEvent),
  entities: z.array(ExtractedEntity),
  quest_updates: z.array(QuestUpdate),
  combat_outcomes: z.array(z.string()),
  unresolved_threads: z.array(UnresolvedThread)
});

export const SourceCoverage = z.object({
  covered_event_ids: z.array(Uuid),
  omitted_high_importance_event_ids: z.array(Uuid)
});

export const RecapOutput = z.object({
  short_recap_markdown: z.string().min(1),
  long_recap_markdown: z.string().min(1),
  last_time_on_bullets: z.array(z.string().min(1)),
  open_threads: z.array(z.string().min(1)),
  source_coverage: SourceCoverage
});

export type GameEventEnvelope = z.infer<typeof GameEventEnvelope>;
export type DiceRollPayload = z.infer<typeof DiceRollPayload>;
export type ExtractionOutput = z.infer<typeof ExtractionOutput>;
export type RecapOutput = z.infer<typeof RecapOutput>;
