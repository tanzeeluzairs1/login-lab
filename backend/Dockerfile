FROM node:24-bookworm-slim
WORKDIR /app
COPY package*.json server.js ./

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=5000

USER node

EXPOSE 5000

CMD ["node", "server.js"]