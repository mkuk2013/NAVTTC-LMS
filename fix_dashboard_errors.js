const fs = require('fs');
const files = ['index.html'];

files.forEach(f => {
    try {
        let c = fs.readFileSync(f, 'utf8');

        // Fix renderUsers toLowerCase error (Line ~7437)
        // Original: users.filter(u => u.role === 'student' && (u.name.toLowerCase().includes(query) || (u.email && u.email.toLowerCase().includes(query))))
        c = c.replace(
            /u\.name\.toLowerCase\(\)/g,
            '(u.name || u.full_name || "").toLowerCase()'
        );

        // Fix 400 Bad request on fetchFeedback (Line ~7610)
        // Original: .order('created_at', { ascending: false });
        // The feedback table has 'submitted_at' instead of 'created_at'.
        // To be safe, we'll replace the specific order clause in fetchFeedback logic
        // It's line 7610: .order('created_at', { ascending: false });

        // Let's do a targeted replace for fetchFeedback specifically.
        const feedbackFuncRegex = /async function fetchFeedback\(\) \{[\s\S]*?client\.from\('feedback'\)[\s\S]*?\.order\('created_at'/;
        if (feedbackFuncRegex.test(c)) {
            c = c.replace(
                /(client\.from\('feedback'\)[\s\S]*?)\.order\('created_at'/g,
                "$1.order('submitted_at'"
            );
        }

        // While we're at it, check if exam_settings has the same issue.
        // exam_settings has `updated_at` not `created_at` in schema.
        if (c.includes(".from('exam_settings').select('*').order('created_at'")) {
            c = c.replace(
                /\.from\('exam_settings'\)\.select\('\*'\)\.order\('created_at'/g,
                ".from('exam_settings').select('*').order('updated_at'"
            );
        }

        fs.writeFileSync(f, c);
        console.log('Fixed rendering and query errors in ' + f);
    } catch (e) {
        console.error('Error on ' + f + ': ' + e.message);
    }
});
