const fs = require('fs');
const content = fs.readFileSync('c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html', 'utf-8');

const tables = {};
function addCol(table, col) {
    if (!tables[table]) tables[table] = new Set();
    if (col && col !== '*') tables[table].add(col);
}

// match .from('table') followed by anything until next .from or end
const tableRegex = /\.from\(['"]([^'"]+)['"]\)([\s\S]*?)(?=\.from|\Z)/g;
let match;
while ((match = tableRegex.exec(content)) !== null) {
    const table = match[1];
    const ops = match[2];

    const selectRegex = /\.select\(['"]([^'"]+)['"]\)/g;
    let sm;
    while ((sm = selectRegex.exec(ops)) !== null) {
        sm[1].split(',').forEach(c => addCol(table, c.trim()));
    }

    const eqRegex = /\.eq\(['"]([^'"]+)['"]/g;
    let em;
    while ((em = eqRegex.exec(ops)) !== null) {
        addCol(table, em[1]);
    }

    const payloadRegex = /\.(?:insert|update|upsert)\(\s*({[^}]+})\s*\)/g;
    let pm;
    while ((pm = payloadRegex.exec(ops)) !== null) {
        const payload = pm[1];
        const keyRegex = /['"]?([a-zA-Z0-9_]+)['"]?\s*:/g;
        let km;
        while ((km = keyRegex.exec(payload)) !== null) {
            addCol(table, km[1]);
        }
    }
}

try {
    const content2 = fs.readFileSync('c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/verify.html', 'utf-8');
    let match2;
    while ((match2 = tableRegex.exec(content2)) !== null) {
        const table = match2[1];
        const ops = match2[2];
        const selectRegex = /\.select\(['"]([^'"]+)['"]\)/g;
        let sm;
        while ((sm = selectRegex.exec(ops)) !== null) {
            sm[1].split(',').forEach(c => addCol(table, c.trim()));
        }
        const eqRegex = /\.eq\(['"]([^'"]+)['"]/g;
        let em;
        while ((em = eqRegex.exec(ops)) !== null) {
            addCol(table, em[1]);
        }
    }
} catch (e) {}

const res = {};
for (const t in tables) {
    res[t] = Array.from(tables[t]);
}
console.log(JSON.stringify(res, null, 2));
