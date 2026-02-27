const fs = require('fs');

const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

// The problematic line is around 9119:
// onclick="loadUserFiles('${id}', '${student.name.replace(/'/g, "\\'")}')"
// and 9130: ${student.name}

c = c.replace(
    /\$\{student\.name\.replace\(/g,
    '${(student.name || student.full_name || "Unknown").replace('
);

c = c.replace(
    /        \$\{student\.name\}/g,
    '        ${student.name || student.full_name || "Unknown"}'
);

fs.writeFileSync(f, c);
console.log('Fixed undefined replace error in renderStudentDirectory');
