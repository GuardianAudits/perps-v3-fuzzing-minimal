"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.reportErrors = exports.errorMap = void 0;
const zod_1 = require("zod");
const colorette_1 = require("colorette");
// Even though we also have our own formatter, we pass a custom error map to
// Zod's `.parse()` for two reasons:
// - to ensure that no other consumer of zod in the codebase has set a default
//   error map that might override our formatting
// - to return slightly friendly error messages in some common scenarios.
const errorMap = (issue, ctx) => {
    if (issue.code === zod_1.ZodIssueCode.invalid_type &&
        issue.received === "undefined") {
        return { message: "This field is required." };
    }
    return { message: ctx.defaultError };
};
exports.errorMap = errorMap;
const indent = (str, amt) => `${" ".repeat(amt)}${str}`;
function reportErrors(errors, schemas) {
    const formattedErrors = errors.map(({ key, receivedValue, error, defaultUsed, defaultValue }) => {
        const message = [`[${(0, colorette_1.yellow)(key)}]:`];
        if (error instanceof zod_1.ZodError) {
            const { formErrors, fieldErrors } = error.flatten();
            for (const fe of formErrors)
                message.push(indent(fe, 2));
            const fieldErrorEntries = Object.entries(fieldErrors);
            if (fieldErrorEntries.length > 0) {
                message.push(indent("Errors on object keys:", 2));
                for (const [objKey, keyErrors] of fieldErrorEntries) {
                    message.push(indent(`[${(0, colorette_1.green)(objKey)}]:`, 4));
                    for (const fe of keyErrors)
                        message.push(indent(fe, 6));
                }
            }
        }
        else if (error instanceof Error) {
            message.push(...error.message.split("\n").map((l) => indent(l, 2)));
        }
        else {
            message.push(...JSON.stringify(error, undefined, 2)
                .split("\n")
                .map((l) => indent(l, 2)));
        }
        message.push(indent(`(received ${(0, colorette_1.cyan)(receivedValue === undefined
            ? "undefined"
            : JSON.stringify(receivedValue))})`, 2));
        if (defaultUsed) {
            message.push(indent(`(used default of ${(0, colorette_1.cyan)(defaultValue === undefined
                ? "undefined"
                : JSON.stringify(defaultValue))})`, 2));
        }
        const desc = schemas[key]?.description;
        if (desc) {
            message.push("");
            message.push(`Description of [${(0, colorette_1.yellow)(key)}]: ${schemas[key].description}`);
        }
        return message.map((l) => indent(l, 2)).join("\n");
    });
    return `${(0, colorette_1.red)("Errors found while parsing environment:")}\n${formattedErrors.join("\n\n")}\n`;
}
exports.reportErrors = reportErrors;
//# sourceMappingURL=reporter.js.map