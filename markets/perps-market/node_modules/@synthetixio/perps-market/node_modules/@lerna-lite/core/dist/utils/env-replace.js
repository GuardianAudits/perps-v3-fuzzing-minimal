export function envReplace(str) {
    if (typeof str !== 'string' || !str) {
        return str;
    }
    const regex = /(\\*)\$\{([^}]+)\}/g;
    return str.replace(regex, (orig, esc, name) => {
        if (esc.length > 0 && esc.length % 2) {
            return orig;
        }
        if (!name || process.env[name] === undefined) {
            throw new Error(`Failed to replace env in config: ${orig}`);
        }
        return process.env[name] ?? '';
    });
}
//# sourceMappingURL=env-replace.js.map