export const jwtConstants = {
  secret: `${process.env.JWT_SECRET_KEY}`,
  algorithm: 'HS256',
  expiresIn: '1h',
  issuer: 'my-app',
};
