import path from 'path';
import { envReplace } from './env-replace.js';
import { types } from './types.js';
export function parseField(input, key) {
    if (typeof input !== 'string') {
        return input;
    }
    const typeList = [].concat(types[key]);
    const isPath = typeList.indexOf(path) !== -1;
    const isBool = typeList.indexOf(Boolean) !== -1;
    const isString = typeList.indexOf(String) !== -1;
    const isNumber = typeList.indexOf(Number) !== -1;
    let field = `${input}`.trim();
    if (/^'.*'$/.test(field)) {
        try {
            field = JSON.parse(field);
        }
        catch (err) {
            throw new Error(`Failed parsing JSON config key ${key}: ${field}`);
        }
    }
    if (isBool && !isString && field === '') {
        return true;
    }
    switch (field) {
        case 'true': {
            return true;
        }
        case 'false': {
            return false;
        }
        case 'null': {
            return null;
        }
        case 'undefined': {
            return undefined;
        }
    }
    field = envReplace(field);
    if (isPath) {
        const regex = process.platform === 'win32' ? /^~(\/|\\)/ : /^~\//;
        if (typeof field === 'string' && regex.test(field) && process.env.HOME) {
            field = path.resolve(process.env.HOME, field.substring(2));
        }
        field = path.resolve(field);
    }
    if (isNumber && !isNaN(field)) {
        field = Number(field);
    }
    return field;
}
//# sourceMappingURL=parse-field.js.map