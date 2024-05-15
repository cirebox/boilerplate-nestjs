declare namespace ApiTypes {
  interface Exception {
    id?: string;
    statusCode?: number;
    message?: string;
    path?: string;
    stack?: string;
    createdAt?: string;
  }
}
