export function isNpmPkgGitHubPublishVersionConflict(ex) {
    if (!ex || typeof ex !== 'object' || !(ex instanceof Error)) {
        return false;
    }
    else if ('code' in ex && ex.code === 'E409') {
        return true;
    }
    else if ('body' in ex &&
        typeof ex.body === 'object' &&
        ex.body.error === 'Cannot publish over existing version') {
        return true;
    }
    else {
        return ex.message.startsWith('409 Conflict - PUT https://npm.pkg.github.com');
    }
}
//# sourceMappingURL=is-npm-pkg-github-publish-version-conflict.js.map