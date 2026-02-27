const fs = require('fs');
const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
const lines = fs.readFileSync(f, 'utf8').split('\n');

for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.includes('profiles') && line.includes('name') && line.includes('update')) {
        console.log(`Line ${i}: ${line.trim()}`);
    }
}
