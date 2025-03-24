import { ApiProperty, ApiPropertyOptions } from '@nestjs/swagger';
import {
  IsString,
  IsNumber,
  IsEmail,
  IsUUID,
  IsOptional,
  MinLength,
  MaxLength,
  Min,
  Max,
  Matches,
  IsEnum,
  registerDecorator,
  ValidationOptions,
  ValidationArguments,
} from 'class-validator';
import { Type } from 'class-transformer';

/**
 * Decorator para campos obrigatórios tipo string com validações e documentação Swagger
 */
export function RequiredString(
  options: ApiPropertyOptions & {
    minLength?: number;
    maxLength?: number;
    pattern?: RegExp;
    message?: string;
  } = {},
) {
  const { minLength, maxLength, pattern, message, ...apiOptions } = options;

  return function (target: any, propertyKey: string) {
    // Swagger documentation
    ApiProperty({
      ...apiOptions,
    })(target, propertyKey);

    // Validations
    IsString({ message: message || 'Este campo deve ser uma string' })(
      target,
      propertyKey,
    );

    if (minLength !== undefined) {
      MinLength(minLength, {
        message: `Este campo deve ter no mínimo ${minLength} caracteres`,
      })(target, propertyKey);
    }

    if (maxLength !== undefined) {
      MaxLength(maxLength, {
        message: `Este campo deve ter no máximo ${maxLength} caracteres`,
      })(target, propertyKey);
    }

    if (pattern) {
      Matches(pattern, {
        message: message || 'Este campo possui um formato inválido',
      })(target, propertyKey);
    }
  };
}

/**
 * Decorator para campos opcionais tipo string com validações e documentação Swagger
 */
export function OptionalString(
  options: ApiPropertyOptions & {
    minLength?: number;
    maxLength?: number;
    pattern?: RegExp;
    message?: string;
  } = {},
) {
  const { minLength, maxLength, pattern, message, ...apiOptions } = options;

  return function (target: any, propertyKey: string) {
    // Swagger documentation
    ApiProperty({
      ...apiOptions,
    })(target, propertyKey);

    // Validations
    IsOptional()(target, propertyKey);
    IsString({ message: message || 'Este campo deve ser uma string' })(
      target,
      propertyKey,
    );

    if (minLength !== undefined) {
      MinLength(minLength, {
        message: `Este campo deve ter no mínimo ${minLength} caracteres`,
      })(target, propertyKey);
    }

    if (maxLength !== undefined) {
      MaxLength(maxLength, {
        message: `Este campo deve ter no máximo ${maxLength} caracteres`,
      })(target, propertyKey);
    }

    if (pattern) {
      Matches(pattern, {
        message: message || 'Este campo possui um formato inválido',
      })(target, propertyKey);
    }
  };
}

/**
 * Decorator para campos obrigatórios tipo number com validações e documentação Swagger
 */
export function RequiredNumber(
  options: ApiPropertyOptions & {
    min?: number;
    max?: number;
    message?: string;
  } = {},
) {
  const { min, max, message, ...apiOptions } = options;

  return function (target: any, propertyKey: string) {
    // Swagger documentation
    ApiProperty({
      ...apiOptions,
    })(target, propertyKey);

    // Validations
    Type(() => Number)(target, propertyKey);
    IsNumber({}, { message: message || 'Este campo deve ser um número' })(
      target,
      propertyKey,
    );

    if (min !== undefined) {
      Min(min, {
        message: `Este campo deve ser maior ou igual a ${min}`,
      })(target, propertyKey);
    }

    if (max !== undefined) {
      Max(max, {
        message: `Este campo deve ser menor ou igual a ${max}`,
      })(target, propertyKey);
    }
  };
}

/**
 * Decorator para campos opcionais tipo number com validações e documentação Swagger
 */
export function OptionalNumber(
  options: ApiPropertyOptions & {
    min?: number;
    max?: number;
    message?: string;
  } = {},
) {
  const { min, max, message, ...apiOptions } = options;

  return function (target: any, propertyKey: string) {
    // Swagger documentation
    ApiProperty({
      ...apiOptions,
    })(target, propertyKey);

    // Validations
    IsOptional()(target, propertyKey);
    Type(() => Number)(target, propertyKey);
    IsNumber({}, { message: message || 'Este campo deve ser um número' })(
      target,
      propertyKey,
    );

    if (min !== undefined) {
      Min(min, {
        message: `Este campo deve ser maior ou igual a ${min}`,
      })(target, propertyKey);
    }

    if (max !== undefined) {
      Max(max, {
        message: `Este campo deve ser menor ou igual a ${max}`,
      })(target, propertyKey);
    }
  };
}

