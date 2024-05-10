import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  await prisma.exception.create({
    data: {
      statusCode: 500,
      message: 'Test exception message',
      path: 'v1/exception',
      stack: 'Test exception stack trace',
    },
  });

  await prisma.exception.create({
    data: {
      statusCode: 404,
      message: 'Test exception message 123',
      path: 'v1/exception',
      stack: 'Test exception stack trace',
    },
  });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
