const { Client } = require('pg');
const fs = require('fs');

const connectionString = "postgresql://postgres.fnkctvhrilynnmphdxuo:Umerkot@123+@aws-1-ap-south-1.pooler.supabase.com:5432/postgres";

const tables = [
    'profiles', 'tasks', 'submissions', 'notices', 'resources', 
    'exam_results', 'exam_settings', 'arcade_config', 'user_achievements', 
    'user_arcade_progress', 'admin_chat_messages', 'feedback', 
    'game_scores', 'personal_storage', 'system_settings'
];

async function exportData() {
    const client = new Client({ connectionString });
    try {
        await client.connect();
        console.log("Connected to Supabase!");
        
        let output = "PRAGMA foreign_keys=OFF;\n\n";

        for (const table of tables) {
            console.log(`Exporting ${table}...`);
            const res = await client.query(`SELECT * FROM ${table}`);
            
            // Generate CREATE TABLE (simplified)
            if (res.fields.length > 0) {
                const cols = res.fields.map(f => `${f.name} TEXT`).join(', ');
                output += `CREATE TABLE IF NOT EXISTS ${table} (${cols});\n`;
                
                // Generate INSERTS
                for (const row of res.rows) {
                    const keys = Object.keys(row).join(', ');
                    const values = Object.values(row).map(v => {
                        if (v === null) return 'NULL';
                        if (typeof v === 'boolean') return v ? '1' : '0';
                        return `'${String(v).replace(/'/g, "''")}'`;
                    }).join(', ');
                    output += `INSERT INTO ${table} (${keys}) VALUES (${values});\n`;
                }
                output += "\n";
            }
        }

        fs.writeFileSync('turso_import.sql', output);
        console.log("Export complete! turso_import.sql is ready.");
    } catch (err) {
        console.error("Connection failed:", err.message);
    } finally {
        await client.end();
    }
}

exportData();
