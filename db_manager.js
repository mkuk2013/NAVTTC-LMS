/**
 * DB Manager - Universal Proxy Failover (Supabase + Turso)
 * This version uses a dynamic Proxy to support ALL Supabase methods automatically,
 * while still capturing important ones for Turso failover.
 */

(function() {
    const DB_CONFIG = {
        SUPABASE_URL: "https://fnkctvhrilynnmphdxuo.supabase.co",
        SUPABASE_KEY: "sb_publishable_q_jbUM95dckWS7YF1XSRgg_NvhZ4iyU",
        TURSO_URL: "https://navttclms-navttclms.aws-ap-south-1.turso.io",
        TURSO_TOKEN: "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3NzM0OTcxNTMsImlkIjoiMDE5Y2U4ODQtYjAwMS03ZjA0LTk0YTItODRiM2IwZjQ2MTZmIiwicmlkIjoiYzcxY2Y5NTMtYzYxNS00MTViLWFhMjgtYWJjNTA4MzExMDg4In0.CQDO5kgBDwGTazfx7VZAnNrHcw96cu6764oec0h_Hn_zlCrx03iYxNzuFsf6KvzAVg_I75Vl0cbGIS1m2S3pAA"
    };

    if (typeof supabase === 'undefined') {
        console.error("[DB Manager] Supabase library not found.");
        return;
    }

    const originalCreateClient = supabase.createClient;

    supabase.createClient = function(url, key) {
        const realClient = originalCreateClient(url, key);
        return new Proxy(realClient, {
            get(target, prop) {
                if (prop === 'from') {
                    return (table) => {
                        const builder = new SmartQueryBuilder(table, target.from(table));
                        const proxy = new Proxy(builder, {
                            get(bTarget, bProp) {
                                if (bProp in bTarget) return bTarget[bProp];
                                if (bProp === 'then') return bTarget.then.bind(bTarget);
                                
                                return (...args) => {
                                    bTarget.realQuery = bTarget.realQuery[bProp](...args);
                                    bTarget.captureCall(bProp, args);
                                    return proxy; // Chaining
                                };
                            }
                        });
                        return proxy;
                    };
                }
                return target[prop];
            }
        });
    };

    class SmartQueryBuilder {
        constructor(table, realQuery) {
            this.table = table;
            this.realQuery = realQuery;
            this.calls = [];
            this.operation = 'SELECT';
            this.payload = null;
            this.isSingle = false;
        }

        captureCall(method, args) {
            this.calls.push({ method, args });
            if (method === 'insert' || method === 'upsert') { this.operation = 'INSERT'; this.payload = args[0]; }
            if (method === 'update') { this.operation = 'UPDATE'; this.payload = args[0]; }
            if (method === 'delete') { this.operation = 'DELETE'; }
            if (method === 'single' || method === 'maybeSingle') { this.isSingle = true; }
        }

        async then(onFulfilled, onRejected) {
            try {
                const result = await this.realQuery;
                if (this.operation !== 'SELECT' && !result.error) {
                    this.mirrorToTurso();
                }
                if (result.error) throw result.error;
                return onFulfilled ? onFulfilled(result) : result;
            } catch (err) {
                console.warn(`[DB Manager] Supabase Fail: ${err.message}. Switching to Turso...`);
                let res;
                if (this.operation === 'SELECT') res = await this.executeTursoRead();
                else res = await this.executeTursoWrite();

                if (this.isSingle && res.data && Array.isArray(res.data)) res.data = res.data[0] || null;
                return onFulfilled ? onFulfilled(res) : res;
            }
        }

        async mirrorToTurso() {
            try { await this.executeTursoWrite(); } catch (e) { console.error("[DB Manager] Mirroring failed."); }
        }

        async executeTursoRead() {
            let sql = `SELECT * FROM ${this.table}`;
            const selects = this.calls.find(c => c.method === 'select');
            if (selects && selects.args[0] && selects.args[0] !== '*') sql = `SELECT ${selects.args[0]} FROM ${this.table}`;

            const wheres = [];
            this.calls.forEach(c => {
                const [col, val] = c.args;
                if (c.method === 'eq') wheres.push(`${col} = ${this.val(val)}`);
                if (c.method === 'neq') wheres.push(`${col} != ${this.val(val)}`);
                if (c.method === 'gt') wheres.push(`${col} > ${this.val(val)}`);
                if (c.method === 'lt') wheres.push(`${col} < ${this.val(val)}`);
                if (c.method === 'gte') wheres.push(`${col} >= ${this.val(val)}`);
                if (c.method === 'lte') wheres.push(`${col} <= ${this.val(val)}`);
                if (c.method === 'is') wheres.push(`${col} IS ${val === null ? 'NULL' : this.val(val)}`);
                if (c.method === 'in' && Array.isArray(val)) {
                    const list = val.map(v => this.val(v)).join(', ');
                    wheres.push(`${col} IN (${list})`);
                }
                if (c.method === 'match') Object.entries(col).forEach(([k,v]) => wheres.push(`${k} = ${this.val(v)}`));
            });

            if (wheres.length > 0) sql += ` WHERE ${wheres.join(' AND ')}`;

            const order = this.calls.find(c => c.method === 'order');
            if (order) sql += ` ORDER BY ${order.args[0]} ${order.args[1]?.ascending === false ? 'DESC' : 'ASC'}`;

            const limit = this.calls.find(c => c.method === 'limit');
            if (limit) sql += ` LIMIT ${limit.args[0]}`;
            else if (this.isSingle) sql += ` LIMIT 1`;

            return await this.fetchTurso(sql);
        }

        async executeTursoWrite() {
            let sql = '';
            const data = Array.isArray(this.payload) ? this.payload[0] : this.payload;
            
            if (this.operation === 'INSERT') {
                const cols = Object.keys(data).join(', ');
                const vals = Object.values(data).map(v => this.val(v)).join(', ');
                sql = `INSERT OR REPLACE INTO ${this.table} (${cols}) VALUES (${vals})`;
            } else if (this.operation === 'UPDATE') {
                const set = Object.entries(data).map(([k,v]) => `${k} = ${this.val(v)}`).join(', ');
                sql = `UPDATE ${this.table} SET ${set}`;
                const wheres = this.getWheres();
                if (wheres) sql += ` WHERE ${wheres}`;
            } else if (this.operation === 'DELETE') {
                sql = `DELETE FROM ${this.table}`;
                const wheres = this.getWheres();
                if (wheres) sql += ` WHERE ${wheres}`;
            }

            if (!sql) return { data: null, error: null };
            return await this.fetchTurso(sql);
        }

        getWheres() {
            const wheres = [];
            this.calls.forEach(c => {
                if (c.method === 'eq') wheres.push(`${c.args[0]} = ${this.val(c.args[1])}`);
                if (c.method === 'match') Object.entries(c.args[0]).forEach(([k,v]) => wheres.push(`${k} = ${this.val(v)}`));
            });
            return wheres.length > 0 ? wheres.join(' AND ') : null;
        }

        val(v) {
            if (v === null || v === undefined) return 'NULL';
            if (typeof v === 'boolean') return v ? '1' : '0';
            if (typeof v === 'number') return v;
            if (typeof v === 'object') return `'${JSON.stringify(v).replace(/'/g, "''")}'`;
            return `'${String(v).replace(/'/g, "''")}'`;
        }

        async fetchTurso(sql) {
            try {
                const response = await fetch(`${DB_CONFIG.TURSO_URL}/v2/pipeline`, {
                    method: 'POST',
                    headers: { 'Authorization': `Bearer ${DB_CONFIG.TURSO_TOKEN}`, 'Content-Type': 'application/json' },
                    body: JSON.stringify({ requests: [ { type: "execute", stmt: { sql: sql } }, { type: "close" } ] })
                });
                const result = await response.json();
                return { data: this.transform(result), error: null };
            } catch (err) { return { data: null, error: err }; }
        }

        transform(res) {
            if (!res.results || !res.results[0].response.result) return [];
            const result = res.results[0].response.result;
            if (!result.cols) return [];
            const columns = result.cols.map(c => c.name);
            return result.rows.map(row => {
                const obj = {};
                row.forEach((val, i) => { obj[columns[i]] = val.value; });
                return obj;
            });
        }
    }

    console.log("[DB Manager] Universal Failover Proxy (v2.1) Active.");
})();
