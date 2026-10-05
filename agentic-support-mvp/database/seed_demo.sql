BEGIN;

INSERT INTO tenants (id, slug, display_name, public_key)
VALUES ('00000000-0000-0000-0000-000000000001', 'demo', 'Demo Product', 'pk_demo_public_widget')
ON CONFLICT DO NOTHING;

INSERT INTO tenant_domains (tenant_id, hostname)
VALUES ('00000000-0000-0000-0000-000000000001', 'localhost')
ON CONFLICT DO NOTHING;

INSERT INTO knowledge_sources (
  id, tenant_id, source_type, canonical_uri, title, owner, audience, status, effective_at
) VALUES (
  '00000000-0000-0000-0000-000000000010',
  '00000000-0000-0000-0000-000000000001',
  'manual',
  'demo://getting-started',
  'Getting Started',
  'Product Support',
  'public',
  'approved',
  now()
) ON CONFLICT DO NOTHING;

INSERT INTO knowledge_documents (
  id, tenant_id, source_id, version, title, body, body_sha256, status, approved_by, approved_at
) VALUES (
  '00000000-0000-0000-0000-000000000020',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000010',
  1,
  'Getting Started',
  'Create a tenant, approve a knowledge source, configure an allowed domain, and embed the widget.',
  encode(digest('Create a tenant, approve a knowledge source, configure an allowed domain, and embed the widget.', 'sha256'), 'hex'),
  'approved',
  'seed',
  now()
) ON CONFLICT DO NOTHING;

INSERT INTO knowledge_chunks (
  tenant_id, document_id, ordinal, content, token_count, metadata
) VALUES (
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000020',
  1,
  'To install the support widget: create a tenant, add an approved knowledge source, configure the allowed website domain, and add the module script and agentic-support element to the host page.',
  35,
  '{"section":"installation","audience":"public"}'::jsonb
) ON CONFLICT DO NOTHING;

COMMIT;
