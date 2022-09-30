import GitLabAPI from "./gitlab/GitLabAPI";
import { Platform, Comment } from "./platform";
import { GitDSL, GitJSONDSL } from "../dsl/GitDSL";
import { GitLabDSL, GitLabJSONDSL, GitLabNote } from "../dsl/GitLabDSL";
declare class GitLab implements Platform {
    readonly api: GitLabAPI;
    readonly name: string;
    constructor(api: GitLabAPI);
    getReviewInfo: () => Promise<any>;
    getPlatformReviewDSLRepresentation: () => Promise<GitLabJSONDSL>;
    getPlatformGitRepresentation: () => Promise<GitJSONDSL>;
    getInlineComments: (dangerID: string) => Promise<Comment[]>;
    supportsCommenting(): boolean;
    supportsInlineComments(): boolean;
    updateOrCreateComment: (dangerID: string, newComment: string) => Promise<string>;
    createComment: (comment: string) => Promise<any>;
    createInlineComment: (git: GitDSL, comment: string, path: string, line: number) => Promise<string>;
    updateInlineComment: (comment: string, id: string) => Promise<GitLabNote>;
    deleteInlineComment: (id: string) => Promise<boolean>;
    deleteMainComment: (dangerID: string) => Promise<boolean>;
    getDangerNotes: (dangerID: string) => Promise<GitLabNote[]>;
    updateStatus: () => Promise<boolean>;
    getFileContents: (path: string, slug?: string | undefined, ref?: string | undefined) => Promise<string>;
}
export default GitLab;
export declare const gitlabJSONToGitLabDSL: (gl: GitLabDSL, api: GitLabAPI) => GitLabDSL;
