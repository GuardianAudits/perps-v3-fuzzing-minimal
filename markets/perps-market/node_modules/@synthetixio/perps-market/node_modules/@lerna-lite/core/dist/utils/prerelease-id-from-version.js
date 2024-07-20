import semver from 'semver';
export function prereleaseIdFromVersion(version) {
    return (semver.prerelease(version) || []).shift();
}
//# sourceMappingURL=prerelease-id-from-version.js.map