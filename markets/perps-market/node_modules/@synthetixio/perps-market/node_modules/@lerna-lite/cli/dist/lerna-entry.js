import { loadJsonFileSync } from 'load-json-file';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import changedCmd from './cli-commands/cli-changed-commands.js';
import diffCmd from './cli-commands/cli-diff-commands.js';
import execCmd from './cli-commands/cli-exec-commands.js';
import initCmd from './cli-commands/cli-init-commands.js';
import listCmd from './cli-commands/cli-list-commands.js';
import publishCmd from './cli-commands/cli-publish-commands.js';
import runCmd from './cli-commands/cli-run-commands.js';
import versionCmd from './cli-commands/cli-version-commands.js';
import watchCmd from './cli-commands/cli-watch-commands.js';
import cli from './lerna-cli.js';
export function lerna(argv) {
    const __filename = fileURLToPath(import.meta.url);
    const __dirname = dirname(__filename);
    const cliPkg = loadJsonFileSync(join(__dirname, '../', 'package.json'));
    const context = {
        lernaVersion: (cliPkg?.version ?? ''),
    };
    return cli()
        .command(changedCmd)
        .command(diffCmd)
        .command(execCmd)
        .command(initCmd)
        .command(listCmd)
        .command(publishCmd)
        .command(runCmd)
        .command(versionCmd)
        .command(watchCmd)
        .parse(argv, context);
}
//# sourceMappingURL=lerna-entry.js.map