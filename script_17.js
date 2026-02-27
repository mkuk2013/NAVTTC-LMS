
        // GLOBAL ERROR HANDLER (Must be first)
        window.onerror = function (msg, url, line, col, error) {
            console.error("Global Error Caught:", msg, url, line, col, error);
            // If global loader is visible, hide it to prevent freeze
            var loader = document.getElementById('global-loader');
            if (loader && getComputedStyle(loader).display !== 'none') {
                console.warn("Error occurred while loader was visible. Force hiding loader.");
                loader.style.display = 'none';

                // Show auth if nothing else visible
                var dashboard = document.getElementById('dashboard-layout');
                if (dashboard && dashboard.classList.contains('hidden')) {
                    var auth = document.getElementById('auth-wrapper');
                    if (auth) auth.classList.remove('hidden');
                }
            }
        };

        // --- TEXT ENCODING UTILITIES ---
        // Helper to fix corrupted UTF-16 surrogates (Mojibake)
        window.fixEncoding = (str) => {
            if (!str) return str;

            let fixed = str;
            // console.log("FixEncoding Input:", str); // Debug

            // 1. Explicit Replacements for known patterns (based on user feedback)
            // Ø=ÜØ -> 📘 (Blue Book)
            fixed = fixed.replace(/Ø=ÜØ/g, '\uD83D\uDCD8');
            // Ø=ÜM -> 👍 (Thumbs Up)
            fixed = fixed.replace(/Ø=ÜM/g, '\uD83D\uDC4D');
            // Ø<ß  -> 🎓 (Graduation Cap)
            fixed = fixed.replace(/Ø<ß/g, '\uD83C\uDF93');

            // 2. Generic Regex for "Double-Encoded" Surrogates
            // Pattern: High(D8-DB) Byte2 Low(DC-DF) Byte4
            fixed = fixed.replace(/([\u00D8-\u00DB])([\s\S])([\u00DC-\u00DF])([\s\S])/g, (match, h1, h2, l1, l2) => {
                try {
                    const high = (h1.charCodeAt(0) << 8) | h2.charCodeAt(0);
                    const low = (l1.charCodeAt(0) << 8) | l2.charCodeAt(0);
                    if (high >= 0xD800 && high <= 0xDBFF && low >= 0xDC00 && low <= 0xDFFF) {
                        return String.fromCharCode(high, low);
                    }
                    return match;
                } catch (e) {
                    return match;
                }
            });

            return fixed;
        };

        // Helper to render text with emojis as an image (for PDF)
        window.textToImage = (text, fontSize, color, maxWidth, scaleFactor = 4, fontWeight = 'bold') => {
            const canvas = document.createElement('canvas');
            const ctx = canvas.getContext('2d');

            const font = `${fontWeight} ${fontSize}px "Segoe UI Emoji", "Apple Color Emoji", "Noto Color Emoji", sans-serif`;
            ctx.font = font;

            // Text Wrapping Logic
            const words = text.split(' ');
            let lines = [];
            let currentLine = words[0];

            if (maxWidth) {
                for (let i = 1; i < words.length; i++) {
                    const word = words[i];
                    const width = ctx.measureText(currentLine + " " + word).width;
                    if (width < maxWidth) {
                        currentLine += " " + word;
                    } else {
                        lines.push(currentLine);
                        currentLine = word;
                    }
                }
                lines.push(currentLine);
            } else {
                lines.push(text);
            }

            // Calculate Dimensions
            const lineHeight = fontSize * 1.4;
            const width = maxWidth || (Math.ceil(ctx.measureText(text).width) + 4);
            const height = Math.ceil(lines.length * lineHeight);

            // Set High-DPI Canvas Size
            canvas.width = width * scaleFactor;
            canvas.height = height * scaleFactor;

            // Scale Context
            ctx.scale(scaleFactor, scaleFactor);

            // Render
            ctx.font = font;
            ctx.fillStyle = color || '#000000';
            ctx.textBaseline = 'middle';

            lines.forEach((line, index) => {
                ctx.fillText(line, 2, (index * lineHeight) + (lineHeight / 2));
            });

            return { dataUrl: canvas.toDataURL('image/png'), width, height };
        };

        // Helper to process text for PDF reports (Fixes encoding AND replaces emojis with images)
        window.processTextForReport = (text) => {
            if (!text) return '';
            let processed = window.fixEncoding(text);

            // Regex for emojis (broad range to catch most emojis)
            // Uses unicode property escapes if supported, otherwise simple range
            const emojiRegex = /(\p{Emoji_Presentation}|\p{Extended_Pictographic})/gu;

            try {
                processed = processed.replace(emojiRegex, (match) => {
                    // Generate image for the emoji
                    const imgData = window.textToImage(match, 14, '#000000'); // Match report font size roughly
                    return `<img src="${imgData.dataUrl}" style="width: ${imgData.width}px; height: ${imgData.height}px; vertical-align: middle; display: inline-block;" alt="emoji" />`;
                });
            } catch (e) {
                console.warn("Emoji replacement failed:", e);
                // Fallback: return text with just encoding fixed
            }

            // Replace newlines with break tags
            processed = processed.replace(/\n/g, '<br>');
            return processed;
        };

        // Helper to format teacher hints (splits by emoji or newlines)
        window.formatTeacherHints = (text) => {
            if (!text) return "No Teacher Hints Provided.";

            // Regex to find emojis (bullets)
            const emojiRegex = /(\p{Emoji_Presentation}|\p{Extended_Pictographic})/gu;

            // If no emojis, check for newlines
            if (!emojiRegex.test(text)) {
                if (text.includes('\n')) {
                    return text.split('\n').filter(line => line.trim()).map(line =>
                        `<div class="mb-2 flex items-start gap-3">
                            <div class="flex-shrink-0 w-1.5 h-1.5 rounded-full bg-amber-400 mt-2"></div>
                            <span class="leading-relaxed text-slate-700 dark:text-slate-300">${line.trim()}</span>
                        </div>`
                    ).join('');
                }
                return `<p class="leading-relaxed text-slate-700 dark:text-slate-300">${text}</p>`;
            }

            // Split by Emoji
            const parts = text.split(emojiRegex);
            let html = '<div class="space-y-4">'; // Increased spacing for cleaner look

            // Handle prefix
            if (parts[0] && parts[0].trim()) {
                html += `<div class="mb-3 text-slate-700 dark:text-slate-300 font-medium">${parts[0].trim()}</div>`;
            }

            for (let i = 1; i < parts.length; i += 2) {
                const emoji = parts[i];
                const content = parts[i + 1] ? parts[i + 1].trim() : "";

                if (emoji) {
                    html += `
                        <div class="flex gap-4 group">
                            <div class="flex-shrink-0 w-10 h-10 rounded-xl bg-white dark:bg-slate-800 flex items-center justify-center text-xl shadow-sm border border-slate-100 dark:border-slate-700 group-hover:scale-110 transition-transform duration-300">
                                ${emoji}
                            </div>
                            <div class="pt-1 flex-1">
                                <p class="text-sm text-slate-600 dark:text-slate-300 leading-relaxed font-medium">
                                    ${content}
                                </p>
                            </div>
                        </div>`;
                }
            }
            html += '</div>';
            return html;
        };

        // UI Helpers (Inlined for reliability)

        // GLOBAL SIDEBAR TOGGLE HELPERS

        // DESKTOP SIDEBAR TOGGLE
        window.toggleSidebarCollapse = function () {
            const sidebar = document.getElementById('main-sidebar');
            const content = document.querySelector('.content-main');
            const icon = document.getElementById('collapse-icon');

            if (sidebar) {
                sidebar.classList.toggle('collapsed');
                const isCollapsed = sidebar.classList.contains('collapsed');

                // Save state
                localStorage.setItem('sidebarCollapsed', isCollapsed);

                // Adjust Content
                if (content) {
                    if (isCollapsed) content.classList.add('expanded');
                    else content.classList.remove('expanded');
                }

                // Rotate Icon
                if (icon) {
                    icon.style.transform = isCollapsed ? 'rotate(180deg)' : 'rotate(0deg)';
                }
            }
        };

        // Initialize Desktop State
        document.addEventListener('DOMContentLoaded', () => {
            if (window.innerWidth > 768) {
                const isCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
                const sidebar = document.getElementById('main-sidebar');
                const content = document.querySelector('.content-main');
                const icon = document.getElementById('collapse-icon');

                if (isCollapsed && sidebar) {
                    sidebar.classList.add('collapsed');
                    if (content) content.classList.add('expanded');
                    if (icon) icon.style.transform = 'rotate(180deg)';
                }
            }
        });

        // MOBILE SIDEBAR TOGGLE
        window.toggleMobileSidebar = function () {
            const sidebar = document.getElementById('main-sidebar');
            const overlay = document.getElementById('mobile-overlay');
            // const iconMenu = document.getElementById('icon-menu-mobile');
            // const iconClose = document.getElementById('icon-close-mobile');

            if (sidebar && overlay) {
                sidebar.classList.toggle('mobile-open');
                overlay.classList.toggle('active');

                // Logic:
                // 1. Open -> Hide Page Logo & Hamburger Button (Sidebar takes over)
                // 2. Close -> Show Page Logo & Hamburger Button

                const isOpen = sidebar.classList.contains('mobile-open');
                const pageLogo = document.getElementById('mobile-logo-container');
                const hamburgerBtn = document.getElementById('mobile-menu-btn');

                if (isOpen) {
                    if (pageLogo) pageLogo.classList.add('opacity-0');
                    if (hamburgerBtn) hamburgerBtn.classList.add('opacity-0', 'pointer-events-none');
                    // FORCE EXPANDED STATE ON MOBILE
                    sidebar.classList.remove('collapsed');
                } else {
                    if (pageLogo) pageLogo.classList.remove('opacity-0');
                    if (hamburgerBtn) hamburgerBtn.classList.remove('opacity-0', 'pointer-events-none');
                }
            } else {
                console.error("Sidebar or Overlay not found for mobile toggle");
            }
        };
    