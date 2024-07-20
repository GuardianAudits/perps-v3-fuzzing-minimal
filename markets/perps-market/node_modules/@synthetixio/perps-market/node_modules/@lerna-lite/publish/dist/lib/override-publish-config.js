import { isEmpty } from '@lerna-lite/core';
const PUBLISH_CONFIG_WHITELIST = new Set([
    'bin',
    'browser',
    'cpu',
    'esnext',
    'es2015',
    'exports',
    'imports',
    'libc',
    'main',
    'module',
    'os',
    'type',
    'types',
    'typings',
    'typesVersions',
    'umd:main',
    'unpkg',
]);
export function overridePublishConfig(manifest) {
    const publishConfig = manifest?.publishConfig;
    if (publishConfig) {
        Object.entries(publishConfig)
            .filter(([key]) => PUBLISH_CONFIG_WHITELIST.has(key))
            .forEach(([key, value]) => {
            manifest[key] = value;
            delete publishConfig[key];
        });
        if (isEmpty(publishConfig)) {
            delete manifest.publishConfig;
        }
    }
}
//# sourceMappingURL=override-publish-config.js.map