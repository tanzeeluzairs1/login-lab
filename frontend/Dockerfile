FROM node:24-bookworm-slim
WORKDIR /app

COPY package.json server.js ./
COPY public ./public

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

USER node

EXPOSE 3000
CMD ["node", "server.js"]   
