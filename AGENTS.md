# Agent Notes

## Repository State
- This repo is currently empty apart from this instruction file; do not assume app source, build scripts, tests, or CI exist here until added.
- No repo-local build, test, lint, deploy, or compose commands are verified yet.
- This repo is intended for a separate production monitoring stack for MKit Travel, not the MKit Travel app itself.

## Target App
- Monitor project `mkit-travel` in `production`.
- Public targets: API `https://api.mikorh.com`, API health `https://api.mikorh.com/health`, frontend `https://travel.mikorh.com`.
- App stack is Docker Compose behind an existing external Traefik network named `traefik`.
- Expected app containers: `mkit-travel-api-1`, `mkit-travel-frontend-1`, `mkit-travel-db-1`.
- App services are FastAPI API, Nginx-served React/Vite frontend, and PostgreSQL 16 Alpine DB.

## Monitoring Stack Direction
- Start with Docker Compose services: `grafana`, `prometheus`, `blackbox-exporter`, `node-exporter`, and `cadvisor`.
- Add logs with Loki plus Promtail or Grafana Alloy reading Docker logs.
- Optional later service: Alertmanager.
- Expose only Grafana publicly through Traefik, likely `grafana.mikorh.com`.
- Keep Prometheus, Loki, cAdvisor, node-exporter, and Alertmanager internal unless explicitly changed.

## Metrics And Checks
- Prefer blackbox checks and logs before scraping app internals.
- Blackbox targets are `https://api.mikorh.com/health` every 30s or 60s and `https://travel.mikorh.com` every 60s.
- Blackbox checks must cover HTTP 200, TLS validity, latency, availability, and TLS certificate expiration.
- Use a Blackbox `http_2xx` module with GET, timeout around 5s, valid status `[200]`, and `preferred_ip_protocol: ip4`.
- API `GET /internal/metrics` returns in-memory JSON, not Prometheus format; metrics reset on API restart.
- If `INTERNAL_METRICS_TOKEN` exists, `/internal/metrics` requires `X-Internal-Token: <token>`; do not put this token in public dashboards or committed files.

## Logs
- API logs are JSON on stdout/stderr with useful fields: `timestamp`, `level`, `message`, `correlation_id`, HTTP method, path, status, and duration.
- Loki ingestion should filter or label by Docker container and compose project; expected compose project is probably `mkit-travel`.

## Labels
- Use consistent labels: `project="mkit-travel"`, `environment="production"`, `service="api|frontend|db"`, `domain="api.mikorh.com|travel.mikorh.com"`.

## Initial Alerts
- API health down for more than 2 minutes.
- Frontend down for more than 2 minutes.
- TLS certificate expires in less than 14 days.
- Host disk over 80% warning and over 90% critical.
- API or DB container not running.
- Latest PostgreSQL backup older than 36h.
- Latest storage snapshot older than 36h.

## Backups
- Monitor backup freshness under `/backups/mkit-travel/postgres/*.dump` and `/backups/mkit-travel/storage/snapshots/*`.
- Implement backup age metrics with node-exporter textfile collector, a cron-generated `.prom` file, or a small exporter; no implementation exists yet.

## Dashboards
- Provision datasources internally as Prometheus `http://prometheus:9090` and Loki `http://loki:3100`.
- Useful starting dashboards: node-exporter host overview, cAdvisor Docker containers, Blackbox HTTP availability/latency/TLS, Loki logs by container.
- Add an MKit Travel dashboard with API/frontend up, blackbox latency, TLS days remaining, container CPU/RAM, DB CPU/RAM, disk usage, and backup age.

## Security Constraints
- Do not expose Prometheus, Loki, cAdvisor, node-exporter, or Alertmanager publicly by default.
- Protect Grafana with HTTPS via Traefik and a strong login; consider Traefik auth or IP allowlist if exposed.
- Do not commit secrets, Grafana admin passwords, Traefik credentials, or internal metrics tokens.

## Future App Improvements
- Add a native Prometheus endpoint such as `/internal/prometheus` or `/metrics` in the app repo, not here unless this repo later gains app code.
- Add histogram metrics for requests by route/method/status, request duration buckets, upload failures, and rate-limit hits.
- Add `postgres_exporter` once DB credentials and network access are deliberately configured.
- Add a textfile collector script for backup state.
