const fs = require('fs');

const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
const lines = fs.readFileSync(f, 'utf8').split('\n');

for (let i = 0; i < lines.length; i++) {
    if (lines[i].toLowerCase().includes('navttc')) {
        console.log(`Line ${i + 1}: ${lines[i].trim()}`);
    }
}
