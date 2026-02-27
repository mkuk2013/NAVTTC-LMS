const fs = require('fs');

const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

// Replace .select('name') with .select('full_name') globally in JS Supabase queries
// Sometimes it's select('id, name') or select('*') etc... 
// The safest way is to replace .select() arguments containing just 'name' or ', name' or 'name,'
// But since the schema has full_name, let's just replace all word boundary "name" inside .select( to "full_name" if referring to profiles

c = c.replace(/\.select\(['"]([^'"]*\b)name(\b[^'"]*)['"]\)/g, ".select('$1full_name$2')");

// We also need to map full_name -> name when saving userProfile for backwards comp
// We already did this in initDashboard, but let's check profile fetch which happens in handleUserSession
// Line 4630 approx: const { data: profile } = await client.from('profiles').select('*').eq('uid', user.id).maybeSingle();
// Since it's select('*'), the DB returns full_name, not name.
// Then line 4703 approx: userProfile = profile;
// Let's inject a fix to map full_name to name immediately after fetching!

const profileFetchRegex = /(const \{ data: profile, error: profileError \} = await \w+\.from\('profiles'\)[\s\S]*?if \(!profile\) \{)/;

c = c.replace(
    /if \(profile\) \{/g,
    "if (profile) {\n                        profile.name = profile.full_name || profile.name;"
);

// We should also replace the order('name') to order('full_name') just in case
c = c.replace(/\.order\(['"]name['"]/g, ".order('full_name'");

fs.writeFileSync(f, c);
console.log('Fixed schema column mismatches (name -> full_name) in JS.');
