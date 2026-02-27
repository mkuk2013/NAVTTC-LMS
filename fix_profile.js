const fs = require('fs');

const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

// 1. Fix initDashboard to check if userProfile exists to prevent crash
c = c.replace(
    /function initDashboard\(\) \{/g,
    `function initDashboard() {
            if (!userProfile) {
                console.error("Critical: initDashboard called but userProfile is null.");
                showToast("System failed to load user profile. Please try logging in again.", "error");
               return;
            }
            // Ensure backwards compatibility between name and full_name
            userProfile.name = userProfile.name || userProfile.full_name || 'User';
`
);

// 2. Fix the upsert in handleAuthSubmit from name to full_name
c = c.replace(
    /name:\s*name,/g,
    'full_name: name, name: name,'
);

fs.writeFileSync(f, c);
console.log('Fixed index.html profile references');
