const fs = require('fs');

const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

// The line is: setTimeout(() => reject(new Error("Session Check Timeout")), 5000)
// We will increase the timeout to 15000ms (15 seconds) to give Supabase auth ample time.
c = c.replace(
    /setTimeout\(\(\) => reject\(new Error\("Session Check Timeout"\)\), 5000\)/g,
    'setTimeout(() => reject(new Error("Session Check Timeout")), 15000)'
);

// Second Error mentioned in user prompt: profile fetch timeout
// Network Timeout: Profile fetch took too long.
// The line is: setTimeout(() => { if (!loadedFromCache) reject(new Error("Network Timeout: Profile fetch took too long. Please check your internet connection.")); }, 8000)
c = c.replace(
    /setTimeout\(\(\) => \{\s*if \(\!loadedFromCache\) reject\(new Error\("Network Timeout: Profile fetch took too long\. Please check your internet connection\."\)\);\s*\}, 8000\)/g,
    'setTimeout(() => { if (!loadedFromCache) reject(new Error("Network Timeout: Profile fetch took too long. Please check your internet connection.")); }, 20000)'
);

fs.writeFileSync(f, c);
console.log('Increased session and profile fetch timeouts in index.html to prevent false failures.');
