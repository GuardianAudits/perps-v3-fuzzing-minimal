import { collectDependents } from './collect-dependents.js';
export function collectPackages(packages, { isCandidate = () => true, onInclude, excludeDependents } = {}) {
    const candidates = new Set();
    packages.forEach((node, name) => {
        if (isCandidate(node, name)) {
            candidates.add(node);
        }
    });
    if (!excludeDependents) {
        collectDependents(candidates).forEach((node) => candidates.add(node));
    }
    const updates = [];
    packages.forEach((node, name) => {
        if (candidates.has(node)) {
            if (onInclude) {
                onInclude(name);
            }
            updates.push(node);
        }
    });
    return updates;
}
//# sourceMappingURL=collect-packages.js.map