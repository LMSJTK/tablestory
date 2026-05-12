# API Vertical Slice (Scaffold)

This folder contains implementation scaffolding for the first MVP vertical slice:

- Create/start/end session
- Authoritative dice roll event persistence
- Session timeline query
- Recap job queue + recap read

## Files

- `types.ts`: zod DTOs for endpoint payloads and responses.
- `sql.ts`: parameterized SQL statements for handler/service integration.

## Intended next step

Wire these contracts and SQL queries into your chosen runtime (Fastify, Express, or Nest) and DB adapter (`pg`/Kysely/Prisma) with transaction and idempotency handling.
