
        // Emergency Loader Removal (Run independently of other scripts)
        (function () {
            setTimeout(function () {
                var loader = document.getElementById('global-loader');
                if (loader && getComputedStyle(loader).display !== 'none') {
                    console.error('⚠️ CRITICAL: Global loader stuck. Force removing via Failsafe.');
                    loader.style.display = 'none'; // Force hide

                    // Attempt to recover UI
                    var dashboard = document.getElementById('dashboard-layout');
                    var auth = document.getElementById('auth-wrapper');

                    if (dashboard && auth &&
                        dashboard.classList.contains('hidden') &&
                        auth.classList.contains('hidden')) {
                        // If both hidden, show Auth by default to be safe
                        console.warn('⚠️ UI State lost. Defaulting to Auth Screen.');
                        auth.classList.remove('hidden');
                    }
                }
            }, 8000); // 8 Seconds Timeout
        })();

        // Global Error Handler for Loader
        window.addEventListener('error', function (event) {
            console.error('Global Script Error:', event.message);
            var loader = document.getElementById('global-loader');
            if (loader) loader.style.display = 'none';
        });
    