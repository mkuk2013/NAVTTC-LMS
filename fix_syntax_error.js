const fs = require('fs');
const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

// The problematic block looks like:
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
                }
            } catch (err) {
*/

// Notice the double `} }` before `catch (err) {`.
// We just need to replace `}\n                }\n            } catch (err) {` with `\n                }\n            } catch (err) {`

c = c.replace(/                \}\n                \}\n            \} catch \(err\) \{/g, '                }\n            } catch (err) {');

fs.writeFileSync(f, c);
console.log("Fixed SyntaxError double brace.");
