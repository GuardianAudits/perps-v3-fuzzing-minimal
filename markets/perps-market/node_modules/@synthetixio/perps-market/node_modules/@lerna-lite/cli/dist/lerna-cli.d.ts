declare function lernaCLI(argv?: any[], cwd?: string): import("yargs").Argv<import("yargs").Omit<import("yargs").Omit<any, string | number | symbol> & import("yargs").InferredOptionTypes<any>, "ci"> & {
    ci: boolean | undefined;
} & {
    help: unknown;
} & {
    version: unknown;
}>;
export default lernaCLI;
