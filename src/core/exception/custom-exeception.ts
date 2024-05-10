export class CustomException extends Error {
  private response: Core.NestResponse;

  constructor(error: Core.NestResponseException) {
    super();
    this.response = error.response;
  }
}
