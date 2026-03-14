const fs = require('fs');
const path = require('path');

const inputPath = path.join(__dirname, 'navigation_db_dump.sql');
const schemaPath = path.join(__dirname, 'turso_schema.sql');
const dataPath = path.join(__dirname, 'turso_data.sql');

const postgresSql = fs.readFileSync(inputPath, 'utf8');
const lines = postgresSql.split('\n');

const targetTables = [
    'profiles', 'tasks', 'submissions', 'notices', 'resources', 
    'exam_results', 'exam_settings', 'arcade_config', 'user_achievements', 
    'user_arcade_progress', 'admin_chat_messages', 'feedback', 
    'game_scores', 'personal_storage', 'system_settings'
];

let createStatements = [];
let insertStatements = [];
let currentStatement = '';
let inTargetContext = false;
let currentTableName = '';

for (let line of lines) {
    let trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('--')) continue;

    if (trimmed.startsWith('CREATE TABLE ') || trimmed.startsWith('INSERT INTO ')) {
        const tableMatch = trimmed.match(/(?:CREATE TABLE|INSERT INTO)\s+(?:[a-zA-Z0-9_"]+\.)?([a-zA-Z0-9_"]+)/);
        if (tableMatch) {
            currentTableName = tableMatch[1].replace(/"/g, '');
            inTargetContext = targetTables.includes(currentTableName);
        }
        currentStatement = line;
    } else if (currentStatement) {
        currentStatement += ' ' + line;
    }

    if (trimmed.endsWith(';') && currentStatement) {
        if (inTargetContext) {
            let processed = currentStatement;
            
            if (processed.startsWith('CREATE TABLE')) {
                processed = processed.replace(/CREATE TABLE\s+(?:[a-zA-Z0-9_"]+\.)?([a-zA-Z0-9_"]+)/i, 'CREATE TABLE IF NOT EXISTS $1');
                processed = processed.replace(/"/g, '');

                const startParen = processed.indexOf('(');
                const endParen = processed.lastIndexOf(')');
                
                if (startParen !== -1 && endParen !== -1) {
                    const innerContent = processed.substring(startParen + 1, endParen);
                    
                    let parts = [];
                    let depth = 0;
                    let start = 0;
                    for (let i = 0; i < innerContent.length; i++) {
                        if (innerContent[i] === '(') depth++;
                        if (innerContent[i] === ')') depth--;
                        if (innerContent[i] === ',' && depth === 0) {
                            parts.push(innerContent.substring(start, i));
                            start = i + 1;
                        }
                    }
                    parts.push(innerContent.substring(start));

                    const cleanParts = [];
                    for (let p of parts) {
                        let pt = p.trim();
                        if (!pt) continue;

                        const upperPt = pt.toUpperCase();
                        if (upperPt.startsWith('CONSTRAINT') || upperPt.startsWith('CHECK') || upperPt.startsWith('PRIMARY KEY') || upperPt.startsWith('FOREIGN KEY') || upperPt.startsWith('UNIQUE')) {
                            continue;
                        }

                        pt = pt.replace(/uuid/gi, 'TEXT');
                        pt = pt.replace(/timestamp( with time zone| without time zone)?/gi, 'TEXT');
                        pt = pt.replace(/jsonb?/gi, 'TEXT');
                        pt = pt.replace(/boolean/gi, 'INTEGER');
                        pt = pt.replace(/bigint/gi, 'INTEGER');
                        pt = pt.replace(/smallint/gi, 'INTEGER');
                        pt = pt.replace(/integer/gi, 'INTEGER');
                        pt = pt.replace(/character varying(\(\d+\))?/gi, 'TEXT');
                        pt = pt.replace(/text\[\]/gi, 'TEXT');
                        pt = pt.replace(/::[a-z0-9_.]+/gi, ''); 
                        pt = pt.replace(/DEFAULT .+?\(.*?\)/gi, '');
                        pt = pt.replace(/DEFAULT true/gi, 'DEFAULT 1');
                        pt = pt.replace(/DEFAULT false/gi, 'DEFAULT 0');
                        
                        if (pt.includes('ARRAY[')) continue;

                        if (pt.toLowerCase().startsWith('id text')) {
                            pt = 'id TEXT PRIMARY KEY';
                        }

                        if (pt.match(/^[a-z0-9_]+\s+[a-z0-9_]+/i)) {
                            cleanParts.push(pt);
                        }
                    }

                    processed = `CREATE TABLE IF NOT EXISTS ${currentTableName} (\n  ${cleanParts.join(',\n  ')}\n);`;
                    createStatements.push(processed);
                }
            } else if (processed.startsWith('INSERT INTO')) {
                processed = processed.replace(/INSERT INTO\s+(?:[a-zA-Z0-9_"]+\.)?([a-zA-Z0-9_"]+)/i, 'INSERT INTO $1');
                processed = processed.replace(/"/g, ''); 
                processed = processed.replace(/, true/g, ', 1');
                processed = processed.replace(/, false/g, ', 0');
                processed = processed.replace(/\(true/g, '(1');
                processed = processed.replace(/\(false/g, '(0');
                insertStatements.push(processed);
            }
        }
        currentStatement = '';
        inTargetContext = false;
    }
}

fs.writeFileSync(schemaPath, 'PRAGMA foreign_keys=OFF;\n\n' + createStatements.join('\n\n'));
fs.writeFileSync(dataPath, 'PRAGMA foreign_keys=OFF;\n\n' + insertStatements.join('\n'));

console.log('Conversion complete: turso_schema.sql and turso_data.sql created.');
