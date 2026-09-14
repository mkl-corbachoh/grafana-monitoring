# MKit Travel Monitoring

Stack de monitorizacion separado para `mkit-travel`. Grafana vive en el Compose base y los servicios de observabilidad se incorporan mediante un override especifico para desarrollo o produccion.

## Estructura Compose

- `docker-compose.yml`: base comun con Grafana, su almacenamiento y la red interna.
- `docker-compose.dev.yml`: añade Prometheus, Alertmanager, Blackbox Exporter, Loki, Alloy, node-exporter y cAdvisor; publica las interfaces de desarrollo solo en `127.0.0.1`.
- `docker-compose.prod.yml`: añade los mismos servicios, mantiene todas sus interfaces internas y publica exclusivamente Grafana mediante la red externa `traefik`.

No se debe arrancar un override de forma aislada: siempre se combina con el archivo base.

## Desarrollo

Levantar el stack completo:

```sh
docker compose -p mkit-monitoring-dev -f docker-compose.yml -f docker-compose.dev.yml up -d
```

Validar la configuracion resultante:

```sh
docker compose -p mkit-monitoring-dev -f docker-compose.yml -f docker-compose.dev.yml config
```

Interfaces locales:

- Grafana: `http://localhost:3000` (`admin` / `admin` por defecto).
- Prometheus: `http://localhost:9090`.
- Alertmanager: `http://localhost:9093`.
- Blackbox Exporter, Loki, Alloy, node-exporter y cAdvisor permanecen en la red Docker interna.

Los mounts de node-exporter, cAdvisor y Alloy estan orientados a un host Docker Linux. En Docker Desktop observan la VM Linux de Docker, no directamente el host Windows o macOS.

Detener el entorno y conservar sus datos:

```sh
docker compose -p mkit-monitoring-dev -f docker-compose.yml -f docker-compose.dev.yml down
```

## Produccion

1. Crear `.env` a partir de `.env.example` y sustituir todos los valores de ejemplo.
2. Confirmar que existe la red Docker externa `traefik`.
3. Levantar siempre el base junto al override de produccion.

```sh
docker compose -p mkit-monitoring -f docker-compose.yml -f docker-compose.prod.yml up -d
```

Grafana queda disponible en `https://${GRAFANA_DOMAIN}`. Prometheus, Alertmanager, Blackbox Exporter, Loki, Alloy, node-exporter y cAdvisor no publican puertos en el host.

Validar antes de desplegar:

```sh
docker compose --env-file .env -p mkit-monitoring -f docker-compose.yml -f docker-compose.prod.yml config --quiet
```

## Configuracion

- Grafana provisiona Prometheus, Loki y Alertmanager desde `config/grafana/provisioning`.
- Prometheus usa `config/prometheus` en produccion y `config/prometheus-dev` en desarrollo.
- Blackbox comprueba `https://api.mikorh.com/health` y `https://travel.mikorh.com` con HTTP 200, timeout de 5 segundos y IPv4.
- Alloy descubre contenedores mediante `/var/run/docker.sock`, etiqueta los logs con el entorno del override y los envia a Loki.
- Los dashboards provisionados viven en `config/grafana-dashboards`.

## Seguridad

- No commitear `.env`, passwords, tokens de Telegram, credenciales SMTP ni `INTERNAL_METRICS_TOKEN`.
- Produccion exige `GRAFANA_ADMIN_PASSWORD` y las credenciales de notificacion al resolver el Compose.
- No exponer Prometheus, Loki, cAdvisor, node-exporter ni Alertmanager publicamente.
