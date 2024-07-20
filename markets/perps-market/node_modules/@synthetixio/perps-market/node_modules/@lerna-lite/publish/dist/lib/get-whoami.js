import fetch from 'npm-registry-fetch';
import { pulseTillDone } from '@lerna-lite/core';
export async function getWhoAmI(opts) {
    opts.log.verbose('', 'Retrieving npm username');
    const data = pulseTillDone(await fetch.json('/-/whoami', opts));
    opts.log.silly('npm whoami', 'received %j', data);
    return data;
}
//# sourceMappingURL=get-whoami.js.map