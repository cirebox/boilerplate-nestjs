import * as winston from 'winston';
import { WinstonModule } from 'nest-winston';
import 'winston-logstash';

const LoggerFactory = () => {
  const consoleFormat = winston.format.combine(
    winston.format.timestamp(),
    winston.format.json(),
  );

  const transportsList: (typeof winston.transports.Stream)[] = [
    new winston.transports.Console({ format: consoleFormat }),
  ];

  if (process.env.LOG_FILE === 'true') {
    transportsList.push(
      new winston.transports.File({
        filename: `log/${new Date().toISOString().split('T')[0]}_info.log`,
      }),

      new winston.transports.File({
        filename: `log/${new Date().toISOString().split('T')[0]}_debug.log`,
        level: 'debug',
      }),

      new winston.transports.File({
        filename: `log/${new Date().toISOString().split('T')[0]}_error.log`,
        level: 'error',
      }),

      new winston.transports.File({
        filename: `log/${new Date().toISOString().split('T')[0]}_fatal.log`,
        level: 'fatal',
      }),

      new winston.transports.File({
        filename: `log/${new Date().toISOString().split('T')[0]}_warn.log`,
        level: 'warn',
      }),
    );
  }

  return WinstonModule.createLogger({
    level: 'info',
    transports: transportsList,
  });
};

export { LoggerFactory };
