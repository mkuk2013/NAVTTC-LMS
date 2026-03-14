const DB_CONFIG = {
    TURSO_URL: "https://navttclms-navttclms.aws-ap-south-1.turso.io",
    TURSO_TOKEN: "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3NzM0OTcxNTMsImlkIjoiMDE5Y2U4ODQtYjAwMS03ZjA0LTk0YTItODRiM2IwZjQ2MTZmIiwicmlkIjoiYzcxY2Y5NTMtYzYxNS00MTViLWFhMjgtYWJjNTA4MzExMDg4In0.CQDO5kgBDwGTazfx7VZAnNrHcw96cu6764oec0h_Hn_zlCrx03iYxNzuFsf6KvzAVg_I75Vl0cbGIS1m2S3pAA"
};

async function testTurso() {
    console.log("Testing Turso Connection (Standalone)...");
    try {
        const url = `${DB_CONFIG.TURSO_URL}/v2/pipeline`;
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${DB_CONFIG.TURSO_TOKEN}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                requests: [
                    { type: "execute", stmt: { sql: "SELECT name FROM sqlite_master WHERE type='table' LIMIT 5;" } },
                    { type: "close" }
                ]
            })
        });

        const result = await response.json();
        if (result.results && result.results[0].response.result) {
            console.log("Connection Successful!");
            console.log("Tables snapshot:", result.results[0].response.result.rows.map(r => r[0].value));
        } else {
            console.log("Connection failed or invalid response.", JSON.stringify(result, null, 2));
        }
    } catch (err) {
        console.error("Fetch Error:", err.message);
    }
}

testTurso();
