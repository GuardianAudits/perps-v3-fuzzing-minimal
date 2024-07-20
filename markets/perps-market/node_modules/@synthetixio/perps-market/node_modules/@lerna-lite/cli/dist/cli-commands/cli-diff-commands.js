export default {
    command: 'diff [pkgName]',
    describe: 'Diff all packages or a single package since the last release',
    builder: {
        'ignore-changes': {
            group: 'Command Options:',
            describe: 'Ignore changes in files matched by glob(s).',
            type: 'array',
        },
    },
    handler: async (argv) => {
        try {
            const { DiffCommand } = await import('@lerna-lite/diff');
            new DiffCommand(argv);
        }
        catch (err) {
            throw new Error(`"@lerna-lite/diff" is optional and was not found. Please install it with "npm install @lerna-lite/diff -D". ${err}`);
        }
    },
};
//# sourceMappingURL=cli-diff-commands.js.map