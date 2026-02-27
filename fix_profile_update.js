const fs = require('fs');
const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

// Replace line 9171 approx: .update({ name: newName }) -> .update({ full_name: newName, name: newName })
c = c.replace(
    /\.update\(\{ name: newName \}\)/g,
    '.update({ full_name: newName, name: newName })'
);

// Replace line 10752 approx: .update({ name }).eq('uid', currentUser.id) -> .update({ full_name: name, name: name }).eq('uid', currentUser.id)
c = c.replace(
    /await client\.from\('profiles'\)\.update\(\{ name \}\)/g,
    "await client.from('profiles').update({ full_name: name, name: name })"
);

// Let's also double check `adminRenameStudent` or similar functions, the regex above should catch {.update({ name }), but not if it's newName}
// There's `.update({ name: newName })` which we caught above.
// Let's do a safe global regex for any remaining `{ name }` in an update call:
c = c.replace(
    /\.update\(\{ name \}\)/g,
    '.update({ full_name: name, name: name })'
);


fs.writeFileSync(f, c);
console.log("Successfully fixed profile name update logic.");
