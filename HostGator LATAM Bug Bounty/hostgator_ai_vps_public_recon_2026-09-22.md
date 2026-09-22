# HostGator LATAM Bug Bounty — Public AI Agent / AI-VPS Recon (2026-09-22)

Scope note: This is a public-only reconnaissance pass focused on the newly announced AI Agent / AI-driven VPS area. No exploitation, no login, no purchase flow, no destructive or state-changing actions, and no testing beyond public, unauthenticated behavior.

## 1) Public AI / VPS URLs observed

### AI bundle / homepage anchor
- https://www.hostgator.com.br/#ai-tools
  - Observed in homepage HTML as a public anchor link.
  - This appears to be a marketing section, not a direct AI console.

### VPS landing page
- https://www.hostgator.com.br/servidor-vps
  - Returned HTTP 200.
  - Public marketing page advertising VPS services with an AI/automation-oriented product grid.

### AI automation / agent VPS subpages
- https://www.hostgator.com.br/servidor-vps/openclaw
  - Returned HTTP 200.
  - Public page describes OpenClaw as an autonomous AI agent that executes tasks and evolves over time.
- https://www.hostgator.com.br/servidor-vps/hospedagem-n8n
  - Returned HTTP 200.
  - Public page promotes self-hosted n8n automation hosting, likely as part of AI workflow/automation infra.

### Other relevant public references found on the homepage
- HostGator AllPass includes AI models such as ChatGPT, Claude, Gemini, and Grok.
- The VPS landing page includes visible product cards such as Claude Code, OpenClaw, Hermes, and n8n.

## 2) Observed public behavior and product claims

### Observations
- The public site clearly positions AI as a product and hosting/automation bundle, not a user-facing chat interface.
- The site text explicitly describes OpenClaw as:
  - "agente de IA que atua de forma autônoma"
  - "executando tarefas e evoluindo com o uso ao longo do tempo"
  - "automação inteligente"
- The AI/VPS pages are publicly accessible and do not require authentication to load the landing HTML.
- The OpenClaw and n8n pages are presented as pre-installed / ready-to-use VPS offerings rather than interactive web apps.
- The homepage also advertises a bundle named HostGator AllPass that includes multiple AI models (ChatGPT, Claude, Gemini, Grok). This is an AI access bundle, not necessarily a host-managed agent UI.

### Hypotheses
- The public-facing AI functionality appears to be a marketing/upsell layer and a hosted-infrastructure product pitch, not a directly interactive backend agent surface accessible to unauthenticated users.
- The actual AI agent management or server-management workflows likely live behind authenticated customer or account flows after purchase or login.
- The OpenClaw / n8n offerings may be used as infrastructure for customer-side AI automation and not as a HostGator-controlled AI agent console accessible to the public.

## 3) Relevant endpoints and HTTP methods

### Public endpoints with observed HTTP status
- GET https://www.hostgator.com.br/  -> HTML page, public landing page
- GET https://www.hostgator.com.br/#ai-tools  -> anchor fragment on homepage
- GET https://www.hostgator.com.br/servidor-vps  -> HTTP 200
- GET https://www.hostgator.com.br/servidor-vps/hospedagem-n8n  -> HTTP 200
- GET https://www.hostgator.com.br/servidor-vps/openclaw  -> HTTP 200

### Method pattern
- Publicly observed method: GET only.
- No public API endpoints or authenticated JSON endpoints were discovered in the reviewed public HTML.
- No visible API actions such as POST /api/*, /graphql, /wp-json, or direct fetch() URLs were found in the reviewed public page source.
- No user-controlled query parameters or mutation-style payloads were observed in the public AI/VPS paths reviewed.

## 4) Important parameters and prompt-like user controls

### Observations
- No public AI prompt fields or chat inputs were discovered at the reviewed public routes.
- No user-controlled prompt parameter was visible in HTML/URL patterns for the public AI agent functions reviewed.
- No public API request payloads were found that expose a backend LLM job or agent task endpoint.

### Hypotheses
- If a prompt-driven AI agent exists, it is likely behind a customer-authenticated interface rather than in the public marketing pages.
- The public pages may only advertise the AI agent capability and not expose the actual runtime interface.

## 5) Authentication / authorization boundary

### Observations
- The reviewed AI/VPS routes load without authentication and present static public content.
- No clear auth boundary was exposed in the public HTML reviewed.
- No login form, session token flow, or authenticated API route was observable in the public source reviewed.

### Hypotheses
- The real AI workflow likely requires a signed-in customer or a purchased VPS subscription.
- The public portion appears to be a front-door marketing layer; the actual management/control plane likely sits behind authenticated portal flows or internal tooling.

## 6) VPS / server-management actions implied by the public AI workflow

### Observations from public text
- The pages describe server management benefits, such as:
  - root access
  - custom installation / configuration
  - dedicated CPU, memory, storage
  - 24/7 uptime / monitoring
  - firewall / security / SSL / DDoS protection
  - support for automation workflows and AI agents
- OpenClaw is described as a self-contained autonomous agent that can execute tasks and scale with usage.
- n8n is described as a workflow automation platform for AI-driven automation and integrations.

### What the public content implies
- The AI/VPS offering appears capable of:
  - running autonomous or semi-autonomous workflows
  - hosting custom AI assistants or automation agents
  - integrating with external tools and workflows
  - running server-side automation on dedicated resources
  - enabling customer-configured and self-hosted operations

### Important boundary
- Nothing in the public pages indicates that unauthenticated users can command or trigger the AI agent, or that the hosting platform itself exposes privileged server-management actions to the public.

## 7) Notable security boundaries to investigate next

These are the next likely investigation points, strictly beyond the public-only reconnaissance already performed:

1. Authenticated customer portal / purchase flow
   - Check whether the real AI agent/VPS console is accessible only after customer login or subscription activation.
2. VPS control plane
   - Determine whether the agent/VPS product exposes management endpoints for deployment, app install, service restarts, or environment changes behind auth.
3. API exposure for OpenClaw / n8n / automation services
   - Look for authenticated endpoints that could trigger automation execution or system actions.
4. Role separation between user account and VPS instance
   - Validate whether a customer can influence only their own instance or whether wider administrative scope is reachable.
5. Public vs. internal lead-generation boundary
   - Confirm whether the public pages are purely marketing and whether the actual workflow and server triggers are restricted to authenticated account owners.

## 8) Explicit non-findings / no exploitation performed

- No public AI chatbot or agent prompt interface was found.
- No direct user prompt parameter to a backend AI model endpoint was observed.
- No unauthenticated server-management action was triggered.
- No purchase, charge, or state-changing action was created.
- No Cloudflare/anti-bot or rate-limit bypass was attempted.
- No brute force, scanning, or high-volume probing was performed.
- No customer account data or real production data was accessed.

## 9) Summary

The public HostGator footprint shows a clear AI/VPS marketing layer, not a directly exploitable AI agent console. The concrete public routes with evidence are:
- https://www.hostgator.com.br/#ai-tools
- https://www.hostgator.com.br/servidor-vps
- https://www.hostgator.com.br/servidor-vps/openclaw
- https://www.hostgator.com.br/servidor-vps/hospedagem-n8n

The most likely next step, while staying strictly within scope, is to determine whether the actual AI agent and VPS control plane is only accessible after customer authentication or purchase, and whether those interfaces expose privileged workflow or server-management actions behind auth.
