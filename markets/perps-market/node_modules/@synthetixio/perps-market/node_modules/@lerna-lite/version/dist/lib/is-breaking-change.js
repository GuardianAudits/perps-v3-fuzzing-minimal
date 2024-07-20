import semver from 'semver';
export function isBreakingChange(currentVersion, nextVersion) {
    const releaseType = semver.diff(currentVersion, nextVersion);
    let breaking;
    if (releaseType === 'major') {
        breaking = true;
    }
    else if (releaseType === 'minor') {
        breaking = semver.lt(currentVersion, '1.0.0');
    }
    else if (releaseType === 'patch') {
        breaking = semver.lt(currentVersion, '0.1.0');
    }
    else {
        breaking = false;
    }
    return breaking;
}
//# sourceMappingURL=is-breaking-change.js.map