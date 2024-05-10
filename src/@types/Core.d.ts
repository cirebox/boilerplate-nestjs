declare namespace Core {
  interface NestResponse {
    code?: number;
    headers?: object;
    message?: string;
    data?: any;
    service?: any;
    axios?: any;
  }

  interface NestResponseException {
    response: NestResponse;
  }

  interface ResponseData {
    code: number;
    message?: string;
    data?: any;
  }
}
