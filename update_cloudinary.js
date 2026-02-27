const fs = require('fs');
const files = ['index.html'];

const NEW_CLOUD = "dwowte8ny";
const NEW_PRESET = "navttc-lms";

files.forEach(f => {
    try {
        let c = fs.readFileSync(f, 'utf8');
        // Replace CLOUD_NAME
        c = c.replace(/const\s+CLOUD_NAME\s*=\s*['"][^'"]+['"];?/g, `const CLOUD_NAME = "${NEW_CLOUD}";`);
        // Replace UPLOAD_PRESET
        c = c.replace(/const\s+UPLO_PRESET\s*=\s*['"][^'"]+['"];?/g, `const UPLO_PRESET = "${NEW_PRESET}";`);

        fs.writeFileSync(f, c);
        console.log('Updated ' + f);
    } catch (e) {
        console.error('Error on ' + f + ': ' + e.message);
    }
});
