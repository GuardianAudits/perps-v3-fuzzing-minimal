export function collectDependents(nodes) {
    const collected = new Set();
    nodes.forEach((currentNode) => {
        if (currentNode.localDependents.size === 0) {
            return;
        }
        const queue = [currentNode];
        const seen = new Set();
        const visit = (dependentNode, dependentName, siblingDependents) => {
            if (seen.has(dependentNode)) {
                return;
            }
            seen.add(dependentNode);
            if (dependentNode === currentNode || siblingDependents.has(currentNode.name)) {
                return;
            }
            collected.add(dependentNode);
            queue.push(dependentNode);
        };
        while (queue.length) {
            const node = queue.shift();
            node.localDependents.forEach(visit);
        }
    });
    return collected;
}
//# sourceMappingURL=collect-dependents.js.map