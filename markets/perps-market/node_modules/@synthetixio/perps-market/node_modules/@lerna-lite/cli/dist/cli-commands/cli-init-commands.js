import { InitCommand } from '@lerna-lite/init';
export default {
    command: 'init',
    describe: 'Create a new Lerna repo or upgrade an existing repo to the current version of Lerna.',
    builder: {
        exact: {
            describe: 'Specify lerna dependency version in package.json without a caret (^)',
            type: 'boolean',
        },
        independent: {
            describe: 'Version packages independently',
            alias: 'i',
            type: 'boolean',
        },
        'use-workspaces': {
            group: 'Command Options:',
            describe: 'Enable integration with Yarn workspaces.',
            type: 'boolean',
        },
    },
    handler: (argv) => {
        return new InitCommand(argv);
    },
};
//# sourceMappingURL=cli-init-commands.js.map