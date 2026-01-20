import path from 'path';
import {dirname} from 'path';
import {fileURLToPath} from 'url';

// Get __dirname equivalent in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Get all arguments
const args = process.argv.slice(2);
const env = process.env;

// Read stdin
let stdinData = '';

process.stdin.setEncoding('utf8');

process.stdin.on('data', chunk => {
    stdinData += chunk;
});

process.stdin.on('end', () => {
    let parsedStdin = null;
    try {
        parsedStdin = JSON.parse(stdinData);
    } catch (e) {
        parsedStdin = stdinData;
    }

    // Extract the command from stdin
    const command = parsedStdin?.tool_input?.command || parsedStdin?.command || '';

    // Get the project directory from environment
    const projectDir = env.CLAUDE_PROJECT_DIR || path.join(__dirname, '..', '..');
    const normalizedProjectDir = path.resolve(projectDir).toLowerCase();

    // Pattern to detect cd commands
    const cdPattern = /^\s*cd\s+(.+?)(?:\s*[;&|]|\s*$)/i;
    const match = command.match(cdPattern);

    if (match) {
        let targetPath = match[1].trim();

        // Remove quotes if present
        targetPath = targetPath.replace(/^["']|["']$/g, '');

        // Skip if it's just "cd" without arguments (goes to home directory)
        if (!targetPath || targetPath === '~') {
            const response = {
                hookSpecificOutput: {
                    hookEventName: "PreToolUse",
                    permissionDecision: "ask",
                    permissionDecisionReason: `NAVIGATING OUTSIDE WORKSPACE

You are attempting to navigate to your home directory, which is outside the current workspace.

Current workspace: ${projectDir}
Target: Home directory

Do you want to allow this navigation?

Command: ${command}`
                }
            };

            console.log(JSON.stringify(response));
            process.exit(0);
        }

        // Resolve the target path (handling both absolute and relative paths)
        let resolvedPath;
        try {
            if (path.isAbsolute(targetPath)) {
                resolvedPath = path.resolve(targetPath);
            } else {
                // For relative paths, we need to consider the current working directory
                // Since we don't know the exact cwd at execution time, we check against project dir
                resolvedPath = path.resolve(projectDir, targetPath);
            }

            const normalizedResolvedPath = resolvedPath.toLowerCase();

            // Check if the resolved path is outside the workspace
            if (!normalizedResolvedPath.startsWith(normalizedProjectDir)) {
                const response = {
                    hookSpecificOutput: {
                        hookEventName: "PreToolUse",
                        permissionDecision: "ask",
                        permissionDecisionReason: `NAVIGATING OUTSIDE WORKSPACE

You are attempting to navigate outside the current workspace directory.

Current workspace: ${projectDir}
Target directory:  ${resolvedPath}

Do you want to allow this navigation?

Command: ${command}`
                    }
                };

                console.log(JSON.stringify(response));
                process.exit(0);
            }
        } catch (error) {
            // If path resolution fails, ask for confirmation to be safe
            const response = {
                hookSpecificOutput: {
                    hookEventName: "PreToolUse",
                    permissionDecision: "ask",
                    permissionDecisionReason: `UNCERTAIN PATH NAVIGATION

Unable to verify if the target path is within the workspace.

Current workspace: ${projectDir}
Target path: ${targetPath}

Do you want to allow this navigation?

Command: ${command}`
                }
            };

            console.log(JSON.stringify(response));
            process.exit(0);
        }
    }

    process.exit(0);
    // // Allow the command (no cd detected or cd within workspace)
    // const response = {
    //     hookSpecificOutput: {
    //         hookEventName: "PreToolUse",
    //         permissionDecision: "allow",
    //     }
    // };
    // console.log(JSON.stringify(response));
    // process.exit(0);
});
