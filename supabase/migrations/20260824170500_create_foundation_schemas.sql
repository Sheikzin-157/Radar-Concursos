create extension if not exists pg_trgm with schema extensions;
create extension if not exists vector with schema extensions;

create schema if not exists public_data;
create schema if not exists identity;
create schema if not exists documents;
create schema if not exists ai;
create schema if not exists notifications;
create schema if not exists audit;
create schema if not exists internal;

comment on schema public_data is 'Public competition catalog and published domain data.';
comment on schema identity is 'Application identity and personal user data.';
comment on schema documents is 'Sources, documents, versions and provenance.';
comment on schema ai is 'AI artifacts, changesets and embeddings.';
comment on schema notifications is 'Notification preferences, devices and delivery records.';
comment on schema audit is 'Append-oriented audit trail.';
comment on schema internal is 'Internal persistence primitives with no public API contract.';
