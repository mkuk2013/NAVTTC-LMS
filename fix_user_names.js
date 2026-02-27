const fs = require('fs');

const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

c = c.replace(
    /window\.allUsersCache = users \|\| \[\]; \/\/ Cache users IMMEDIATELY after fetch/g,
    `if (users) { users.forEach(u => u.name = u.name || u.full_name || 'Student'); }
                window.allUsersCache = users || []; // Cache users IMMEDIATELY after fetch`
);

fs.writeFileSync(f, c);
console.log('Fixed undefined names in Admin Student List by mapping properties in fetchUsers.');
