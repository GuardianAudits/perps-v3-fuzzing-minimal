import * as z from "zod";
export declare const port: () => z.ZodNumber;
export declare const deprecate: () => z.ZodEffects<z.ZodUndefined, never, undefined>;
