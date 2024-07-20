import { filterOptions } from '../filter-options.js';
export default {
    command: 'run <script>',
    describe: 'Run an npm script in each package that contains that script',
    builder: (yargs) => {
        yargs
            .example('$0 run build -- --silent', '# `npm run build --silent` in all packages with a build script')
            .parserConfiguration({
            'populate--': true,
        })
            .positional('script', {
            describe: 'The npm script to run. Pass flags to send to the npm client after --',
            type: 'string',
        })
            .options({
            'dry-run': {
                group: 'Command Options:',
                describe: 'Displays the process command that would be performed without executing it.',
                type: 'boolean',
            },
            'npm-client': {
                group: 'Command Options:',
                describe: 'Executable used to run scripts (npm, yarn, pnpm, ...).',
                defaultDescription: 'npm',
                type: 'string',
                requiresArg: true,
            },
            stream: {
                group: 'Command Options:',
                describe: 'Stream output with lines prefixed by package.',
                type: 'boolean',
            },
            parallel: {
                group: 'Command Options:',
                describe: 'Run script with unlimited concurrency, streaming prefixed output.',
                type: 'boolean',
            },
            'no-bail': {
                group: 'Command Options:',
                describe: 'Continue running script despite non-zero exit in a given package.',
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
                describe: 'Profile script executions and output performance profile to default location.',
                type: 'boolean',
            },
            'profile-location': {
                group: 'Command Options:',
                describe: 'Output performance profile to custom location instead of default project root.',
                type: 'string',
            },
        });
        return filterOptions(yargs);
    },
    handler: async (argv) => {
        try {
            const { RunCommand } = await import('@lerna-lite/run');
            new RunCommand(argv);
        }
        catch (err) {
            throw new Error(`"@lerna-lite/run" is optional and was not found. Please install it with "npm install @lerna-lite/run -D". ${err}`);
        }
    },
};
//# sourceMappingURL=cli-run-commands.js.map