# MKit Travel Monitoring

Stack de monitoring separado para `mkit-travel` en produccion. El repo no contiene codigo de la app; contiene Grafana, Prometheus, Blackbox Exporter, Loki, Grafana Alloy, node-exporter, cAdvisor y Alertmanager.

## Fases
- Fase 1: stack base Docker Compose con Grafana expuesto por Traefik, Prometheus interno, Blackbox, node-exporter, cAdvisor, Loki, Alloy y Alertmanager.
- Fase 2: dashboards iniciales para disponibilidad HTTP, TLS, host, Docker, contenedores de `mkit-travel` y logs por contenedor.
- Fase 3: alertas y notificaciones reales en Alertmanager; ahora existe un receiver `noop` hasta definir canal seguro.
- Fase 4: backup freshness con node-exporter textfile collector para `/backups/mkit-travel/postgres/*.dump` y `/backups/mkit-travel/storage/snapshots/*`.
- Fase 5: mejoras de app: endpoint Prometheus nativo, histogramas, `postgres_exporter` y healthcheck frontend mas explicito.

## Arranque Fase 1
- Copiar `.env.example` a `.env` y cambiar `GRAFANA_ADMIN_PASSWORD` antes de levantar el stack.
- Confirmar que la red externa Docker `traefik` ya existe en el servidor.
- Levantar con `docker compose up -d` desde este repo.
- Grafana se publica en `https://grafana.mikorh.com`; el resto de servicios queda solo en la red Docker interna.

## Desarrollo Local
- Usar `docker-compose.dev.yml` para trabajar en WSL/Windows sin Traefik, dominio publico ni labels de exposicion.
- El stack dev levanta solo `grafana`, `prometheus`, `blackbox-exporter` y `alertmanager`.
- Dev no levanta `node-exporter`, `cadvisor`, `loki` ni `alloy` porque dependen de mounts del host Linux real o del Docker socket y pueden dar lecturas confusas en WSL.
- Levantar con `docker compose -f docker-compose.dev.yml up -d`.
- Los puertos dev se publican solo en `127.0.0.1`, no en Traefik ni en interfaces publicas.
- Grafana local: `http://localhost:3000` con usuario `admin` y password `admin` si no defines otra en `.env`.
- Si el volumen `grafana-dev-data` ya existia, Grafana conserva el password admin inicial y no lo cambia al modificar `.env`.
- Prometheus local: `http://localhost:9090`.
- Alertmanager local: `http://localhost:9093`.
- Blackbox queda solo interno; Prometheus lo usa como `blackbox-exporter:9115`.

## Servicios
- `grafana`: interfaz principal para dashboards, exploracion de logs y alertas; en dev usa Prometheus y Alertmanager, en produccion tambien Loki.
- `prometheus`: recolecta metricas, evalua reglas de alerta y guarda series temporales.
- `blackbox-exporter`: ejecuta checks HTTP externos contra `https://api.mikorh.com/health` y `https://travel.mikorh.com` para disponibilidad, latencia y TLS.
- `alertmanager`: recibe alertas de Prometheus, agrupa/repite notificaciones y mas adelante enviara a email, Slack, Telegram u otro canal.
- `loki`: almacena logs indexados por labels para consultarlos desde Grafana.
- `alloy`: lee logs de Docker mediante `/var/run/docker.sock`, les aplica labels y los envia a Loki.
- `node-exporter`: expone metricas del host como CPU, RAM, filesystem y disco.
- `cadvisor`: expone metricas de contenedores Docker como CPU, memoria, red y estado visto por cgroups.

## Dashboards
- Los dashboards provisionados viven en `config/grafana-dashboards` y se cargan automaticamente en la carpeta Grafana `MKit Travel`.
- `MKit Travel - Blackbox` muestra disponibilidad API/frontend, status HTTP, latencia blackbox y dias restantes de TLS.

## Alertas
- Las reglas Prometheus estan en `config/prometheus/alerts.yml` para produccion y `config/prometheus-dev/alerts.yml` para dev.
- Alertmanager envia a Telegram y email SMTP mediante variables en `.env`; no commitear tokens reales.
- Para Telegram definir `ALERT_TELEGRAM_BOT_TOKEN` y `ALERT_TELEGRAM_CHAT_ID`.
- Para Resend SMTP usar `ALERT_SMTP_SMARTHOST=smtp.resend.com:587`, `ALERT_SMTP_USERNAME=resend` y `ALERT_SMTP_PASSWORD=<resend-api-key>`.
- Definir tambien `ALERT_EMAIL_FROM` con un remitente verificado en Resend y `ALERT_EMAIL_TO` con el destinatario operativo.
- `.env.example` contiene valores dummy solo para validar y arrancar en local.

## Targets Iniciales
- API health: `https://api.mikorh.com/health`.
- Frontend smoke check: `https://travel.mikorh.com`.
- Contenedores esperados: `mkit-travel-api-1`, `mkit-travel-frontend-1`, `mkit-travel-db-1`.

## Seguridad
- No exponer Prometheus, Loki, cAdvisor, node-exporter ni Alertmanager publicamente.
- No commitear `.env`, passwords, tokens de Traefik ni `INTERNAL_METRICS_TOKEN`.
- Preferir blackbox + logs antes de scrapear `/internal/metrics`, porque devuelve JSON en memoria y puede requerir token.
