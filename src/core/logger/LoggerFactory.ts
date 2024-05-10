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
        filename: `log/${new Date().toISOString().split('T')[0]}.log`,
      }),
    );
  }

  return WinstonModule.createLogger({
    level: 'info',
    transports: transportsList,
  });
};

export { LoggerFactory };
