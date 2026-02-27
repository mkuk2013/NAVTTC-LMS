const fs = require('fs');
const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

// The exact block around line 5811:
/*
                } else {
                    // Standard Login
                    const intendedRole = $('#tab-student').hasClass('bg-white') ? 'student' : 'admin';
                    
                    const { data, error } = await client.auth.signInWithPassword({ email, password: pass });
                    if (error) throw error;

                    if (data?.user) {
                        // Strict Role Validation
                        const { data: profile } = await client.from('profiles').select('role').eq('uid', data.user.id).single();
                        if (profile && profile.role !== intendedRole) {
                            await client.auth.signOut();
                            throw new Error('Access Denied: You cannot log into the ' + intendedRole.toUpperCase() + ' portal with a ' + profile.role.toUpperCase() + ' account. Please use the correct login tab.');
                        }
                        
                        // EXPLICIT MODE: Immediately handle the user session
                        // This prevents sticking on "Verifying..." if onAuthStateChange is slow/missed.
                        await handleUserSession(data.user);
                    }
                }
*/

// Let's replace just the inner part of // Standard Login

c = c.replace(
    /const intendedRole = \$\('#tab-student'\)\.hasClass\('bg-white'\) \? 'student' : 'admin';([\s\S]*?)await handleUserSession\(data\.user\);\n                    \}/,
    `const intendedRole = $('#tab-student').hasClass('bg-white') ? 'student' : 'admin';
                    
                    window.isRoleValidating = true;
                    const { data, error } = await client.auth.signInWithPassword({ email, password: pass });
                    if (error) { window.isRoleValidating = false; throw error; }

                    if (data?.user) {
                        const { data: profile } = await client.from('profiles').select('role').eq('uid', data.user.id).single();
                        if (profile && profile.role !== intendedRole) {
                            await client.auth.signOut();
                            window.isRoleValidating = false;
                            throw new Error('Access Denied: You cannot log into the ' + intendedRole.toUpperCase() + ' portal with a ' + profile.role.toUpperCase() + ' account. Please use the correct login tab.');
                        }
                        
                        window.isRoleValidating = false;
                        await handleUserSession(data.user);
                    }`
);

// We need to inject `if (window.isRoleValidating) return;` into `onAuthStateChange`
if (c.includes("client.auth.onAuthStateChange(async (event, session) => {")) {
    c = c.replace(
        "client.auth.onAuthStateChange(async (event, session) => {",
        "client.auth.onAuthStateChange(async (event, session) => {\n            if (window.isRoleValidating) return; // Wait for manual role validation before firing UI changes"
    );
    console.log("Injected Role Validating logic.");
} else {
    // If it's written differently:
    c = c.replace(
        "client.auth.onAuthStateChange((event, session) => {",
        "client.auth.onAuthStateChange(async (event, session) => {\n            if (window.isRoleValidating) return; // Wait for manual role validation before firing UI changes"
    );
    console.log("Injected Role Validating logic (non-async match).");
}

fs.writeFileSync(f, c);
console.log("Saved.");
