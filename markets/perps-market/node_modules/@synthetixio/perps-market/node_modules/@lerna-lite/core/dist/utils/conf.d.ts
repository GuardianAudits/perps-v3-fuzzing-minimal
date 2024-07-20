import { ConfigChain } from 'config-chain';
export declare class Conf extends ConfigChain {
    _await: any;
    addString: any;
    del: any;
    get: any;
    set: any;
    globalPrefix: string;
    localPrefix: string;
    root: any;
    sources: any;
    push: any;
    list: any;
    constructor(base: any);
    add(data: any, marker: any): any;
    addFile(file: string, name?: string): this;
    addEnv(env?: {
        [key: string]: string | undefined;
    }): any;
    loadPrefix(): any;
    loadCAFile(file: string): void;
    loadUser(): void;
    getCredentialsByURI(uri: string): any;
    setCredentialsByURI(uri: any, c: any): void;
}
