
        (function () {
            function initResize() {
                const handle = document.getElementById('drag-handle');
                const editorContainer = document.getElementById('editor-container');
                const outputContainer = document.getElementById('output-container');

                if (!handle || !editorContainer || !outputContainer) return;

                let isDragging = false;
                let startY, startHeight;

                handle.addEventListener('mousedown', (e) => {
                    isDragging = true;
                    startY = e.clientY;
                    startHeight = editorContainer.getBoundingClientRect().height;

                    document.body.style.cursor = 'row-resize';
                    // Visual feedback
                    handle.classList.remove('bg-[#131417]');
                    handle.classList.add('bg-[#444857]');

                    // Disable iframe pointer events
                    const iframe = document.getElementById('code-preview');
                    if (iframe) iframe.style.pointerEvents = 'none';

                    e.preventDefault();
                });

                document.addEventListener('mousemove', (e) => {
                    if (!isDragging) return;

                    const container = editorContainer.parentElement;
                    const containerHeight = container.getBoundingClientRect().height;

                    const deltaY = e.clientY - startY;
                    const newHeight = startHeight + deltaY;

                    // Calculate percentage
                    let newHeightPercent = (newHeight / containerHeight) * 100;

                    // Constraints
                    if (newHeightPercent < 10) newHeightPercent = 10;
                    if (newHeightPercent > 90) newHeightPercent = 90;

                    editorContainer.style.height = `${newHeightPercent}%`;
                });

                document.addEventListener('mouseup', () => {
                    if (isDragging) {
                        isDragging = false;
                        document.body.style.cursor = '';
                        // Reset visual feedback
                        handle.classList.remove('bg-[#444857]');
                        handle.classList.add('bg-[#131417]');

                        const iframe = document.getElementById('code-preview');
                        if (iframe) iframe.style.pointerEvents = '';
                    }
                });
            }

            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', initResize);
            } else {
                initResize();
            }
        })();
    