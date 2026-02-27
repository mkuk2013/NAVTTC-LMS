const fs = require('fs');
const files = ['index.html', 'verify.html', 'feedback.html', 'feedback_details.html'];

const NEW_KEY = "sb_publishable_q_jbUM95dckWS7YF1XSRgg_NvhZ4iyU";

files.forEach(f => {
    try {
        if (fs.existsSync(f)) {
            let c = fs.readFileSync(f, 'utf8');
            // Remove the wrongly added SUPABASE_ANON_KEY line if it's there
            c = c.replace(/const SUPABASE_ANON_KEY = ['"][^'"]+['"];?\n?/g, '');
            // Update the actual SUPABASE_KEY
            c = c.replace(/const SUPABASE_KEY = ['"][^'"]+['"];?/g, `const SUPABASE_KEY = "${NEW_KEY}";`);
            fs.writeFileSync(f, c);
            console.log('Fixed auth key in ' + f);
        }
    } catch (e) {
        console.error('Error on ' + f + ': ' + e.message);
    }
});
