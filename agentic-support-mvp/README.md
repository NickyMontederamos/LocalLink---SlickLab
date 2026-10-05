# Agentic Support MVP

Standalone, product-aware support architecture with an embeddable Web Component, PostgreSQL schema, OpenAPI contract, security boundaries, and phased delivery roadmap.

## What is included

- `docs/MVP_ROADMAP.md` - staged implementation and release gates
- `docs/ARCHITECTURE.md` - component and data-flow design
- `docs/EVALUATION_PLAN.md` - positive, negative, adversarial, permission, privacy and failure tests
- `database/schema.sql` - PostgreSQL 16+ schema
- `database/seed_demo.sql` - safe demo tenant, knowledge source and article
- `api/openapi.yaml` - OpenAPI 3.1 API contract
- `widget/src/agentic-support-widget.js` - framework-independent Web Component
- `widget/src/agentic-support-widget.css` - reference theme variables
- `widget/demo/index.html` - offline mock demo
- `widget/embed-example.html` - production integration example
- `tests/widget-smoke.mjs` - static widget contract checks

## MVP boundary

Version 0.1 is read-only product support with citations and human handoff. It does not autonomously refund, cancel, delete, alter security settings, or access unrestricted customer data.

## Run the widget demo

Open `widget/demo/index.html` directly in Edge, Chrome, Firefox, or Safari.

## Production embed

```html
<script type="module" src="https://cdn.example.com/agentic-support-widget.js"></script>

<agentic-support
  tenant="YOUR_PUBLIC_TENANT_KEY"
  api-base="https://support-api.example.com/v1"
  title="Product Support"
  position="right"
  theme="dark">
</agentic-support>
```

Never place API secrets in widget attributes. The public tenant key identifies configuration but does not grant privileged access.

## Validation performed

- JavaScript syntax check
- JSON parsing checks
- Static contract assertions
- SQL structure checks
- ZIP integrity check

This package is an implementation baseline, not a production security certification.
