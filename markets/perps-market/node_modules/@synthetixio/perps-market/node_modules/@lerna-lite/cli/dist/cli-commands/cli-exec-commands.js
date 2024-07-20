import { filterOptions } from '../filter-options.js';
export default {
    command: 'exec [cmd] [args..]',
    describe: 'Execute an arbitrary command in each package',
    builder: (yargs) => {
        yargs
            .example('$0 exec ls -- --la', '# execute `ls -la` in all packages')
            .example('$0 exec -- ls --la', '# execute `ls -la` in all packages, keeping cmd outside')
            .parserConfiguration({
            'populate--': true,
        })
            .positional('cmd', {
            describe: 'The command to execute. Any command flags must be passed after --',
            type: 'string',
        })
            .positional('args', {
            describe: 'Positional arguments (not recognized by lerna) to send to command',
            type: 'string',
        })
            .options({
            stream: {
                group: 'Command Options:',
                describe: 'Stream output with lines prefixed by originating package name.',
                type: 'boolean',
            },
            parallel: {
                group: 'Command Options:',
                describe: 'Execute command with unlimited concurrency, streaming prefixed output.',
                type: 'boolean',
            },
            'no-bail': {
                group: 'Command Options:',
                describe: 'Continue executing command despite non-zero exit in a given package.',
                type: 'boolean',
            },
            bail: {
                hidden: true,
                type: 'boolean',
            },
            'no-prefix': {
                group: 'Command Options:',
                describe: 'Do not prefix streaming output.',
                type: 'boolean',
            },
            prefix: {
                hidden: true,
                type: 'boolean',
            },
            profile: {
                group: 'Command Options:',
                describe: 'Profile command executions and output performance profile to default location.',
                type: 'boolean',
            },
            'profile-location': {
                group: 'Command Options:',
                describe: 'Output performance profile to custom location instead of default project root.',
                type: 'string',
            },
            'dry-run': {
                group: 'Command Options:',
                describe: 'Displays the execution command that would be performed without executing it.',
                type: 'boolean',
            },
        });
        return filterOptions(yargs);
    },
    handler: async (argv) => {
        try {
            const { ExecCommand } = await import('@lerna-lite/exec');
            new ExecCommand(argv);
        }
        catch (err) {
            throw new Error(`"@lerna-lite/exec" is optional and was not found. Please install it with "npm install @lerna-lite/exec -D". ${err}`);
        }
    },
};
//# sourceMappingURL=cli-exec-commands.js.map