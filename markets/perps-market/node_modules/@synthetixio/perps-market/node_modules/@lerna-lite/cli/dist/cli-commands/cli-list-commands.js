import { filterOptions } from '../filter-options.js';
import { listableOptions } from './listable/listable-options.js';
export default {
    command: 'list',
    aliases: ['ls', 'la', 'll'],
    describe: 'List local packages',
    builder: (yargs) => {
        listableOptions(yargs);
        return filterOptions(yargs);
    },
    handler: async (argv) => {
        try {
            const { ListCommand } = await import('@lerna-lite/list');
            new ListCommand(argv);
        }
        catch (err) {
            throw new Error(`"@lerna-lite/list" is optional and was not found. Please install it with "npm install @lerna-lite/list -D". ${err}`);
        }
    },
};
//# sourceMappingURL=cli-list-commands.js.map