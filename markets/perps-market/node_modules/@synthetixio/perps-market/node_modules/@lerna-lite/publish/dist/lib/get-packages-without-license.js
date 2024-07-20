import { dirname } from 'node:path';
export function getPackagesWithoutLicense(project, packagesToPublish) {
    return project.getPackageLicensePaths().then((licensePaths) => {
        const licensed = new Set(licensePaths.map((lp) => dirname(lp)));
        return packagesToPublish.filter((pkg) => !licensed.has(pkg.location));
    });
}
//# sourceMappingURL=get-packages-without-license.js.map