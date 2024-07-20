import { ValidationError } from '@lerna-lite/core';
import { getFetchConfig } from './fetch-config.js';
import { getProfileData } from './get-profile-data.js';
import { getWhoAmI } from './get-whoami.js';
export function getNpmUsername(options) {
    const opts = getFetchConfig(options, {
        fetchRetries: 0,
    });
    opts.log.info('', 'Verifying npm credentials');
    return getProfileData(opts)
        .catch((err) => {
        if (err.code === 'E500' || err.code === 'E404') {
            return getWhoAmI(opts);
        }
        throw err;
    })
        .then(success, failure);
    function success(result) {
        opts.log.silly('get npm username', 'received %j', result);
        if (!result.username) {
            throw new ValidationError('ENEEDAUTH', 'You must be logged in to publish packages. Use `npm login` and try again.');
        }
        return result.username;
    }
    function failure(err) {
        opts.log.pause();
        console.error(err.message);
        opts.log.resume();
        if (opts.registry === 'https://registry.npmjs.org/') {
            if (err.code === 'E403') {
                throw new ValidationError('ENEEDAUTH', 'Access verification failed. Ensure that your npm access token has both read and write access, or remove the verifyAccess option to skip this verification. Note that npm automation tokens do NOT have read access (https://docs.npmjs.com/creating-and-viewing-access-tokens).');
            }
            throw new ValidationError('EWHOAMI', 'Authentication error. Use `npm whoami` to troubleshoot.');
        }
        opts.log.warn('EWHOAMI', 'Unable to determine npm username from third-party registry, this command will likely fail soon!');
    }
}
//# sourceMappingURL=get-npm-username.js.map