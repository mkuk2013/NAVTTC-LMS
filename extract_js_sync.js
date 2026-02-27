const fs = require('fs');
const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
const html = fs.readFileSync(f, 'utf8');

// Extract the main script block
const match = html.match(/<script>([\s\S]*?)<\/script>/);
if (match) {
    fs.writeFileSync('c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/temp_script.js', match[1]);
    console.log("Extracted script to temp_script.js");
} else {
    console.log("No main <script> tag found.");
}
