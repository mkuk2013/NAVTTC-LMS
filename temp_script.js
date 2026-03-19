        // --- ENHANCED IN-LMS TASK EDITOR LOGIC (v2) ---
        let monacoEditor = null;
        let htmlModel = null, cssModel = null, jsModel = null;
        let currentEditingTaskId = null;
        let autosaveTimer = null;
        let activeTab = 'html';

        window.openTaskEditor = async (taskId, taskTitle, readOnly = false) => {
            console.log('Opening enhanced editor for task:', taskId, 'ReadOnly:', readOnly);
            currentEditingTaskId = taskId;
            document.getElementById('editor-task-title').innerText = taskTitle || 'Task Editor';
            const modal = document.getElementById('task-editor-modal');
            modal.classList.remove('hidden');
            modal.classList.add('flex');

            // Header UI based on readOnly
            const saveBtn = document.getElementById('save-task-btn');
            const uploadBtn = document.getElementById('upload-img-btn');
            if (saveBtn) saveBtn.style.display = readOnly ? 'none' : 'flex';
            if (uploadBtn) uploadBtn.style.display = readOnly ? 'none' : 'flex';

            if (!monacoEditor) {
                await initMonacoEditor();
                setTimeout(() => loadAndInitializeContent(readOnly), 800);
            } else {
                loadAndInitializeContent(readOnly);
            }

            if (window.lucide) lucide.createIcons({ root: modal });
        };

        async function loadAndInitializeContent(readOnly) {
            if (!monacoEditor) return;
            monacoEditor.updateOptions({ readOnly: readOnly });
            
            // 1. Try to load from localStorage (Autosave) if not admin/readOnly
            let content = null;
            if (!readOnly) {
                const draft = localStorage.getItem(`task_draft_${currentEditingTaskId}`);
                if (draft) {
                    try {
                        content = JSON.parse(draft);
                        console.log('Loaded from autosave.');
                    } catch (e) { }
                }
            }

            // 2. If no draft, fetch from DB
            if (!content) {
                try {
                    const { data } = await client
                        .from('submissions')
                        .select('content')
                        .eq('task_id', currentEditingTaskId)
                        .eq('student_id', currentUser.id)
                        .order('submitted_at', { ascending: false })
                        .limit(1)
                        .single();

                    if (data && data.content) {
                        try {
                            const parsed = JSON.parse(data.content);
                            if (parsed.type === 'editor') {
                                content = parsed;
                            } else {
                                content = { html: data.content, css: '', js: '' };
                            }
                        } catch (e) {
                            content = { html: data.content, css: '', js: '' };
                        }
                    }
                } catch (err) { console.log('No DB submission found.'); }
            }

            // 3. Defaults
            if (!content) {
                content = {
                    html: '<!-- Type your HTML here... -->\n\n<h1>Student Task</h1>\n<p>Add your code and see the preview on the right!</p>',
                    css: '/* Type your CSS here... */\nbody {\n  font-family: sans-serif;\n  padding: 20px;\n}\nh1 {\n  color: #4f46e5;\n}',
                    js: '// Type your JS here...\nconsole.log("Hello from Task Editor!");'
                };
            }

            // Update Models
            htmlModel.setValue(content.html || '');
            cssModel.setValue(content.css || '');
            jsModel.setValue(content.js || '');

            switchEditorTab('html');
            updatePreview();

            // Start Autosave Timer if not readOnly
            if (!readOnly) {
                if (autosaveTimer) clearInterval(autosaveTimer);
                autosaveTimer = setInterval(autosaveTask, 30000); // 30 seconds
            }
        }

        window.openAdminCodePreview = async (submissionId) => {
            const sub = window.allSubmissions.find(s => s.id === submissionId);
            if (!sub) return;

            const data = parseSubmission(sub.content);
            let content = null;
            if (data.type === 'editor') {
                content = data;
            } else {
                content = { html: sub.content, css: '', js: '' };
            }

            document.getElementById('editor-task-title').innerText = `Review: ${sub.task_title} (${sub.student_name})`;
            const modal = document.getElementById('task-editor-modal');
            modal.classList.remove('hidden');
            modal.classList.add('flex');

            // Hide buttons for admin
            if (document.getElementById('save-task-btn')) document.getElementById('save-task-btn').style.display = 'none';
            if (document.getElementById('upload-img-btn')) document.getElementById('upload-img-btn').style.display = 'none';

            if (!monacoEditor) {
                await initMonacoEditor();
                setTimeout(() => {
                    monacoEditor.updateOptions({ readOnly: true });
                    htmlModel.setValue(content.html || '');
                    cssModel.setValue(content.css || '');
                    jsModel.setValue(content.js || '');
                    switchEditorTab('html');
                    updatePreview();
                }, 800);
            } else {
                monacoEditor.updateOptions({ readOnly: true });
                htmlModel.setValue(content.html || '');
                cssModel.setValue(content.css || '');
                jsModel.setValue(content.js || '');
                switchEditorTab('html');
                updatePreview();
            }

            if (window.lucide) lucide.createIcons({ root: modal });
        };

        function initMonacoEditor() {
            return new Promise((resolve) => {
                require.config({ paths: { 'vs': 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.44.0/min/vs' } });
                require(['vs/editor/editor.main'], function () {
                    // Create Models
                    htmlModel = monaco.editor.createModel('', 'html');
                    cssModel = monaco.editor.createModel('', 'css');
                    jsModel = monaco.editor.createModel('', 'javascript');

                    monacoEditor = monaco.editor.create(document.getElementById('monaco-editor-container'), {
                        model: htmlModel,
                        theme: localStorage.getItem('theme') === 'dark' ? 'vs-dark' : 'vs',
                        fontSize: 14,
                        fontFamily: "'Courier New', monospace",
                        minimap: { enabled: true },
                        automaticLayout: true,
                        autoClosingBrackets: 'always',
                        autoClosingQuotes: 'always',
                        autoClosingTags: true,
                        formatOnPaste: true,
                        links: true,
                        lineNumbers: 'on',
                        roundedSelection: true,
                        cursorSmoothCaretAnimation: 'on'
                    });

                    // Update cursor position in UI
                    monacoEditor.onDidChangeCursorPosition((e) => {
                        document.getElementById('editor-cursor-pos').innerText = `Line ${e.position.lineNumber}, Column ${e.position.column}`;
                    });

                    // Live Preview on change
                    htmlModel.onDidChangeContent(() => updatePreview());
                    cssModel.onDidChangeContent(() => updatePreview());
                    jsModel.onDidChangeContent(() => updatePreview());

                    resolve();
                });
            });
        }

        window.switchEditorTab = (lang) => {
            if (!monacoEditor) return;
            activeTab = lang;
            
            // Update Models
            if (lang === 'html') monacoEditor.setModel(htmlModel);
            if (lang === 'css') monacoEditor.setModel(cssModel);
            if (lang === 'js') monacoEditor.setModel(jsModel);

            // Update UI
            ['html', 'css', 'js'].forEach(t => {
                const btn = document.getElementById(`tab-${t}`);
                if (t === lang) {
                    btn.classList.add('border-indigo-600', 'text-indigo-600', 'dark:text-indigo-400');
                    btn.classList.remove('border-transparent', 'text-slate-400');
                } else {
                    btn.classList.remove('border-indigo-600', 'text-indigo-600', 'dark:text-indigo-400');
                    btn.classList.add('border-transparent', 'text-slate-400');
                }
            });

            document.getElementById('editor-language').innerText = lang.toUpperCase();
        };

        function updatePreview() {
            if (!htmlModel || !cssModel || !jsModel) return;
            
            const html = htmlModel.getValue();
            const css = cssModel.getValue();
            const js = jsModel.getValue();

            const jsContent = '<script>' + js + '<' + '/script>';
            let combined = '<!DOCTYPE html><html><head><style>' + css + '</style></head>';
            combined += '<body>' + html + jsContent + '</body></html>';

            const iframe = document.getElementById('task-preview-iframe');
            if (!iframe) return;
            const doc = iframe.contentDocument || iframe.contentWindow.document;
            doc.open();
            doc.write(combined);
            doc.close();
        }

        function autosaveTask() {
            if (monacoEditor.getRawOptions().readOnly) return;
            if (!currentEditingTaskId) return;

            const draft = {
                type: 'editor',
                html: htmlModel.getValue(),
                css: cssModel.getValue(),
                js: jsModel.getValue(),
                updatedAt: new Date().toISOString()
            };

            localStorage.setItem(`task_draft_${currentEditingTaskId}`, JSON.stringify(draft));
            
            const statusText = document.getElementById('autosave-status');
            statusText.innerText = 'Autosave: Saved';
            statusText.classList.remove('opacity-70');
            statusText.classList.add('text-emerald-400');
            
            setTimeout(() => {
                statusText.innerText = 'Autosave: On';
                statusText.classList.add('opacity-70');
                statusText.classList.remove('text-emerald-400');
            }, 2000);
        }

        async function saveTaskSubmission() {
            if (!monacoEditor) return;
            
            const content = {
                type: 'editor',
                html: htmlModel.getValue(),
                css: cssModel.getValue(),
                js: jsModel.getValue()
            };
            
            Swal.fire({
                title: 'Submitting Task...',
                didOpen: () => { Swal.showLoading(); },
                allowOutsideClick: false
            });

            try {
                const { error } = await client.from('submissions').upsert({
                    id: crypto.randomUUID(), 
                    task_id: currentEditingTaskId,
                    student_id: currentUser.id,
                    student_name: userProfile.full_name,
                    content: JSON.stringify(content),
                    status: 'submitted',
                    submitted_at: new Date().toISOString()
                });

                if (error) throw error;

                // Clear draft on successful submission
                localStorage.removeItem(`task_draft_${currentEditingTaskId}`);

                Swal.fire({
                    title: 'Task Submitted! 🚀',
                    text: 'Your task has been successfully saved in the LMS.',
                    icon: 'success',
                    timer: 3000,
                    showConfirmButton: false
                });
                closeTaskEditor();
            } catch (err) {
                console.error("Save Error:", err);
                Swal.fire('Error', 'Failed to submit task.', 'error');
            }
        }

        window.viewTaskDetailsFromEditor = () => {
            if (typeof window.openDetail === 'function') {
                window.openDetail(currentEditingTaskId);
            } else {
                Swal.fire('Info', 'Task details loading logic unavailable.', 'info');
            }
        };

        function closeTaskEditor() {
            if (autosaveTimer) clearInterval(autosaveTimer);
            autosaveTask(); // Final autosave on close
            document.getElementById('task-editor-modal').classList.add('hidden');
            document.getElementById('task-editor-modal').classList.remove('flex');
        }

        window.uploadEditorImage = async () => {
            const { value: file } = await Swal.fire({
                title: 'Select Image',
                input: 'file',
                inputAttributes: { 'accept': 'image/*', 'aria-label': 'Upload image' }
            });

            if (file) {
                const reader = new FileReader();
                reader.onload = async (e) => {
                    Swal.fire({ title: 'Uploading...', didOpen: () => { Swal.showLoading(); } });
                    try {
                        const CLOUD_NAME = "dwowte8ny";
                        const UPLO_PRESET = "navttc-lms";
                        const formData = new FormData();
                        formData.append('file', file);
                        formData.append('upload_preset', UPLO_PRESET);

                        const response = await fetch(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`, { method: 'POST', body: formData });
                        const data = await response.json();
                        if (data.error) throw new Error(data.error.message);

                        const imgTag = `\n<img src="${data.secure_url}" alt="Task Image" style="max-width: 100%; border-radius: 8px; margin: 10px 0;">\n`;
                        
                        // Insert into active model
                        const pos = monacoEditor.getPosition();
                        const model = monacoEditor.getModel();
                        monacoEditor.executeEdits('', [{
                            range: new monaco.Range(pos.lineNumber, pos.column, pos.lineNumber, pos.column),
                            text: imgTag
                        }]);

                        Swal.fire('Uploaded!', 'Image added to code.', 'success');
                    } catch (err) { Swal.fire('Error', 'Upload failed.', 'error'); }
                };
                reader.readAsDataURL(file);
            }
        };
