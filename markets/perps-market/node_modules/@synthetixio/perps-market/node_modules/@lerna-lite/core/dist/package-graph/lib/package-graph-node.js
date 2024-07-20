import semver from 'semver';
import { prereleaseIdFromVersion } from '../../utils/prerelease-id-from-version.js';
const PKG = Symbol('pkg');
export class PackageGraphNode {
    constructor(pkg) {
        this.name = pkg?.name ?? '';
        this[PKG] = pkg;
        Object.defineProperty(this, PKG, { enumerable: false });
        this.externalDependencies = new Map();
        this.localDependencies = new Map();
        this.localDependents = new Map();
    }
    get location() {
        return this[PKG].location;
    }
    get pkg() {
        return this[PKG];
    }
    get prereleaseId() {
        return prereleaseIdFromVersion(this.version);
    }
    get version() {
        return this[PKG].version;
    }
    satisfies({ gitCommittish, gitRange, fetchSpec }) {
        return semver.satisfies(this.version, (gitCommittish || gitRange || fetchSpec));
    }
    toString() {
        return this.name;
    }
}
//# sourceMappingURL=package-graph-node.js.map