import { exec, execSync } from '../child-process.js';
import { isCorepackEnabled } from './is-corepack-enabled.js';
function createCommandAndArgs(npmClient, args) {
    let command = npmClient;
    const commandArgs = args === undefined ? [] : [...args];
    if (isCorepackEnabled()) {
        commandArgs.unshift(command);
        command = 'corepack';
    }
    return { command, commandArgs };
}
export function execPackageManager(npmClient, args, opts, dryRun = false) {
    const { command, commandArgs } = createCommandAndArgs(npmClient, args);
    return exec(command, commandArgs, opts, dryRun);
}
export function execPackageManagerSync(npmClient, args, opts, dryRun = false) {
    const { command, commandArgs } = createCommandAndArgs(npmClient, args);
    return execSync(command, commandArgs, opts, dryRun);
}
//# sourceMappingURL=exec-package-manager.js.map