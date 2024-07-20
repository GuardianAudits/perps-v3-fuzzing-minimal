export function shallowExtend(json, defaults = {}) {
    return Object.keys(json).reduce((obj, key) => {
        const val = json[key];
        if (Array.isArray(val)) {
            obj[key] = val.slice();
        }
        else if (val && typeof val === 'object') {
            obj[key] = shallowExtend(val, obj[key]);
        }
        else {
            obj[key] = val;
        }
        return obj;
    }, defaults);
}
//# sourceMappingURL=shallow-extend.js.map