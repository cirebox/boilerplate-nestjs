export interface IQueueProvider {
  createQueue(
    routeKey: string,
    pattern: string,
    value: any,
    priority: number,
  ): void;
}
