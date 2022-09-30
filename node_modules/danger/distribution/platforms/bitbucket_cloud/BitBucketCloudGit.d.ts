import { GitJSONDSL, GitDSL } from "../../dsl/GitDSL";
import { BitBucketCloudAPI } from "./BitBucketCloudAPI";
import { BitBucketCloudDSL } from "../../dsl/BitBucketCloudDSL";
import { GitCommitAuthor } from "../../dsl/Commit";
export declare function bitBucketCloudRawAndDateToGitCommitAuthor(raw: string, date: string): GitCommitAuthor;
export default function gitDSLForBitBucketCloud(api: BitBucketCloudAPI): Promise<GitJSONDSL>;
export declare const bitBucketCloudGitDSL: (bitBucketCloud: BitBucketCloudDSL, json: GitJSONDSL, bitBucketCloudAPI: BitBucketCloudAPI) => GitDSL;
