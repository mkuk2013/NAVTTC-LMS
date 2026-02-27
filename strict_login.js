const fs = require('fs');
const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

// The code block to replace around line 5780:
/*
                } else {
                    // Standard Login
                    const { data, error } = await client.auth.signInWithPassword({ email, password: pass });
                    if (error) throw error;

                    // EXPLICIT MODE: Immediately handle the user session
                    // This prevents sticking on "Verifying..." if onAuthStateChange is slow/missed.
                    if (data?.user) {
                        await handleUserSession(data.user);
                    }
                }
*/

const searchStr = `                } else {
                    // Standard Login
                    const { data, error } = await client.auth.signInWithPassword({ email, password: pass });
                    if (error) throw error;

                    // EXPLICIT MODE: Immediately handle the user session
                    // This prevents sticking on "Verifying..." if onAuthStateChange is slow/missed.
                    if (data?.user) {
                        await handleUserSession(data.user);
                    }
                }`;

const replaceStr = `                } else {
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
                }`;

if (c.includes(searchStr)) {
    c = c.replace(searchStr, replaceStr);

    // Also remove the auto-switching from handleUserSession to prevent bypass completely if needed,
    // but the F5 refresh logic is actually useful. Let's just comment out the auto-switch from handleUserSession
    // so it doesn't accidentally log them in if they somehow bypass the form (e.g. clicking tab fast).
    // Actually, no, if we block it at login, they never get a session. F5 refresh is fine.

    fs.writeFileSync(f, c);
    console.log("Strict Form Login Validation Added.");
} else {
    console.log("String not found. Let's use Regex for handleAuthSubmit standard login.");

    const regexSearch = /\} else \{\s*\/\/ Standard Login\s*const \{ data, error \} = await client\.auth\.signInWithPassword\(\{ email, password: pass \}\);\s*if \(error\) throw error;\s*\/\/ EXPLICIT MODE[\s\S]*?await handleUserSession\(data\.user\);\s*\}/;

    if (regexSearch.test(c)) {
        c = c.replace(regexSearch, replaceStr);
        fs.writeFileSync(f, c);
        console.log("Regex standard login string replaced.");
    } else {
        console.log("Regex also failed to find the block!");
    }
}
