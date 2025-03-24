FROM node:20

WORKDIR /home/app/boilerplate-nestjs
COPY package.json ./
RUN npm install
COPY . .
CMD npx prisma generate && npx prisma db push && npx prisma db seed && npm run start:dev 

