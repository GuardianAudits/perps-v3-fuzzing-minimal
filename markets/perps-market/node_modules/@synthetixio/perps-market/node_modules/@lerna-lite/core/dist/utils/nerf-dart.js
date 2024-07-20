import url from 'node:url';
export function toNerfDart(uri) {
    const parsed = url.parse(uri);
    delete parsed.protocol;
    delete parsed.auth;
    delete parsed.query;
    delete parsed.search;
    delete parsed.hash;
    return url.resolve(url.format(parsed), '.');
}
//# sourceMappingURL=nerf-dart.js.map