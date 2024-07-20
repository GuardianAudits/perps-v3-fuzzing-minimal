import { ValidationError } from '@lerna-lite/core';
import { getFetchConfig } from './fetch-config.js';
import { getProfileData } from './get-profile-data.js';
export function getTwoFactorAuthRequired(options) {
    const opts = getFetchConfig(options, {
        fetchRetries: 0,
    });
    opts.log.info('', 'Checking two-factor auth mode');
    return getProfileData(opts).then(success, failure);
    function success(result) {
        opts.log.silly('2FA', result.tfa.toString());
        if (result.tfa.pending) {
            return false;
        }
        return result.tfa.mode === 'auth-and-writes';
    }
    function failure(err) {
        if (err.code === 'E500' || err.code === 'E404') {
            opts.log.warn('EREGISTRY', `Registry "${opts.registry}" does not support 'npm profile get', skipping two-factor auth check...`);
            return false;
        }
        opts.log.pause();
        console.error(err.message);
        opts.log.resume();
        throw new ValidationError('ETWOFACTOR', 'Unable to obtain two-factor auth mode');
    }
}
//# sourceMappingURL=get-two-factor-auth-required.js.map