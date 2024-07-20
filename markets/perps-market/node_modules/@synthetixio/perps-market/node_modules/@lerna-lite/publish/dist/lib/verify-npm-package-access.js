import access from 'libnpmaccess';
import { pulseTillDone, ValidationError } from '@lerna-lite/core';
import { getFetchConfig } from './fetch-config.js';
export function verifyNpmPackageAccess(packages, username, options) {
    const opts = getFetchConfig(options, {
        fetchRetries: 0,
    });
    opts.log.silly('verifyNpmPackageAccess', '');
    return pulseTillDone(access.getPackages(username, opts)).then(success, failure);
    function success(result) {
        if (result === null) {
            opts.log.warn('', 'The logged-in user does not have any previously-published packages, skipping permission checks...');
        }
        else {
            for (const pkg of packages) {
                if (pkg?.name in result && result[pkg?.name] !== 'read-write') {
                    throw new ValidationError('EACCESS', `You do not have write permission required to publish "${pkg.name}"`);
                }
            }
        }
    }
    function failure(err) {
        if (err.code === 'E500' || err.code === 'E404') {
            opts.log.warn('EREGISTRY', 'Registry %j does not support `npm access ls-packages`, skipping permission checks...', opts.registry);
            return;
        }
        opts.log.pause();
        console.error(err.message);
        opts.log.resume();
        throw new ValidationError('EWHOAMI', 'Authentication error. Use `npm whoami` to troubleshoot.');
    }
}
//# sourceMappingURL=verify-npm-package-access.js.map