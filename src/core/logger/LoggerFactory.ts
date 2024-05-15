import { transports, format } from 'winston';
import { WinstonModule } from 'nest-winston';

const LoggerFactory = () => {
  const consoleFormat = format.combine(format.timestamp(), format.json());

  const transportsList: (typeof transports.Stream)[] = [
    new transports.Console({ format: consoleFormat }),
  ];

  if (process.env.LOG_FILE === 'true') {
    transportsList.push(
      new transports.File({
        filename: `log/${new Date().toISOString().split('T')[0]}_info.log`,
      }),

      new transports.File({
        filename: `log/${new Date().toISOString().split('T')[0]}_debug.log`,
        level: 'debug',
      }),

      new transports.File({
        filename: `log/${new Date().toISOString().split('T')[0]}_error.log`,
        level: 'error',
      }),

      new transports.File({
        filename: `log/${new Date().toISOString().split('T')[0]}_fatal.log`,
        level: 'fatal',
      }),

      new transports.File({
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
