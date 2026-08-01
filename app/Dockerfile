FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="codyssey-workstation-web"
LABEL org.opencontainers.image.description="Static site for the Docker workstation lab"

COPY index.html /usr/share/nginx/html/index.html

HEALTHCHECK --interval=5s --timeout=2s --retries=5 \
  CMD wget -qO- http://127.0.0.1:80/ >/dev/null || exit 1
