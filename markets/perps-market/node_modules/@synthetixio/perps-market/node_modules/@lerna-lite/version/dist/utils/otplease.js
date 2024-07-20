import { promptTextInput } from '@lerna-lite/core';
const semaphore = {
    wait() {
        return new Promise((resolve) => {
            if (!this._promise) {
                this._promise = new Promise((release) => {
                    this._resolve = release;
                });
                resolve(undefined);
            }
            else {
                resolve(this._promise.then(() => this.wait()));
            }
        });
    },
    release() {
        const resolve = this._resolve;
        if (resolve) {
            this._resolve = undefined;
            this._promise = undefined;
            resolve();
        }
    },
};
export function otplease(fn, _opts, otpCache) {
    const opts = { ...otpCache, ..._opts };
    return attempt(fn, opts, otpCache);
}
function attempt(fn, opts, otpCache) {
    return new Promise((resolve) => {
        resolve(fn(opts));
    }).catch((err) => {
        if (err.code !== 'EOTP' && !(err.code === 'E401' && /one-time pass/.test(err.body))) {
            throw err;
        }
        else if (!process.stdin.isTTY || !process.stdout.isTTY) {
            throw err;
        }
        else {
            if (!isNullOrUndefined(otpCache) && !isNullOrUndefined(otpCache.otp) && otpCache.otp !== opts.otp) {
                return attempt(fn, { ...opts, ...otpCache }, otpCache);
            }
            return semaphore.wait().then(() => {
                if (!isNullOrUndefined(otpCache) && !isNullOrUndefined(otpCache.otp) && otpCache.otp !== opts.otp) {
                    semaphore.release();
                    return attempt(fn, { ...opts, ...otpCache }, otpCache);
                }
                return getOneTimePassword()
                    .then((otp) => {
                    if (!isNullOrUndefined(otpCache)) {
                        otpCache.otp = otp;
                    }
                    semaphore.release();
                    return otp;
                }, (promptError) => {
                    semaphore.release();
                    return Promise.reject(promptError);
                })
                    .then((otp) => {
                    return fn({ ...opts, otp });
                });
            });
        }
    });
}
export function getOneTimePassword(message = 'This operation requires a one-time password:') {
    return promptTextInput(message, {
        filter: (otp) => otp.replace(/\s+/g, ''),
        validate: (otp) => (otp && /^[\d ]+$|^[A-Fa-f0-9]{64,64}$/.test(otp)) ||
            'Must be a valid one-time-password. ' + 'See https://docs.npmjs.com/getting-started/using-two-factor-authentication',
    });
}
function isNullOrUndefined(val) {
    return val === null || val === undefined;
}
//# sourceMappingURL=otplease.js.map