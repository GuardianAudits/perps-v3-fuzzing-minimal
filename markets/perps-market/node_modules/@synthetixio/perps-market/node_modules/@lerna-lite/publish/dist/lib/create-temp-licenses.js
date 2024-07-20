import { copy } from 'fs-extra/esm';
import { basename, join } from 'node:path';
import pMap from 'p-map';
export function createTempLicenses(srcLicensePath, packagesToBeLicensed) {
    if (!srcLicensePath || !packagesToBeLicensed.length) {
        return Promise.resolve();
    }
    const licenseFileName = basename(srcLicensePath);
    const options = {
        preserveTimestamps: process.arch !== 'ia32',
    };
    packagesToBeLicensed.forEach((pkg) => {
        pkg.licensePath = join(pkg.contents, licenseFileName);
    });
    return pMap(packagesToBeLicensed, (pkg) => copy(srcLicensePath, pkg.licensePath, options));
}
//# sourceMappingURL=create-temp-licenses.js.map