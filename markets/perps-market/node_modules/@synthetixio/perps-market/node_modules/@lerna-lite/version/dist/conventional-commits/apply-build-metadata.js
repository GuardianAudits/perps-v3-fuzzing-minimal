import { ValidationError } from '@lerna-lite/core';
const BUILD_METADATA_REGEX = /^[0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*$/;
export function applyBuildMetadata(version, buildMetadata) {
    version = version || '';
    if (!buildMetadata) {
        return version;
    }
    if (isValidBuildMetadata(buildMetadata)) {
        return `${version}+${buildMetadata}`;
    }
    throw new ValidationError('EBUILDMETADATA', 'Build metadata does not satisfy SemVer specification.');
}
function isValidBuildMetadata(buildMetadata) {
    return BUILD_METADATA_REGEX.test(buildMetadata);
}
//# sourceMappingURL=apply-build-metadata.js.map