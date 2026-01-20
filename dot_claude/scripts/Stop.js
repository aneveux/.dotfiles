import path from 'path';
import fs from 'fs';
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

    // Prepare content to write with stdin, args and env
    const content = {
        timestamp: new Date().toISOString(),
        stdin: parsedStdin,
        args: args,
        env: Object.keys(env)
            .filter(key => key.startsWith('CLAUDE_'))
            .reduce((obj, key) => {
                obj[key] = env[key];
                return obj;
            }, {}),
    };

    // Write to project root (or use CLAUDE_PROJECT_DIR)
    const projectDir = env.CLAUDE_PROJECT_DIR || path.join(__dirname, '..', '..');
    fs.appendFileSync(
        path.join(projectDir, 'Stop.jsonl'),
        JSON.stringify(content, null, 2) + '\n'
    );

    // Output required JSON response to stdout
    // For Stop hooks, use root-level fields (NOT hookSpecificOutput)
    const response = {
        decision: "approve"
        // To block: { decision: "block", reason: "explanation of what work remains" }
    };
    console.log(JSON.stringify(response));

    process.exit(0);

    // Tip: use this hook to trigger Slash Commands (e.g. review, audit, integrate, etc.)
    // or any other automation you could think of.
    
    // Tip: you can use the content.stdin.session_id to identify the session that was stopped.
    // If you want to resume it after.
});
