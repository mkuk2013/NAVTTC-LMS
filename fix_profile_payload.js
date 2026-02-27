const fs = require('fs');
const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

// Replace { full_name: name, name: name } with { full_name: name } globally.
c = c.replace(/\{ full_name: newName, name: newName \}/g, '{ full_name: newName }');
c = c.replace(/\{ full_name: name, name: name \}/g, '{ full_name: name }');

fs.writeFileSync(f, c);
console.log("Successfully removed 'name' column from update payloads to fix schema error.");
