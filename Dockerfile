FROM n8nio/n8n:2.26.3

USER root

COPY --chown=node:node workflows/ /opt/assistant/workflows/
COPY --chown=node:node db/schema.sql /opt/assistant/db/01-schema.sql
COPY --chown=node:node scripts/bootstrap.sh /usr/local/bin/assistant-bootstrap

RUN chmod 755 /usr/local/bin/assistant-bootstrap

LABEL org.opencontainers.image.title="n8n Telegram AI Assistant" \
      org.opencontainers.image.description="n8n com workflows comunitarios e bootstrap automatico" \
      org.opencontainers.image.source="https://github.com/DienysonSouza/n8n-telegram-ai-assistant" \
      org.opencontainers.image.licenses="MIT"

USER node
