// src/tracing.ts
import * as process from 'process';
import * as opentelemetry from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import * as api from '@opentelemetry/api';

// Configuração simplificada do OpenTelemetry
const sdk = new opentelemetry.NodeSDK({
  // O recurso com os metadados será configurado via variáveis de ambiente
  // SERVICE_NAME e DEPLOYMENT_ENVIRONMENT
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://jaeger:4318/v1/traces',
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false },
      '@opentelemetry/instrumentation-express': { enabled: true },
      '@opentelemetry/instrumentation-http': { enabled: true },
      '@opentelemetry/instrumentation-nestjs-core': { enabled: true },
    }),
  ],
});

// Inicialização simplificada
process.env.OTEL_SERVICE_NAME = process.env.OTEL_SERVICE_NAME || 'nest-microservice';

// Inicializa o SDK
try {
  sdk.start();
  console.log('🔍 OpenTelemetry inicializado com sucesso');
} catch (error) {
  console.error('❌ Erro ao inicializar OpenTelemetry:', error);
}

// Encerramento adequado
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('🔍 OpenTelemetry encerrado com sucesso'))
    .catch((error) => console.log('❌ Erro ao encerrar OpenTelemetry', error))
    .finally(() => process.exit(0));
});

// Exporta o tracer e o SDK para uso em outros módulos
export const tracer = api.trace.getTracer('nest-microservice');
export { sdk as openTelemetrySDK };