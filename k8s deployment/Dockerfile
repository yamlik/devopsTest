FROM node:12-alpine
WORKDIR /app
COPY package.json ./
COPY node_modules ./
RUN npm i
COPY index.js index.js
CMD ["npm", "start"]