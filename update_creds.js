const fs = require('fs');
const files = ['index.html', 'verify.html', 'feedback.html', 'feedback_details.html'];

const NEW_URL = "https://fnkctvhrilynnmphdxuo.supabase.co";
const NEW_KEY = "sb_publishable_q_jbUM95dckWS7YF1XSRgg_NvhZ4iyU";

files.forEach(f => {
    try {
        let c = fs.readFileSync(f, 'utf8');
        c = c.replace(/const SUPABASE_URL = ['"][^'"]+['"];?/g, `const SUPABASE_URL = "${NEW_URL}";`);
        c = c.replace(/const SUPABASE_ANON_KEY = ['"][^'"]+['"];?/g, `const SUPABASE_ANON_KEY = "${NEW_KEY}";`);
        fs.writeFileSync(f, c);
        console.log('Updated ' + f);
    } catch (e) {
        console.error('Error on ' + f + ': ' + e.message);
    }
});
