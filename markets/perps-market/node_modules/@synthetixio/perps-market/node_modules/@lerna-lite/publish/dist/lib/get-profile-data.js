import fetch from 'npm-registry-fetch';
import { pulseTillDone } from '@lerna-lite/core';
export async function getProfileData(opts) {
    opts.log.verbose('', 'Retrieving npm user profile');
    const data = await pulseTillDone(await fetch.json('/-/npm/v1/user', opts));
    opts.log.silly('npm profile get', 'received %j', data);
    return Object.assign({ username: data.name }, data);
}
//# sourceMappingURL=get-profile-data.js.map