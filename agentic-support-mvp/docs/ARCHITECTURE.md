# Architecture

## Request flow

```text
Embeddable Widget / App / Help Desk
                 |
          Channel Gateway
                 |
        Identity and Consent
                 |
          Input Policy Gate
                 |
        Intent and Risk Router
          /              \
 Tone Controller     Knowledge Runtime
          \              /
          Support Specialist
                 |
          Answer or Tool Proposal
                 |
          Tool Gateway / MCP Adapters
          /                     \
 Read-only execution      Approval-required action
          \                     /
          Answer Validator / Handoff
                 |
             Customer
                 |
       Trace, Audit and Evaluations
```

## Authoritative ownership

- Identity service owns authenticated users and sessions.
- Tenant config owns channel, theme, domains and retention settings.
- Knowledge service owns source approval, versions, chunks and citations.
- Conversation service owns transcript and support state.
- Tool gateway owns tool registration, risk tier, schemas and invocation policy.
- Approval service owns consequential-action decisions.
- Product systems own account, billing, ticket and product states.
- Audit service owns append-only consequential records.

## Communication adaptation

The tone controller may adapt directness, brevity, formality, technical depth, vocabulary and pacing. It must not imitate threats, intensify aggression, claim human emotion, manipulate the customer, or override policy.

## Knowledge rules

- Only approved and effective source versions are retrievable.
- Retrieval applies tenant and audience filters before semantic ranking.
- Every answer contains source references or explicitly states insufficient evidence.
- Customer messages do not automatically become approved knowledge.
- Superseded and expired content is excluded from new answers.

## Action rules

- The widget never calls privileged tools directly.
- Every tool has a JSON schema, risk tier, required scopes and timeout.
- Write tools require idempotency keys.
- Sensitive tools require a server-created approval record.
- Agent output is a proposal, not authorization.
- Execution occurs only through authoritative APIs.

## Suggested deployment

```text
CDN
  -> Widget JavaScript
  -> Support API
       -> PostgreSQL
       -> Object storage
       -> Retrieval worker
       -> Model provider adapter
       -> Tool gateway
       -> Help-desk connector
       -> OpenTelemetry collector
```
