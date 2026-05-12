import Fastify from 'fastify';
import { pool, withTransaction } from './db.js';
import { sql } from './sql.js';
import { CreateSessionRequest, GenerateRecapRequest, RollDiceRequest } from './types.js';
import crypto from 'crypto';

const app = Fastify({ logger: true });

function parseBody(schema, body) {
  const result = schema.safeParse(body);
  if (!result.success) return { error: result.error.flatten() };
  return { data: result.data };
}

async function getSessionOr404(sessionId, reply) {
  const session = await pool.query(sql.getSessionStatus, [sessionId]);
  if (!session.rows[0]) {
    reply.code(404).send({ error: 'not_found' });
    return null;
  }
  return session.rows[0];
}

app.post('/api/v1/campaigns/:campaignId/sessions', async (req, reply) => {
  const parsed = parseBody(CreateSessionRequest, req.body);
  if (parsed.error) return reply.code(400).send({ error: 'validation_error', details: parsed.error });

  const createdBy = req.headers['x-user-id'];
  if (!createdBy) return reply.code(401).send({ error: 'unauthorized' });

  const { rows } = await pool.query(sql.createSession, [
    req.params.campaignId,
    parsed.data.title,
    parsed.data.session_number ?? null,
    parsed.data.scheduled_for ?? null,
    createdBy
  ]);

  return reply.code(201).send(rows[0]);
});

app.post('/api/v1/sessions/:sessionId/start', async (req, reply) => {
  const existing = await getSessionOr404(req.params.sessionId, reply);
  if (!existing) return;
  if (existing.status !== 'scheduled') {
    return reply.code(409).send({ error: 'invalid_state_transition', message: `Cannot start session from status ${existing.status}` });
  }

  const { rows } = await pool.query(sql.startSession, [req.params.sessionId]);
  return rows[0];
});

app.post('/api/v1/sessions/:sessionId/end', async (req, reply) => {
  const existing = await getSessionOr404(req.params.sessionId, reply);
  if (!existing) return;
  if (existing.status !== 'active') {
    return reply.code(409).send({ error: 'invalid_state_transition', message: `Cannot end session from status ${existing.status}` });
  }

  const { rows } = await pool.query(sql.endSession, [req.params.sessionId]);
  return rows[0];
});

app.get('/api/v1/sessions/:sessionId/timeline', async (req) => {
  const limit = Math.min(Number(req.query.limit ?? 100), 250);
  const { rows } = await pool.query(sql.getSessionTimeline, [req.params.sessionId, limit]);
  return {
    items: rows.map((r) => ({
      id: r.id,
      campaign_id: r.campaign_id,
      session_id: r.session_id,
      event_type: r.event_type,
      actor_participant_id: r.actor_participant_id,
      schema_version: r.schema_version,
      ts: r.ts,
      payload: r.payload_json
    })),
    next_cursor: null
  };
});

app.post('/api/v1/sessions/:sessionId/rolls', async (req, reply) => {
  const parsed = parseBody(RollDiceRequest, req.body);
  if (parsed.error) return reply.code(400).send({ error: 'validation_error', details: parsed.error });

  const existing = await getSessionOr404(req.params.sessionId, reply);
  if (!existing) return;
  if (existing.status !== 'active') {
    return reply.code(409).send({ error: 'invalid_state_transition', message: 'Rolls are only allowed during active sessions' });
  }

  const expressionMatch = parsed.data.expression.match(/^(\d+)d(\d+)([+-]\d+)?$/);
  if (!expressionMatch) return reply.code(400).send({ error: 'validation_error', message: 'Unsupported dice syntax' });

  const count = Number(expressionMatch[1]);
  const sides = Number(expressionMatch[2]);
  const mod = Number(expressionMatch[3] ?? 0);
  if (count > 20 || sides > 1000) return reply.code(400).send({ error: 'validation_error', message: 'Dice expression exceeds limits' });

  const idempotent = await pool.query(sql.findIdempotentResponse, [req.params.sessionId, 'rolls', parsed.data.client_request_id]);
  if (idempotent.rows[0]) {
    return reply.code(200).send(idempotent.rows[0].response_json);
  }

  const rolls = Array.from({ length: count }, () => 1 + crypto.randomInt(sides));
  const total = rolls.reduce((a, b) => a + b, 0) + mod;

  const payload = {
    expression: parsed.data.expression,
    context: parsed.data.context,
    rolls,
    modifier_total: mod,
    total,
    critical: 'none'
  };

  const response = await withTransaction(async (client) => {
    const { rows } = await client.query(sql.insertGameEvent, [
      existing.campaign_id,
      req.params.sessionId,
      'dice.roll.resolved',
      parsed.data.actor_participant_id,
      JSON.stringify(payload)
    ]);

    const result = {
      request_event_id: null,
      resolved_event: {
        ...rows[0],
        payload: rows[0].payload_json
      }
    };

    await client.query(sql.saveIdempotentResponse, [
      req.params.sessionId,
      parsed.data.client_request_id,
      'rolls',
      JSON.stringify(result)
    ]);

    return result;
  });

  return reply.code(201).send(response);
});

app.post('/api/v1/sessions/:sessionId/recap:generate', async (req, reply) => {
  const parsed = parseBody(GenerateRecapRequest, req.body ?? {});
  if (parsed.error) return reply.code(400).send({ error: 'validation_error', details: parsed.error });

  const session = await getSessionOr404(req.params.sessionId, reply);
  if (!session) return;
  if (session.status !== 'completed') {
    return reply.code(409).send({ error: 'invalid_state_transition', message: 'Recaps can only be generated for completed sessions' });
  }

  const { rows } = await pool.query(sql.queueRecapJob, [
    session.campaign_id,
    req.params.sessionId,
    JSON.stringify(parsed.data),
    parsed.data.prompt_version
  ]);

  return reply.code(202).send({ job_id: rows[0].id, status: rows[0].status });
});

app.get('/api/v1/sessions/:sessionId/recap', async (req, reply) => {
  const { rows } = await pool.query(sql.getLatestRecap, [req.params.sessionId]);
  if (!rows[0]) return reply.code(404).send({ error: 'not_found' });
  return { ...rows[0], source_coverage: rows[0].source_coverage_json };
});

app.listen({ port: Number(process.env.PORT ?? 3000), host: '0.0.0.0' });
