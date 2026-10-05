# Agentic Support MVP Roadmap

## Product objective

Deliver a reusable support agent that can be embedded into websites and applications, answer product questions from approved knowledge, adapt communication style, cite evidence, create a human handoff, and expose traceable quality signals.

## Phase 0 - Discovery and contract freeze (Week 1)

### Deliverables

- Select one initial product and one support audience.
- Collect approved public documentation, release notes, setup guides and policies.
- Identify 50 highest-frequency questions and 20 known failure paths.
- Define escalation destinations, support hours and ownership.
- Classify tools into read-only, controlled write and approval-required.
- Freeze public widget configuration, API envelopes and answer schema.

### Exit gate

- Every source has owner, audience, effective date and approval state.
- Unsupported topics and escalation rules are documented.
- No confidential content is included in the public corpus.

## Phase 1 - Read-only support core (Weeks 2-3)

### Build

- Tenant and channel configuration.
- Conversation and message persistence.
- Approved knowledge ingestion.
- Hybrid retrieval interface and citations.
- Intent/risk router.
- Product knowledge specialist.
- Answer validator.
- Human handoff request.
- Embeddable Web Component.
- Basic operations/audit events.

### Exit gate

- 100-question evaluation dataset created.
- Citation correctness >= agreed pilot threshold.
- Unsupported questions do not fabricate answers.
- Keyboard, focus, screen-reader status and reduced motion pass.

## Phase 2 - Authenticated support context (Weeks 4-5)

### Build

- Signed session exchange.
- User and account scope resolution.
- Private knowledge audiences.
- Read-only account summary and ticket-status tools.
- Consent records and retention controls.
- Cross-tenant authorization tests.

### Exit gate

- Anonymous users cannot access account context.
- Account data is fetched only through scoped server tools.
- Tenant isolation suite passes.

## Phase 3 - Controlled support actions (Weeks 6-7)

### Build

- Create-ticket and add-comment commands.
- Callback requests.
- Contact preference updates.
- Tool registry and risk tiers.
- Idempotency and expected-version enforcement.
- Human approval queue.
- Action receipt surfaced in chat.

### Exit gate

- Duplicate requests cannot duplicate side effects.
- Sensitive actions pause for authorized approval.
- All proposals, decisions and executions are auditable.

## Phase 4 - Operations console and hardening (Weeks 8-9)

### Build

- Knowledge review and publication.
- Conversation search with privacy controls.
- Live handoff queue.
- Tool registry and kill switch.
- Trace explorer and support analytics.
- Knowledge rollback.
- Incident runbook.

### Exit gate

- Prompt-injection and malicious-document tests pass.
- Sensitive payloads are excluded from telemetry by default.
- Knowledge and tool rollback drills succeed.

## Phase 5 - Controlled beta (Weeks 10-11)

### Rollout

- One product, one channel, invited users only.
- Observe unanswered questions and retrieval failures.
- Review every low-confidence response.
- Compare support deflection with customer resolution and escalation quality.
- Do not optimize only for fewer tickets.

### Decision metrics

- Grounded answer rate.
- Citation correctness.
- First-contact resolution.
- Time to useful answer.
- Escalation appropriateness.
- Repeat contact for the same issue.
- Customer feedback.
- Human-agent acceptance of handoff summaries.
- Cost and latency per resolved conversation.

## Phase 6 - Omnichannel and specialist expansion (post-beta)

Add help-desk, in-app, collaboration and email adapters only after the core API is stable. Add troubleshooting, account and operations specialists only when evaluation data shows a measurable need.

## Non-goals for MVP

- Autonomous refunds, cancellations or account deletion.
- Arbitrary MCP discovery.
- Unreviewed learning from customer transcripts.
- Cross-customer memory.
- Emotional profiling.
- Voice calling.
- Browser control against customer accounts.
- Fine-tuning on raw production conversations.

## Recommended release tags

- `agentic-support-v0.1.0-readonly`
- `agentic-support-v0.2.0-authenticated-context`
- `agentic-support-v0.3.0-controlled-actions`
- `agentic-support-v0.4.0-closed-beta`
