import { remove } from 'fs-extra/esm';
import pMap from 'p-map';
export function removeTempLicenses(packagesToBeLicensed) {
    if (!packagesToBeLicensed.length) {
        return Promise.resolve();
    }
    return pMap(packagesToBeLicensed, (pkg) => remove(pkg.licensePath));
}
//# sourceMappingURL=remove-temp-licenses.js.map