import { cpus } from 'node:os';
export function globalOptions(yargs) {
    const opts = {
        loglevel: {
            defaultDescription: 'info',
            describe: 'What level of logs to report.',
            type: 'string',
        },
        concurrency: {
            defaultDescription: cpus().length,
            describe: 'How many processes to use when lerna parallelizes tasks.',
            type: 'number',
            requiresArg: true,
        },
        'reject-cycles': {
            describe: 'Fail if a cycle is detected among dependencies.',
            type: 'boolean',
        },
        'no-progress': {
            describe: 'Disable progress bars. (Always off in CI)',
            type: 'boolean',
        },
        progress: {
            hidden: true,
            type: 'boolean',
        },
        'no-sort': {
            describe: 'Do not sort packages topologically (dependencies before dependents).',
            type: 'boolean',
        },
        sort: {
            hidden: true,
            type: 'boolean',
        },
        'max-buffer': {
            describe: 'Set max-buffer (in bytes) for subcommand execution',
            type: 'number',
            requiresArg: true,
        },
    };
    const globalKeys = Object.keys(opts).concat(['help', 'version']);
    return yargs.options(opts).group(globalKeys, 'Global Options:').option('ci', {
        hidden: true,
        type: 'boolean',
    });
}
//# sourceMappingURL=global-options.js.map