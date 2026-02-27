const fs = require('fs');
const files = ['index.html', 'verify.html', 'feedback.html', 'feedback_details.html'];

files.forEach(f => {
    try {
        if (fs.existsSync(f)) {
            let c = fs.readFileSync(f, 'utf8');
            c = c.replace(/const SUPABASE_ANON_KEY = /g, 'const SUPABASE_KEY = ');
            fs.writeFileSync(f, c);
            console.log('Fixed auth key variable in ' + f);
        }
    } catch (e) {
        console.error('Error on ' + f + ': ' + e.message);
    }
});
