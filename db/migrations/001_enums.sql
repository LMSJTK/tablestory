CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE member_role AS ENUM ('owner', 'gm', 'player', 'viewer');
CREATE TYPE session_status AS ENUM ('scheduled', 'active', 'completed', 'archived');
CREATE TYPE participant_kind AS ENUM ('human', 'ai');
CREATE TYPE message_kind AS ENUM ('chat', 'system', 'narration', 'ooc');
CREATE TYPE memory_item_type AS ENUM ('npc', 'location', 'quest', 'loot', 'relationship', 'fact');
CREATE TYPE memory_status AS ENUM ('proposed', 'confirmed', 'rejected', 'superseded');
CREATE TYPE job_status AS ENUM ('queued', 'running', 'completed', 'failed', 'dead_lettered');
