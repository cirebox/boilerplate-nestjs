# NestJS boilerplate

[![image](https://github.com/brocoders/nestjs-boilerplate/assets/72293912/197da43e-02f4-4895-8d3e-b7a42a591c26)](https://github.com/new?template_name=boilerplate-nestjs&template_owner=cirebox)

## Description
NestJS boilerplate for a typical project
## Features
- [x] Prisma Database ORM.
- [x] Seeding
- [x] GRPC.
- [x] RabbitMQ.
- [ ] Social sign in (Apple, Facebook, Google, Twitter).
- [ ] I18N ([nestjs-i18n](https://www.npmjs.com/package/nestjs-i18n)).
- [ ] Mailing ([nodemailer](https://www.npmjs.com/package/nodemailer)).
- [ ] File uploads. Support local and Amazon S3 drivers.
- [x] TypeDocs
- [x] Swagger
- [x] Units tests.
- [ ] E2E tests 
- [ ] Docker.
- [x] Husky.
- [x] CI (Github Actions).

## Quick run

```bash
git clone --depth 1 https://github.com/cirebox/boilerplate-nestjs.git
cd boilerplate-nestjs
cp .env.example .env
docker-compose up -d
```

For check status run

```bash
docker-compose logs
```

## [Architecture](/doc/architecture.md)


## Installation
```bash
$ pnpm install
```

### About the [database](/doc/db.md)

## Running

```bash
# development
$ pnpm run start

# watch mode
$ pnpm run start:dev

# production mode
$ pnpm run start:prod
```

## Test

```bash
# unit tests
$ pnpm run test

# unit watch
$ pnpm run test:watch

# e2e tests
$ pnpm run test:e2e

# test coverage
$ pnpm run test:cov
```

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%">
        <a href="https://github.com/Shchepotin">
            <img src="https://avatars.githubusercontent.com/u/9134065?v=4?s=100" width="100px;" alt="Vladyslav Shchepotin"/>
            <br />
            <sub>
                <b>Eric Pereira</b>
            </sub>
        </a><br />
        <a href="#maintenance-Shchepotin" title="Maintenance">🚧</a> 
        <a href="#doc-Shchepotin" title="Documentation">📖</a> 
        <a href="#code-Shchepotin" title="Code">💻</a>
        <a href="#business-sars" title="Business development">💼</a>
      </td>      
    </tr>
  </tbody>
</table>
<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->
<!-- ALL-CONTRIBUTORS-LIST:END -->

## Support
If you seek consulting, support, or wish to collaborate, please contact us via [suportecire@gmail.com](mailto:suportecire@gmail.com). For any inquiries regarding boilerplates, feel free to ask on [GitHub Discussions](https://github.com/cirebox/boilerplate-nestjs/discussions).

Author - [Eric Pereira](https://portfolio-eric-pereira.vercel.app/)

 
<p><a href="https://www.buymeacoffee.com/ericpereiri"> <img align="left" src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" height="50" width="210" alt="wetty1" /></a></p><br><br>