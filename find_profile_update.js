const fs = require('fs');
const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
const lines = fs.readFileSync(f, 'utf8').split('\n');

for (let i = 0; i < lines.length; i++) {
    const line = lines[i].toLowerCase();
    if (line.includes('profiles') && (line.includes('update') || line.includes('upsert') || line.includes('set'))) {
        console.log(`Line ${i + 1}: ${lines[i].trim()}`);
    }
    if (line.includes('name:') && line.includes('update')) {
        console.log(`Line ${i + 1} (name update): ${lines[i].trim()}`);
    }
}
