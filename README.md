# Tablestory MVP (Docker Quickstart)

Yes — you can use Docker to run the environment end-to-end.

## Prerequisites
- Docker + Docker Compose

## Start everything
```bash
docker compose up --build
```

This starts:
- Postgres (`db`)
- Migration job (`migrate`)
- Seed job (`seed`)
- API (`api`) on `http://localhost:3000`
- Recap worker (`worker`)

## Smoke test
```bash
curl http://localhost:3000/api/v1/sessions/bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb/timeline
```

## Notes
- Demo seed includes session id `bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb`.
- To reset state: `docker compose down -v`.
