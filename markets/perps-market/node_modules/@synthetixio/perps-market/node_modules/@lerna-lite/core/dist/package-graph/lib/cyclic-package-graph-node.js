let lastCollapsedNodeId = 0;
export class CyclicPackageGraphNode extends Map {
    constructor() {
        super();
        this.name = `(cycle) ${(lastCollapsedNodeId += 1)}`;
        this.localDependencies = new Map();
        this.localDependents = new Map();
    }
    get isCycle() {
        return true;
    }
    toString() {
        const parts = Array.from(this, ([key, node]) => node.isCycle ? `(nested cycle: ${node.toString()})` : key);
        parts.push(parts[0]);
        return parts.reverse().join(' -> ');
    }
    flatten() {
        const result = [];
        for (const node of this.values()) {
            if (node.isCycle) {
                result.push(...node.flatten());
            }
            else {
                result.push(node);
            }
        }
        return result;
    }
    contains(name) {
        for (const [currentName, currentNode] of this) {
            if (currentNode.isCycle) {
                if (currentNode.contains(name)) {
                    return true;
                }
            }
            else if (currentName === name) {
                return true;
            }
        }
        return false;
    }
    insert(node) {
        this.set(node.name, node);
        this.unlink(node);
        for (const [dependencyName, dependencyNode] of node.localDependencies) {
            if (!this.contains(dependencyName)) {
                this.localDependencies.set(dependencyName, dependencyNode);
            }
        }
        for (const [dependentName, dependentNode] of node.localDependents) {
            if (!this.contains(dependentName)) {
                this.localDependents.set(dependentName, dependentNode);
            }
        }
    }
    unlink(candidateNode) {
        this.localDependencies.delete(candidateNode.name);
        this.localDependents.delete(candidateNode.name);
    }
}
//# sourceMappingURL=cyclic-package-graph-node.js.map