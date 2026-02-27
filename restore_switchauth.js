const fs = require('fs');
const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

const switchAuthFunc = `
        window.switchAuth = (role) => {
            const isStudent = role === 'student';
            
            // Tab Styling
            $('#tab-student').toggleClass('bg-white dark:bg-[#1e293b] shadow-sm text-indigo-600 dark:text-indigo-400', isStudent)
                            .toggleClass('text-slate-500 hover:bg-slate-200 dark:hover:bg-slate-800', !isStudent);
            
            $('#tab-admin').toggleClass('bg-white dark:bg-[#1e293b] shadow-sm text-indigo-600 dark:text-indigo-400', !isStudent)
                          .toggleClass('text-slate-500 hover:bg-slate-200 dark:hover:bg-slate-800', isStudent);

            // Form Fields State
            if (isStudent) {
                if ($('#auth-btn span').text() === 'Create Account') {
                    $('#name-field, #avatar-field').slideDown(200);
                }
                $('#toggle-auth-mode').show();
            } else {
                // Admin is login only
                $('#name-field, #avatar-field').slideUp(200);
                $('#toggle-auth-mode').hide();
                if (typeof customToggleMode === 'function' && $('#auth-btn span').text() === 'Create Account') {
                    customToggleMode(); 
                }
            }
        };

        window.handleAuthSubmit = async (e) => {`;

// Force replace
c = c.replace(/window\.handleAuthSubmit = async \(e\) => \{/g, switchAuthFunc);
fs.writeFileSync(f, c);
console.log("Forced switchAuth injection.");
