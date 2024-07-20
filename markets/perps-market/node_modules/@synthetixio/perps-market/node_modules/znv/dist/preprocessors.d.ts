import * as z from "zod";
/**
 * Given a Zod schema, returns a function that tries to convert a string (or
 * undefined!) to a valid input type for the schema.
 */
export declare function getPreprocessorByZodType(schema: z.ZodFirstPartySchemaTypes): (arg: string | undefined) => unknown;
/**
 * Given a Zod schema, return the schema wrapped in a preprocessor that tries to
 * convert a string to the schema's input type.
 */
export declare function getSchemaWithPreprocessor(schema: z.ZodTypeAny): z.ZodEffects<z.ZodTypeAny, any, any>;