/**
 * Decorator para campos obrigatórios tipo email com validações e documentação Swagger
 */
export function RequiredEmail(
  options: ApiPropertyOptions & {
    message?: string;
  } = {},
) {
  const { message, ...apiOptions } = options;

  return function (target: any, propertyKey: string) {
    // Swagger documentation
    ApiProperty({
      format: 'email',
      ...apiOptions,
    })(target, propertyKey);

    // Validations
    IsString({ message: 'Este campo deve ser uma string' })(
      target,
      propertyKey,
    );
    IsEmail({}, { message: message || 'Este campo deve ser um email válido' })(
      target,
      propertyKey,
    );
  };
}

/**
 * Decorator para campos obrigatórios tipo UUID com validações e documentação Swagger
 */
export function RequiredUUID(
  options: ApiPropertyOptions & {
    message?: string;
    version?: '3' | '4' | '5' | 'all';
  } = {},
) {
  const { message, version = '4', ...apiOptions } = options;

  return function (target: any, propertyKey: string) {
    // Swagger documentation
    ApiProperty({
      format: 'uuid',
      ...apiOptions,
    })(target, propertyKey);

    // Validations
    IsUUID(version, {
      message: message || 'Este campo deve ser um UUID válido',
    })(target, propertyKey);
  };
}

/**
 * Decorator para campos obrigatórios tipo enum com validações e documentação Swagger
 */
export function RequiredEnum(
  enumType: any,
  options: ApiPropertyOptions & {
    message?: string;
  } = {},
) {
  const { message, ...apiOptions } = options;

  return function (target: any, propertyKey: string) {
    const enumValues = Object.values(enumType).filter(
      (item) => typeof item === 'string' || typeof item === 'number',
    );

    // Swagger documentation
    ApiProperty({
      enum: enumValues,
      ...apiOptions,
    })(target, propertyKey);

    // Validations
    IsEnum(enumType, {
      message:
        message ||
        `Este campo deve ser um dos valores: ${enumValues.join(', ')}`,
    })(target, propertyKey);
  };
}

/**
 * Decorator para validar se um valor é diferente de outro campo
 */
export function IsDifferentFrom(
  property: string,
  validationOptions?: ValidationOptions,
) {
  return function (target: any, propertyKey: string) {
    registerDecorator({
      name: 'isDifferentFrom',
      target: target.constructor,
      propertyName: propertyKey,
      constraints: [property],
      options: validationOptions,
      validator: {
        validate(value: any, args: ValidationArguments) {
          const [relatedPropertyName] = args.constraints;
          const relatedValue = (args.object as any)[relatedPropertyName];
          return value !== relatedValue;
        },
        defaultMessage(args: ValidationArguments) {
          const [relatedPropertyName] = args.constraints;
          return `${args.property} deve ser diferente de ${relatedPropertyName}`;
        },
      },
    });
  };
}

/**
 * Decorator para validar se uma data é posterior a outra
 */
export function IsAfter(
  property: string,
  validationOptions?: ValidationOptions,
) {
  return function (target: any, propertyKey: string) {
    registerDecorator({
      name: 'isAfter',
      target: target.constructor,
      propertyName: propertyKey,
      constraints: [property],
      options: validationOptions,
      validator: {
        validate(value: any, args: ValidationArguments) {
          const [relatedPropertyName] = args.constraints;
          const relatedValue = (args.object as any)[relatedPropertyName];

          if (!value || !relatedValue) return true;

          const dateValue = new Date(value);
          const relatedDateValue = new Date(relatedValue);

          return dateValue > relatedDateValue;
        },
        defaultMessage(args: ValidationArguments) {
          const [relatedPropertyName] = args.constraints;
          return `${args.property} deve ser posterior a ${relatedPropertyName}`;
        },
      },
    });
  };
}
