
// --- SAFE ICON LOADER ---
window.safeCreateIcons = () => {
    if (typeof lucide !== 'undefined' && lucide.createIcons) {
        lucide.createIcons();
    }
};

const SUPABASE_URL = "https://fnkctvhrilynnmphdxuo.supabase.co";
const SUPABASE_KEY = "sb_publishable_q_jbUM95dckWS7YF1XSRgg_NvhZ4iyU";
// Initialize Supabase Client
let client; // Renamed from 'supabase' to 'client' to match original usage
window.SUPABASE_AVAILABLE = false;

try {
    if (SUPABASE_URL === 'YOUR_SUPABASE_URL_HERE') {
        console.warn("Supabase credentials are placeholders. Starting in offline mode (Guest).");
        window.client = null;
    } else if (typeof supabase !== 'undefined' && supabase.createClient) {
        client = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
        window.client = client; // Make globally available
        window.SUPABASE_AVAILABLE = true;
        console.log("Supabase (v2) initialized successfully via namespace.");
    } else if (typeof createClient !== 'undefined') {
        // Fallback for older versions or direct imports
        client = createClient(SUPABASE_URL, SUPABASE_KEY);
        window.client = client; // Make globally available
        window.SUPABASE_AVAILABLE = true;
        console.log("Supabase initialized via global createClient.");
    } else {
        console.warn("Supabase library not loaded. Starting in offline mode (Guest).");
        window.client = null; // Prevent ReferenceError
    }
} catch (e) {
    console.error("Supabase init failed:", e);
    window.client = null; // Prevent ReferenceError
}
const { jsPDF } = window.jspdf || { jsPDF: null };

// NEW: Capture Recovery Mode IMMEDIATELY before hash is cleared
window.isRecoveryMode = window.location.hash && window.location.hash.includes('type=recovery');
if (window.isRecoveryMode) console.log("Global Recovery Flag Set: TRUE");

let currentUser = null, userProfile = null, syncInterval = null, performanceChart = null;
// Expose to window for external scripts (like chat.js)
window.currentUser = currentUser;
window.userProfile = userProfile;
let activeTab = 'dashboard', currentTask = null, currentSub = null, editingTaskId = null;
let isInitializing = false;
window.tempInputState = {};
window.allSubmissions = []; window.allTasks = [];

// --- UI NAVIGATION ---
window.toggleSidebar = () => {
    const aside = $('aside');
    const overlay = $('#sidebar-overlay');

    if (aside.hasClass('-translate-x-full')) {
        aside.removeClass('-translate-x-full').addClass('translate-x-0');
        overlay.addClass('show');
    } else {
        aside.removeClass('translate-x-0').addClass('-translate-x-full');
        overlay.removeClass('show');
    }
};

// Close sidebar on tab switch (mobile only)
function closeSidebarOnMobile() {
    if (window.innerWidth <= 1024) {
        $('.sidebar').removeClass('open');
        $('#sidebar-overlay').removeClass('show');
    }
}

// --- THEME ENGINE ---


// --- AUTH LOGIC ---
window.switchAuth = (role) => {
    // Persist selection to prevent refresh mismatches
    localStorage.setItem('last_auth_tab', role);

    $('#auth-form').data('role', role);
    $('#auth-error').addClass('hidden').text('');

    // Modern classes for auth tabs (matching the UI design)
    const activeClass = "bg-white dark:bg-[#1e293b] shadow-sm text-indigo-600 dark:text-indigo-400";
    const inactiveClass = "text-slate-500 hover:text-slate-600 dark:text-slate-400 dark:hover:text-slate-300";

    if (role === 'admin') {
        $('#tab-admin').addClass(activeClass).removeClass(inactiveClass);
        $('#tab-student').removeClass(activeClass).addClass(inactiveClass);
    } else {
        $('#tab-student').addClass(activeClass).removeClass(inactiveClass);
        $('#tab-admin').removeClass(activeClass).addClass(inactiveClass);
    }
};

// --- SESSION MANAGEMENT ---
async function checkSession() {
    if (isInitializing) return;

    // Safety Check for Offline Mode
    if (!client || !client.auth) {
        console.warn("Offline Mode: Skipping session check.");
        finishInitialization(false);
        return;
    }

    try {
        // Robust Session Check with Timeout
        const sessionPromise = client.auth.getSession();
        const timeoutPromise = new Promise((_, reject) =>
            setTimeout(() => reject(new Error("Session Check Timeout")), 15000)
        );

        const { data } = await Promise.race([sessionPromise, timeoutPromise]);
        const session = data?.session;

        if (session) {
            await handleUserSession(session.user);
        } else {
            console.log("No active session found.");
            finishInitialization(false);
        }
    } catch (err) {
        // Handle AbortError and Timeout gracefully
        if (err.name === 'AbortError' || err.message?.includes('aborted')) {
            console.warn("Session check aborted (likely due to navigation or timeout). Treating as logged out.");
        } else {
            console.error("Session check failed:", err);
        }
        finishInitialization(false);
    }
}

async function handleUserSession(user) {
    // If recovery mode, skip login logic and stay on auth screen
    if (window.isRecoveryMode) {
        console.log("Recovery Mode Detected: Skipping Dashboard Init");
        finishInitialization(false);
        return;
    }

    if (!user) { finishInitialization(false); return; }

    // Strict Offline Check: Do not allow cached sessions if Supabase is offline
    if (!client) {
        console.warn("Offline Mode: Forcing logout and clearing cache to prevent guest access.");
        localStorage.removeItem('supabase_profile_cache');
        finishInitialization(false);
        return;
    }

    // PROMISE-BASED LOCK: Request Coalescing
    if (window.sessionInitPromise) {
        console.log("[Session] Joining existing initialization process...");
        return window.sessionInitPromise;
    }

    window.sessionInitPromise = (async () => {
        isInitializing = true;
        let loadedFromCache = false;

        try {
            // Check cache availability for this user ID
            const cachedParams = localStorage.getItem('supabase_profile_cache');

            if (cachedParams) {
                try {
                    const parsed = JSON.parse(cachedParams);
                    if (parsed.uid === user.id) {
                        console.log("[Session] Instant load from cache.");
                        currentUser = user;
                        userProfile = parsed;
                        // CRITICAL FIX: Update global window variables immediately
                        window.currentUser = currentUser;
                        window.userProfile = userProfile;
                        initDashboard(); // UI is now visible!
                        loadedFromCache = true;
                    }
                } catch (e) { localStorage.removeItem('supabase_profile_cache'); }
            }

            // DEFINE the fresh fetch promise
            // DEFINE the fresh fetch promise
            let fetchProfilePromise;
            if (client) {
                fetchProfilePromise = client.from('profiles').select('*').eq('uid', user.id).maybeSingle();
            } else {
                // Offline Mock Promise
                console.warn("Offline Mode: Skipping background profile sync.");
                fetchProfilePromise = Promise.resolve({ data: null, error: { message: "Offline" } });
            }

            // CRITICAL OPTIMIZATION:
            // If we loaded from cache, DO NOT WAIT for the network. Let it run in background.
            if (loadedFromCache) {
                console.log("[Session] Cache hit. Detaching fresh fetch to background.");
                fetchProfilePromise.then(async ({ data: profile, error }) => {
                    if (!profile || error) return; // Silent fail if DB issue, cache is good enough for now

                    // Check for critical changes preventing access
                    if (profile.role !== userProfile.role || profile.status === 'pending') {
                        // If critical status changed, force reload
                        localStorage.setItem('supabase_profile_cache', JSON.stringify(profile));
                        location.reload();
                        return;
                    }

                    // Update cache silently
                    localStorage.setItem('supabase_profile_cache', JSON.stringify(profile));
                    console.log("[Session] Background profile sync complete.");
                });
                return; // EXIT FUNCTION IMMEDIATELY -> Promises resolves -> Loader unlocks
            }

            // If NOT cached, we MUST wait for the fetch, but with a TIMEOUT to prevent hanging
            // Create a timeout promise that rejects after 5 seconds
            // Create a timeout promise that rejects after 15 seconds (increased from 5s)
            const timeoutPromise = new Promise((_, reject) =>
                setTimeout(() => reject(new Error("Network Timeout: Profile fetch took too long. Please check your internet connection.")), 15000)
            );

            let profileData;
            try {
                profileData = await Promise.race([fetchProfilePromise, timeoutPromise]);
            } catch (timeoutErr) {
                console.warn("[Session] Profile sync timed out. Proceeding with limited access or error.");
                throw timeoutErr; // Let the catch block handle it (logout/error message)
            }

            const { data: profile, error } = profileData;

            if (error) throw error;

            if (!profile) {
                console.warn("[Session] Profile not found (User Deleted).");
                await client.auth.signOut();
                localStorage.removeItem('supabase_profile_cache');
                throw new Error("Access Revoked: Your account has been deleted by an administrator.");
            } else {
                // ROLE CHECK with Auto-Correction
                const intendedRole = $('#tab-student').hasClass('bg-white') ? 'student' : 'admin';

                if (profile.role !== intendedRole) {
                    console.log(`[Session] Role mismatch detected. Auto-switching to ${profile.role} view.`);
                    if (window.switchAuth) window.switchAuth(profile.role);
                }

                if (profile.status === 'pending') {
                    console.warn("[Security] Account Pending Approval");
                    await client.auth.signOut();
                    localStorage.removeItem('supabase_profile_cache');
                    throw new Error("Account is pending Admin Approval. Please contact your administrator.");
                }

                // Success: Update Cache
                localStorage.setItem('supabase_profile_cache', JSON.stringify(profile));

                currentUser = user;
                userProfile = profile;

                // CRITICAL FIX: Expose variables globally for chat.js
                window.currentUser = currentUser;
                window.userProfile = userProfile;

                // Initialize Chat if available
                if (window.initChat) {
                    console.log("Initializing Chat System...");
                    window.initChat();
                }

                initDashboard();
            }

        } catch (err) {
            console.error("Session Sync Error:", err);

            if (!loadedFromCache) {
                currentUser = null;
                userProfile = null;
                finishInitialization(false);

                const btn = $('#auth-btn');
                btn.prop('disabled', false);
                // Restore button text based on current mode
                const originalText = $('#name-field').hasClass('hidden') ? 'Sign In' : 'Create Account';
                btn.find('span').text(originalText);

                if ($('#auth-wrapper').is(':visible')) {
                    $('#auth-error').text(err.message).removeClass('hidden');
                } else {
                    showToast(err.message);
                }
            }
        } finally {
            // CRITICAL: Always clear the lock so subsequent attempts can proceed
            isInitializing = false;
            window.sessionInitPromise = null;
        }
    })();

    return window.sessionInitPromise;
}

function finishInitialization(isLoggedIn) {
    $('#global-loader').fadeOut(300);
    if (isLoggedIn) {
        $('#auth-wrapper').addClass('hidden');
        $('#dashboard-layout').removeClass('hidden').css('display', 'flex');

        // Show Mobile Nav
        $('#mobile-nav-bar').removeClass('hidden');

        // Init Daily Quests
    } else {
        $('#dashboard-layout').addClass('hidden');
        $('#mobile-nav-bar').addClass('hidden'); // Hide Mobile Nav
        $('#auth-wrapper').removeClass('hidden');
        // Ensure credentials are shown when returning to auth screen
        if (window.populateRememberedCredentials) window.populateRememberedCredentials();
        window.safeCreateIcons(); // Force refresh icons for eye button
    }
}

if (client && client.auth) {
    client.auth.onAuthStateChange(async (event, session) => {
        console.log("Supabase Auth Event:", event);
        if (event === 'PASSWORD_RECOVERY') {
            // Show Reset Password Modal
            setTimeout(() => new bootstrap.Modal(document.getElementById('resetPasswordModal')).show(), 500);
        } else if (event === 'SIGNED_IN' && session) {
            await handleUserSession(session.user);
        } else if (event === 'SIGNED_OUT') {
            currentUser = null;
            userProfile = null;
            isInitializing = false;
            finishInitialization(false);
        }
    });
} else {
    console.warn("Supabase Auth not available. Auto-login disabled.");
    // Force finish init to remove loader if offline
    setTimeout(() => finishInitialization(false), 100);
}

$(document).ready(() => {
    const savedRole = localStorage.getItem('last_auth_tab') || 'student';
    switchAuth(savedRole);

    // Explicitly check for Recovery Hash to ensure Modal opens
    if (window.isRecoveryMode) {
        console.log("Manual Recovery detection triggered.");
        setTimeout(() => {
            const modalEl = document.getElementById('resetPasswordModal');
            if (modalEl) new bootstrap.Modal(modalEl).show();
        }, 1000);
    }

    checkSession();
    // Safety timeout
    setTimeout(() => {
        if ($('#global-loader').is(':visible')) {
            console.warn("Initialization taking longer than expected... Resetting locks.");
            // CRITICAL: Clear the lock so user can try again manually
            window.sessionInitPromise = null;
            isInitializing = false;
            finishInitialization(!!currentUser);
        }
    }, 12000);
});

// --- TOGGLE MODE OVERRIDE ---
window.customToggleMode = () => {
    const nameField = $('#name-field');
    const avatarField = $('#avatar-field');
    const btn = $('#auth-btn');
    const footer = $('#auth-footer');
    const isSwitchingToSignup = nameField.hasClass('hidden');

    console.log("Custom Toggle Triggered. Switching to Signup?", isSwitchingToSignup);

    if (isSwitchingToSignup) {
        // SWITCH TO SIGNUP
        nameField.removeClass('hidden');
        avatarField.removeClass('hidden');

        btn.find('span').text('Create Account');
        // Icon Logic
        btn.find('svg, i').remove();
        btn.append('<i data-lucide="user-plus" class="w-3.5 h-3.5"></i>');

        footer.html('Already have an account? <button onclick="customToggleMode()" class="text-indigo-500 hover:underline">Sign In</button>');
    } else {
        // SWITCH TO LOGIN
        nameField.addClass('hidden');
        avatarField.addClass('hidden');

        btn.find('span').text('Sign In');
        // Icon Logic
        btn.find('svg, i').remove();
        btn.append('<i data-lucide="log-in" class="w-3.5 h-3.5"></i>');

        // Clear inputs
        $('#auth-name').val('');
        $('#auth-avatar').val('');

        footer.html('New here? <button onclick="customToggleMode()" class="text-indigo-500 hover:underline">Create Account</button>');
    }
    lucide.createIcons();
};

// --- EXAM SYSTEM ---
let examQuestions = [];
let currentQuestionIndex = 0;
let userAnswers = {};
let examActive = false; // Admin toggle state

// 1. Initialize Exam View
async function initExamSystem() {
    if (!currentUser || !userProfile) return;

    // Reset Views
    $('#exam-admin-panel, #exam-admin-results, #exam-student-area, #exam-locked-screen, #exam-start-screen, #exam-interface, #exam-result-card').addClass('hidden');

    if (userProfile.role === 'admin') {
        // Admin View
        $('#exam-admin-panel').removeClass('hidden');
        $('#exam-admin-results').removeClass('hidden');
        fetchExamStatus(); // Check if active
        fetchAdminExamResults();
    } else {
        // Student View
        $('#exam-student-area').removeClass('hidden');
        // Check if already attempted
        const attempted = await checkStudentAttempt();
        if (attempted) {
            showExamResult(attempted.score, attempted.total_marks, true); // Show previous result
        } else {
            // Check for ongoing exam resume
            const savedStart = localStorage.getItem('exam_start_time');
            // Check for stale session (older than 100 mins)
            // Exam is 90 mins. If older than 100 mins, they have no time left, so clear it to allow restart.
            if (savedStart && (Date.now() - parseInt(savedStart) > (100 * 60 * 1000))) {
                console.log("Clearing stale exam session (Time expired)...");
                localStorage.removeItem('exam_start_time');
                localStorage.removeItem('exam_answers');
                // savedStart is now effectively null for the next check, so we fetch status
                fetchExamStatus();
            } else if (savedStart) {
                $('#exam-interface').removeClass('hidden');
                examQuestions = generateQuestions();

                const savedAnswers = localStorage.getItem('exam_answers');
                if (savedAnswers) userAnswers = JSON.parse(savedAnswers);
                else userAnswers = {};

                currentQuestionIndex = 0;
                renderQuestion();
                startTimer();
            } else {
                fetchExamStatus(); // Check if active to show Start or Lock screen
            }
        }
    }
}

// 2. Fetch Exam Status (Active/Locked)
const fetchExamStatus = async () => {
    if (!window.client) return;

    // We'll use a table 'exam_settings' with a row id=1
    const { data, error } = await window.client
        .from('exam_settings')
        .select('is_active')
        .eq('id', 1)
        .single();

    if (data) {
        examActive = data.is_active;
    } else {
        // Default to false if table doesn't exist yet
        examActive = false;
    }

    updateExamUIState();
}

function updateExamUIState() {
    const statusBadge = $('#exam-status-badge');
    const toggleBtn = $('#exam-toggle-btn');

    if (examActive) {
        // Admin UI
        statusBadge.removeClass('bg-rose-500/20 text-rose-400 border-rose-500/20')
            .addClass('bg-emerald-500/20 text-emerald-500 border-emerald-500/20').text('ACTIVE');
        toggleBtn.text('Disable Exam').removeClass('bg-indigo-600').addClass('bg-rose-600 hover:bg-rose-700');

        // Student UI
        // SECURITY CHECK: If attempt exists, prevent Start Screen
        if (window.existingAttempt) {
            $('#exam-start-screen').addClass('hidden');
            // Ensure result card is shown if not already
            if ($('#exam-result-card').hasClass('hidden')) {
                showExamResult(window.existingAttempt.score, window.existingAttempt.total_marks, true);
            }
            return;
        }

        if (userProfile.role !== 'admin' && $('#exam-result-card').hasClass('hidden')) {
            $('#exam-locked-screen').addClass('hidden');
            $('#exam-start-screen').removeClass('hidden');
        }
    } else {
        // Admin UI
        statusBadge.removeClass('bg-emerald-500/20 text-emerald-500 border-emerald-500/20')
            .addClass('bg-rose-500/20 text-rose-400 border-rose-500/20').text('LOCKED');
        toggleBtn.text('Enable Exam').removeClass('bg-rose-600').addClass('bg-indigo-600 hover:bg-indigo-700');

        // Student UI
        if (userProfile.role !== 'admin' && $('#exam-result-card').hasClass('hidden')) {
            $('#exam-start-screen').addClass('hidden');
            $('#exam-locked-screen').removeClass('hidden');
        }
    }
}

// 3. Admin Toggle Exam
window.toggleExamStatus = async () => {
    const newStatus = !examActive;
    const { error } = await window.client
        .from('exam_settings')
        .upsert({ id: 1, is_active: newStatus });

    if (!error) {
        examActive = newStatus;
        updateExamUIState();
        showToast(`Exam ${newStatus ? 'Enabled' : 'Disabled'}`);
    } else {
        console.error(error);
        showToast('Error updating status', 'error');
    }
};

// 4. Student Attempt Check (Robust & Safe)
async function checkStudentAttempt() {
    // Auto-Sync Check: Try to upload pending offline exams
    try {
        if (currentUser) {
            const pendingKey = `pending_exam_sync_${currentUser.id}`;
            const pending = localStorage.getItem(pendingKey);
            if (pending && navigator.onLine) {
                const payload = JSON.parse(pending);
                console.log("Syncing pending exam...");
                const { error } = await window.client.from('exam_results').insert(payload);
                if (!error) {
                    localStorage.removeItem(pendingKey);
                    showToast("Offline exam synced successfully!", "success");
                } else {
                    console.warn("Sync failed:", error);
                }
            }
        }
    } catch (e) { console.error("Auto-sync error:", e); }

    // Return cached result if available
    if (window.existingAttempt) return window.existingAttempt;

    // 1. Check by IDs (Current ID + Legacy UID)
    const idsToCheck = [currentUser.id];
    if (userProfile?.uid && userProfile.uid !== currentUser.id) {
        idsToCheck.push(userProfile.uid);
    }

    let { data } = await window.client
        .from('exam_results')
        .select('id, score, total_marks, status, certificate_id, created_at, student_id, student_name')
        .in('student_id', idsToCheck)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle();

    // 2. Fallback: Check by Name (if no result found by ID)
    if (!data && userProfile?.name) {
        try {
            const safeName = userProfile.name.trim();
            // Try exact match first
            let { data: byName } = await window.client
                .from('exam_results')
                .select('id, score, total_marks, status, certificate_id, created_at, student_id, student_name')
                .eq('student_name', safeName)
                .order('created_at', { ascending: false })
                .limit(1)
                .maybeSingle();

            // If not found, try looser match (handle spaces/case if possible via wildcard)
            if (!byName) {
                const { data: byLike } = await window.client
                    .from('exam_results')
                    .select('id, score, total_marks, status, certificate_id, created_at, student_id, student_name')
                    .ilike('student_name', `%${safeName}%`)
                    .order('created_at', { ascending: false })
                    .limit(1)
                    .maybeSingle();
                byName = byLike;
            }
            data = byName;
        } catch (e) {
            console.warn("Name check failed:", e);
        }
    }

    // 3. Fallback: Check Local Pending Sync (Offline Attempt)
    if (!data) {
        try {
            const pending = localStorage.getItem(`pending_exam_sync_${currentUser.id}`);
            if (pending) {
                data = JSON.parse(pending);
                // Mark as pending/offline for UI if needed
                console.log("Found pending offline exam attempt");
            }
        } catch (e) { console.error("Pending check failed", e); }
    }

    if (data) {
        window.existingAttempt = data;

        // SYNC LOGIC: If server missing details but local has them, sync it
        // Logic disabled until columns added to DB
        // if ((!data.answers_json || !data.questions_json) && currentUser) {
        if (false && currentUser) {
            try {
                const ls = localStorage.getItem(`exam_review_${currentUser.id}`);
                if (ls) {
                    const parsed = JSON.parse(ls);
                    window.previousReviewSnapshot = parsed; // Use local immediately

                    // Background sync to server (DISABLED until columns added to DB)
                    /*
                    window.client.from('exam_results')
                        .update({ 
                            answers_json: parsed.answers,
                            questions_json: parsed.questions
                        })
                        .eq('id', data.id)
                        .then(({ error }) => {
                            if(!error) console.log("Synced legacy exam data to server");
                        });
                    */
                }
            } catch (e) { console.warn("Sync check failed", e); }
        }

        // if (data.answers_json || data.questions_json) {
        if (false) {
            window.previousReviewSnapshot = {
                // answers: data.answers_json || {},
                // questions: data.questions_json || []
                answers: {},
                questions: []
            };
        }
    } else {
        try {
            const ls = localStorage.getItem(`exam_review_${currentUser.id}`);
            if (ls) {
                window.previousReviewSnapshot = JSON.parse(ls);
            }
        } catch { }
    }
    return data;
}

// 5. Start Exam
let examTimerInterval;
const EXAM_DURATION_MS = 60 * 60 * 1000; // 60 minutes for 100 questions

window.startExam = async () => {
    const attempted = await checkStudentAttempt();
    if (attempted) {
        showExamResult(attempted.score, attempted.total_marks, true);
        return;
    }
    if (!localStorage.getItem('exam_start_time')) {
        localStorage.setItem('exam_start_time', Date.now());
        localStorage.removeItem('exam_answers');
        userAnswers = {};
    }
    $('#exam-start-screen').addClass('hidden');
    $('#exam-interface').removeClass('hidden');
    examQuestions = generateQuestions();
    const savedAnswers = localStorage.getItem('exam_answers');
    if (savedAnswers) {
        userAnswers = JSON.parse(savedAnswers);
    }
    currentQuestionIndex = 0;
    renderQuestion();
    startTimer();
};

function startTimer() {
    if (examTimerInterval) clearInterval(examTimerInterval);

    const update = () => {
        const startTime = parseInt(localStorage.getItem('exam_start_time'));
        if (!startTime) return;

        const now = Date.now();
        const elapsed = now - startTime;
        const remaining = EXAM_DURATION_MS - elapsed;

        if (remaining <= 0) {
            clearInterval(examTimerInterval);
            $('#exam-timer-display').text("00:00").addClass('text-rose-500');
            alert("Time's up! Submitting your exam now.");
            submitExam(true);
            return;
        }

        const totalSeconds = Math.floor(remaining / 1000);
        const m = Math.floor(totalSeconds / 60);
        const s = totalSeconds % 60;
        $('#exam-timer-display').text(`${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`);

        if (remaining < 300000) { // 5 mins warning
            $('#exam-timer-display').addClass('text-rose-500 animate-pulse');
        } else {
            $('#exam-timer-display').removeClass('text-rose-500 animate-pulse');
        }
    };

    update();
    examTimerInterval = setInterval(update, 1000);
}

// 6. Generate 100 HTML Questions
function generateQuestions() {
    const allQ = [
        { q: "HTML ka full form kya hai?", options: ["Hyper Text Markup Language", "High Text Machine Language", "Hyper Tool Markup Language", "Hyper Text Machine Language"], correct: 0 },
        { q: "HTML ka use kis liye hota hai?", options: ["Styling", "Programming", "Web page ka structure", "Database"], correct: 2 },
        { q: "HTML file ka extension kya hota hai?", options: [".ht", ".html", ".web", ".doc"], correct: 1 },
        { q: "Root element kaunsa hota hai?", options: ["<head>", "<body>", "<html>", "<title>"], correct: 2 },
        { q: "Page ka title kahan likhte hain?", options: ["<body>", "<meta>", "<title>", "<h1>"], correct: 2 },
        { q: "Heading tags ka range kya hai?", options: ["<h1> to <h3>", "<h1> to <h6>", "<h2> to <h6>", "<h1> to <h5>"], correct: 1 },
        { q: "Paragraph ke liye kaunsa tag hai?", options: ["<para>", "<p>", "<text>", "<pg>"], correct: 1 },
        { q: "Line break ke liye kaunsa tag?", options: ["<lb>", "<br>", "<break>", "<hr>"], correct: 1 },
        { q: "Horizontal line ke liye?", options: ["<br>", "<line>", "<hr>", "<border>"], correct: 2 },
        { q: "Anchor tag ka use?", options: ["Image", "Link", "Form", "Table"], correct: 1 },
        { q: "Link ka address kis attribute me hota hai?", options: ["src", "href", "link", "url"], correct: 1 },
        { q: "New tab me link open karne ke liye?", options: ["open", "blank", "target=\"_blank\"", "new"], correct: 2 },
        { q: "Image ke liye kaunsa tag?", options: ["<image>", "<img>", "<pic>", "<src>"], correct: 1 },
        { q: "Image ka path kis attribute se dete hain?", options: ["href", "src", "alt", "title"], correct: 1 },
        { q: "Image ka alternative text?", options: ["name", "title", "alt", "value"], correct: 2 },
        { q: "HTML comment ka sahi tareeqa?", options: ["// comment", "/* comment */", "<!-- comment -->", "## comment"], correct: 2 },
        { q: "Bold text ke liye?", options: ["<b>", "<strong>", "Dono A aur B", "<bold>"], correct: 2 },
        { q: "Italic text ke liye?", options: ["<i>", "<em>", "Dono A aur B", "<italic>"], correct: 2 },
        { q: "Underline ke liye?", options: ["<u>", "<ul>", "<underline>", "<li>"], correct: 0 },
        { q: "Subscript ke liye?", options: ["<sup>", "<sub>", "<small>", "<big>"], correct: 1 },
        { q: "Superscript ke liye?", options: ["<sub>", "<sup>", "<small>", "<big>"], correct: 1 },
        { q: "Ordered list ka tag?", options: ["<ul>", "<ol>", "<li>", "<list>"], correct: 1 },
        { q: "Unordered list ka tag?", options: ["<ul>", "<ol>", "<li>", "<u>"], correct: 0 },
        { q: "List item ka tag?", options: ["<item>", "<li>", "<list>", "<il>"], correct: 1 },
        { q: "Description list ka main tag?", options: ["<dl>", "<dt>", "<dd>", "<list>"], correct: 0 },
        { q: "Definition term ka tag?", options: ["<dl>", "<dt>", "<dd>", "<li>"], correct: 1 },
        { q: "Definition description ka tag?", options: ["<dl>", "<dt>", "<dd>", "<li>"], correct: 2 },
        { q: "Form banane ka tag?", options: ["<input>", "<form>", "<label>", "<fieldset>"], correct: 1 },
        { q: "Label ka use?", options: ["Styling", "Input ka naam show", "Data store", "Validation"], correct: 1 },
        { q: "Text input ke liye?", options: ["email", "password", "text", "number"], correct: 2 },
        { q: "Email input type?", options: ["mail", "email", "text", "gmail"], correct: 1 },
        { q: "Password input type?", options: ["hidden", "secure", "password", "lock"], correct: 2 },
        { q: "Radio button ka type?", options: ["checkbox", "radio", "select", "option"], correct: 1 },
        { q: "Checkbox ka type?", options: ["check", "tick", "checkbox", "box"], correct: 2 },
        { q: "Mobile number ke liye type?", options: ["phone", "tel", "number", "mobile"], correct: 1 },
        { q: "Textarea ka use?", options: ["Single line text", "Multiple line text", "Image upload", "Dropdown"], correct: 1 },
        { q: "Dropdown banane ka tag?", options: ["<option>", "<select>", "<list>", "<input>"], correct: 1 },
        { q: "Dropdown ke option ka tag?", options: ["<li>", "<option>", "<select>", "<opt>"], correct: 1 },
        { q: "Fieldset ka use?", options: ["Button banana", "Form fields group", "Styling", "Input hide"], correct: 1 },
        { q: "Fieldset ka title?", options: ["<title>", "<label>", "<legend>", "<head>"], correct: 2 },
        { q: "Table banane ka tag?", options: ["<tbl>", "<table>", "<tr>", "<td>"], correct: 1 },
        { q: "Table row ka tag?", options: ["<td>", "<tr>", "<th>", "<row>"], correct: 1 },
        { q: "Table heading cell?", options: ["<td>", "<tr>", "<th>", "<thead>"], correct: 2 },
        { q: "Table data cell?", options: ["<th>", "<td>", "<tr>", "<cell>"], correct: 1 },
        { q: "Table border attribute?", options: ["frame", "border", "cellpadding", "cellspacing"], correct: 1 },
        { q: "Cell ke andar space?", options: ["cellspacing", "cellpadding", "margin", "padding"], correct: 1 },
        { q: "Cells ke darmiyan space?", options: ["border", "cellpadding", "cellspacing", "space"], correct: 2 },
        { q: "Object tag ka use?", options: ["Image", "External resource embed", "Form", "Table"], correct: 1 },
        { q: "Object tag me file path ka attribute?", options: ["src", "data", "href", "link"], correct: 1 },
        { q: "Object tag ka alternate content kyun?", options: ["Styling", "Load fail hone par", "Validation", "Database"], correct: 1 },
        { q: "iframe ka use?", options: ["Image", "Video", "Another webpage show", "Form"], correct: 2 },
        { q: "iframe ka attribute jo URL deta hai?", options: ["href", "src", "link", "path"], correct: 1 },
        { q: "iframe kis cheez ke liye common hai?", options: ["PDF", "Google Maps", "YouTube", "All of these"], correct: 3 },
        { q: "Audio tag ka use?", options: ["Video", "Sound play", "Image", "Text"], correct: 1 },
        { q: "Audio tag ka attribute jo controls show kare?", options: ["play", "show", "controls", "audio"], correct: 2 },
        { q: "Audio file ka common format?", options: [".mp3", ".jpg", ".html", ".css"], correct: 0 },
        { q: "Video tag ka use?", options: ["Audio", "Image", "Video play", "Form"], correct: 2 },
        { q: "Video controls dikhane ke liye?", options: ["play", "show", "controls", "view"], correct: 2 },
        { q: "Video ke liye common format?", options: [".mp4", ".mp3", ".png", ".css"], correct: 0 },
        { q: "Video autoplay ka attribute?", options: ["auto", "play", "autoplay", "start"], correct: 2 },
        { q: "muted attribute ka use?", options: ["Sound increase", "Sound band", "Video stop", "Reload"], correct: 1 },
        { q: "loop attribute ka use?", options: ["Video band", "Repeat play", "Fast", "Pause"], correct: 1 },
        { q: "Form data submit karne ke liye?", options: ["reset", "submit", "button", "send"], correct: 1 },
        { q: "Reset button ka kaam?", options: ["Submit", "Clear form", "Save", "Reload"], correct: 1 },
        { q: "Placeholder ka use?", options: ["Value store", "Hint dikhana", "Label banana", "Hide"], correct: 1 },
        { q: "Required attribute ka use?", options: ["Optional banana", "Field mandatory banana", "Styling", "Hide"], correct: 1 },
        { q: "Name attribute ka kaam?", options: ["Styling", "Data identify", "Size", "Color"], correct: 1 },
        { q: "Select tag kis ke sath use hota hai?", options: ["<li>", "<option>", "<input>", "<label>"], correct: 1 },
        { q: "Audio tag ke andar source ka tag?", options: ["<src>", "<file>", "<source>", "<link>"], correct: 2 },
        { q: "Video tag ke andar source?", options: ["<src>", "<file>", "<source>", "<link>"], correct: 2 },
        { q: "iframe ek ______ element hai", options: ["Form", "Media", "Inline frame", "Block"], correct: 2 },
        { q: "object tag kis type ka content load karta hai?", options: ["External", "Internal", "CSS", "Script"], correct: 0 },
        { q: "HTML case sensitive hoti hai?", options: ["Yes", "No", "Kabhi kabhi", "Attributes only"], correct: 1 },
        { q: "HTML ek ______ language hai", options: ["Programming", "Scripting", "Markup", "Query"], correct: 2 },
        { q: "Meta tag kahan hota hai?", options: ["body", "footer", "head", "html"], correct: 2 },
        { q: "Charset ka kaam?", options: ["Font size", "Encoding batana", "Color", "Layout"], correct: 1 },
        { q: "Viewport ka use?", options: ["SEO", "Responsive design", "Database", "Security"], correct: 1 },
        { q: "iframe me height/width kis liye?", options: ["Style", "Size control", "Color", "Border"], correct: 1 },
        { q: "Audio autoplay attribute?", options: ["auto", "play", "autoplay", "start"], correct: 2 },
        { q: "Video poster attribute ka use?", options: ["Thumbnail image", "Sound", "Caption", "Loop"], correct: 0 },
        { q: "iframe me border remove karne ke liye?", options: ["border", "frameborder=\"0\"", "none", "remove"], correct: 1 },
        { q: "Object tag me width/height?", options: ["Styling", "Size define", "Link", "Validation"], correct: 1 },
        { q: "Form ka method attribute?", options: ["get/post", "send", "push", "fetch"], correct: 0 },
        { q: "Action attribute ka use?", options: ["Styling", "Data submit URL", "Validation", "Hide"], correct: 1 },
        { q: "Label ko input se connect karne ke liye?", options: ["name", "id", "for", "class"], correct: 2 },
        { q: "iframe me sandbox attribute?", options: ["Styling", "Security", "Layout", "Audio"], correct: 1 },
        { q: "Audio loop attribute?", options: ["repeat", "loop", "again", "play"], correct: 1 },
        { q: "Video muted attribute?", options: ["Sound off", "Sound on", "Replay", "Pause"], correct: 0 },
        { q: "Object tag fallback content kab dikhta hai?", options: ["Jab load ho", "Jab fail ho", "Hamesha", "Kabhi nahi"], correct: 1 },
        { q: "iframe ke andar text likha ja sakta hai?", options: ["Yes", "No", "Kabhi kabhi", "CSS se"], correct: 0 },
        { q: "Audio controls attribute?", options: ["show", "controls", "play", "sound"], correct: 1 },
        { q: "Video controls attribute?", options: ["show", "controls", "view", "play"], correct: 1 },
        { q: "Object tag ke andar kis type ka content ho sakta hai?", options: ["Text", "Image", "Media", "All"], correct: 3 },
        { q: "iframe inline element hai ya block?", options: ["Block", "Inline", "Dono", "None"], correct: 1 },
        { q: "Video tag ke sath kis tag ka use hota hai?", options: ["<link>", "<source>", "<img>", "<file>"], correct: 1 },
        { q: "Audio tag kis section me hota hai?", options: ["head", "body", "footer", "meta"], correct: 1 },
        { q: "iframe ka common use?", options: ["Image", "Map", "External page", "All"], correct: 3 },
        { q: "HTML me multimedia tags kaunse hain?", options: ["audio, video", "img, link", "p, h1", "form, input"], correct: 0 },
        { q: "Object tag HTML me kyun use hota hai?", options: ["Styling", "Embed resources", "Layout", "Validation"], correct: 1 },
        { q: "HTML beginners ke liye sabse pehle kya seekhna chahiye?", options: ["JavaScript", "CSS", "HTML structure & basic tags", "Database"], correct: 2 }
    ];

    // Shuffle function to randomize questions
    function shuffle(array) {
        let currentIndex = array.length, randomIndex;
        while (currentIndex != 0) {
            randomIndex = Math.floor(Math.random() * currentIndex);
            currentIndex--;
            [array[currentIndex], array[randomIndex]] = [
                array[randomIndex], array[currentIndex]];
        }
        return array;
    }

    return shuffle(allQ).slice(0, 100);
}

// 7. Render Question
function renderQuestion() {
    const q = examQuestions[currentQuestionIndex];
    $('#current-q-num').text(currentQuestionIndex + 1);
    $('#question-text').text(q.q);

    const progress = ((currentQuestionIndex + 1) / examQuestions.length) * 100;
    $('#exam-progress-bar').css('width', `${progress}%`);

    const container = $('#options-container').empty();
    q.options.forEach((opt, idx) => {
        const isChecked = userAnswers[currentQuestionIndex] === idx;

        // Escape HTML tags in options
        const escapedOpt = opt.replace(/</g, "&lt;").replace(/>/g, "&gt;");

        const el = $(`
                    <label class="group relative flex items-center gap-4 p-5 rounded-2xl border-2 cursor-pointer transition-all duration-200 ${isChecked ? 'border-indigo-500 bg-indigo-50/50 dark:bg-indigo-900/20 shadow-lg shadow-indigo-500/10' : 'bg-white dark:bg-[#1e293b] border-slate-200 dark:border-slate-800 hover:border-indigo-300 dark:hover:border-indigo-700 hover:shadow-md'}">
                        <div class="w-8 h-8 rounded-full border-2 flex items-center justify-center shrink-0 transition-all ${isChecked ? 'border-indigo-500 bg-indigo-500 text-white scale-110' : 'border-slate-300 dark:border-slate-600 group-hover:border-indigo-400'}">
                            ${isChecked ? '<i data-lucide="check" class="w-5 h-5"></i>' : '<span class="text-xs font-bold text-slate-400 group-hover:text-indigo-400">' + String.fromCharCode(65 + idx) + '</span>'}
                        </div>
                        <input type="radio" name="q_opt" value="${idx}" class="hidden" ${isChecked ? 'checked' : ''}>
                        <span class="text-base font-medium text-slate-700 dark:text-slate-200 option-text leading-relaxed group-hover:text-slate-900 dark:group-hover:text-white transition-colors"></span>
                        
                        ${isChecked ? '<div class="absolute inset-0 rounded-2xl ring-2 ring-indigo-500 ring-offset-2 ring-offset-transparent pointer-events-none"></div>' : ''}
                    </label>
                `);
        el.find('.option-text').html(escapedOpt); // Use .html() to render escaped entities correctly

        el.click(() => selectOption(idx));
        container.append(el);
    });

    // Re-initialize icons for the new content
    if (window.lucide) lucide.createIcons();

    $('#btn-prev').prop('disabled', currentQuestionIndex === 0);
    if (currentQuestionIndex === examQuestions.length - 1) {
        $('#btn-next').addClass('hidden');
        $('#btn-submit').removeClass('hidden');
    } else {
        $('#btn-next').removeClass('hidden');
        $('#btn-submit').addClass('hidden');
    }
}

window.selectOption = (idx) => {
    userAnswers[currentQuestionIndex] = idx;
    localStorage.setItem('exam_answers', JSON.stringify(userAnswers));
    renderQuestion();
};

window.nextQuestion = () => {
    if (currentQuestionIndex < examQuestions.length - 1) {
        currentQuestionIndex++;
        renderQuestion();
    }
};

window.prevQuestion = () => {
    if (currentQuestionIndex > 0) {
        currentQuestionIndex--;
        renderQuestion();
    }
};

// 8. Submit Exam
window.submitExam = async (force = false) => {
    if (!force && !confirm("Are you sure you want to submit? You cannot undo this.")) return;

    clearInterval(examTimerInterval);
    localStorage.removeItem('exam_start_time');
    localStorage.removeItem('exam_answers');

    let score = 0;
    examQuestions.forEach((q, idx) => {
        if (userAnswers[idx] === q.correct) score++;
    });

    const percentage = Math.round((score / examQuestions.length) * 100);
    const passed = percentage >= 40;

    // Generate unique Certificate ID if passed
    let certId = null;
    if (passed) {
        const randomPart = Math.floor(1000 + Math.random() * 9000); // 4 digit
        certId = "BBS-HTML-" + new Date().getFullYear() + "-" + randomPart;
    }

    if (window.client && currentUser && userProfile) {
        // Snapshot for review persistence
        const reviewSnapshot = {
            questions: examQuestions.map(q => ({ q: q.q, options: q.options, correct: q.correct })),
            answers: userAnswers
        };

        // Save to localStorage as a backup (for same-device review)
        try {
            localStorage.setItem(`exam_review_${currentUser.id}`, JSON.stringify(reviewSnapshot));
        } catch { }

        // OFFLINE SUPPORT: Create a pending payload
        const payload = {
            student_id: currentUser.id,
            student_name: userProfile.name,
            score: percentage,
            total_marks: 100,
            status: passed ? 'PASS' : 'FAIL',
            certificate_id: certId,
            created_at: new Date().toISOString()
        };

        // Save to Pending Sync (Robust Offline Mode)
        try {
            localStorage.setItem(`pending_exam_sync_${currentUser.id}`, JSON.stringify(payload));
        } catch (e) { console.error("Local save failed", e); }

        try {
            const { error } = await window.client.from('exam_results').insert(payload);
            if (error) {
                console.warn("Upload failed, saved offline:", error);
                showToast("You are offline. Result saved locally and will sync when online.", "warning");
            } else {
                // Success! Remove pending sync
                localStorage.removeItem(`pending_exam_sync_${currentUser.id}`);
                showToast("Exam submitted successfully!", "success");
            }
        } catch (err) {
            console.warn("Network error, saved offline:", err);
            showToast("Network error. Result saved locally.", "warning");
        }
    }

    showExamResult(percentage, examQuestions.length, false);
};

function showExamResult(percentage, total, isHistory) {
    $('#exam-interface').addClass('hidden');
    $('#exam-start-screen').addClass('hidden');
    $('#exam-result-card').removeClass('hidden');

    const passed = percentage >= 40;

    $('#result-score').text(percentage + '%').removeClass('text-emerald-500 text-rose-500').addClass(passed ? 'text-emerald-500' : 'text-rose-500');
    $('#result-message').text(passed ? 'Congratulations! You Passed.' : 'Better luck next time.');

    const icon = passed ? '<i data-lucide="trophy" class="w-12 h-12 text-emerald-600"></i>' : '<i data-lucide="x-circle" class="w-12 h-12 text-rose-600"></i>';
    $('#result-icon-container').html(icon).removeClass('bg-emerald-100 bg-rose-100').addClass(passed ? 'bg-emerald-100' : 'bg-rose-100');

    // Show Download Button if passed
    if (passed) {
        $('#btn-download-cert').removeClass('hidden');
    } else {
        $('#btn-download-cert').addClass('hidden');
    }

    lucide.createIcons();
}

// 10. Download Certificate
window.downloadCertificate = async () => {
    if (!window.jspdf || !window.html2canvas) {
        showToast("Certificate system loading... Please try again in a few seconds.", "error");
        return;
    }

    const container = $('#certificate-container');
    const name = (userProfile && userProfile.name) ? userProfile.name : "Student Name";
    const score = $('#result-score').text();
    const date = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
    // Generate a random ID for "authenticity"
    const certId = "BBS-HTML-" + new Date().getFullYear() + "-" + Math.floor(1000 + Math.random() * 9000);

    // Populate Data
    $('#cert-student-name').text(name);
    $('#cert-score').text(score);
    $('#cert-date').text(date);
    $('#cert-id').text(certId);

    showToast("Generating Certificate... Please wait.", "info");

    // Create a clone of the certificate for capture
    // This avoids issues with hidden elements or existing transforms
    const originalElement = document.getElementById('certificate-template');
    const clone = originalElement.cloneNode(true);

    // Setup clone for perfect capture
    clone.id = 'certificate-template-clone';
    clone.style.position = 'absolute';
    clone.style.top = '0';
    clone.style.left = '0';
    clone.style.transform = 'none';
    clone.style.margin = '0';
    clone.style.zIndex = '9999';
    clone.style.width = '1123px';
    clone.style.height = '900px';

    // Important: Ensure images in clone are loaded or have correct src
    // The cloneNode(true) copies attributes, but we need to ensure the signature image source is set if it was set via JS
    const originalSig = originalElement.querySelector('#admin-sig-img');
    const cloneSig = clone.querySelector('#admin-sig-img');
    if (originalSig && cloneSig) {
        cloneSig.src = originalSig.src;
    }

    document.body.appendChild(clone);

    // Lock body scroll
    const bodyOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    window.scrollTo(0, 0);

    try {
        // Wait for render (fonts, images)
        await new Promise(r => setTimeout(r, 1000));

        const canvas = await html2canvas(clone, {
            scale: 3, // Higher quality
            useCORS: true,
            logging: false,
            backgroundColor: '#ffffff',
            width: 1123,
            height: 900,
            scrollX: 0,
            scrollY: 0,
            x: 0,
            y: 0
        });

        const { jsPDF } = window.jspdf;
        // Create PDF with custom dimensions matching the captured canvas aspect ratio
        // Use pixels (or points) to match canvas dimensions 1:1 to avoid cropping
        const pdf = new jsPDF('l', 'px', [1123, 900]);

        const pdfWidth = pdf.internal.pageSize.getWidth();
        const pdfHeight = pdf.internal.pageSize.getHeight();

        const imgData = canvas.toDataURL('image/jpeg', 0.98);
        pdf.addImage(imgData, 'JPEG', 0, 0, pdfWidth, pdfHeight);

        pdf.save(`HTML_Certificate_${name.replace(/[^a-z0-9]/gi, '_')}.pdf`);

        showToast("Certificate downloaded successfully!");
    } catch (err) {
        console.error("Certificate Generation Error:", err);
        showToast("Failed to generate certificate.", "error");
    } finally {
        // Remove clone and restore body
        if (clone && clone.parentNode) {
            clone.parentNode.removeChild(clone);
        }
        document.body.style.overflow = bodyOverflow;
    }
};

// 9. Admin Results
async function fetchAdminExamResults() {
    if (!userProfile || userProfile.role !== 'admin') return;

    const tbody = $('#exam-results-body');
    tbody.html('<tr><td colspan="4" class="p-4 text-center">Loading...</td></tr>');

    const { data } = await window.client
        .from('exam_results')
        .select('*')
        .order('created_at', { ascending: false });

    if (!data || data.length === 0) {
        tbody.html('<tr><td colspan="4" class="p-4 text-center text-slate-400">No results found.</td></tr>');
        return;
    }

    tbody.empty();
    data.forEach(row => {
        const date = new Date(row.created_at).toLocaleDateString();
        const isPass = row.status === 'PASS';
        const tr = `
                    <tr class="border-b border-slate-50 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-800/50">
                        <td class="p-3 font-bold text-slate-800 dark:text-slate-200">${row.student_name || row.student_id}</td>
                        <td class="p-3 font-black ${isPass ? 'text-emerald-500' : 'text-rose-500'}">${row.score}%</td>
                        <td class="p-3"><span class="px-2 py-1 rounded text-[10px] font-bold uppercase ${isPass ? 'bg-emerald-100 text-emerald-600' : 'bg-rose-100 text-rose-600'}">${row.status}</span></td>
                        <td class="p-3 text-xs text-slate-400">${date}</td>
                        <td class="p-3 text-right">
                            <button onclick="resetExamResult('${row.id}', '${row.student_name || 'Student'}')" 
                                    class="p-2 bg-slate-100 hover:bg-rose-100 text-slate-400 hover:text-rose-500 rounded-lg transition-colors" 
                                    title="Reset Result (Allow Retake)">
                                <i data-lucide="rotate-ccw" class="w-4 h-4"></i>
                            </button>
                        </td>
                    </tr>
                `;
        tbody.append(tr);
    });
    lucide.createIcons();
}

window.resetExamResult = async (resultId, name) => {
    if (!confirm(`Are you sure you want to RESET the exam result for ${name}?\n\nThis will delete their current score and allow them to take the exam again.`)) return;

    const { error } = await window.client
        .from('exam_results')
        .delete()
        .eq('id', resultId);

    if (!error) {
        showToast(`Result for ${name} has been reset.`);
        fetchAdminExamResults();
    } else {
        console.error(error);
        showToast('Failed to reset result.', 'error');
    }
};

// --- STUDENT COUNT LOGIC ---
const initStudentCounter = () => {
    const countNode = document.getElementById('total-student-count');
    const target = document.getElementById('user-table-body');

    if (target && countNode) {
        const observer = new MutationObserver(() => {
            const count = target.children.length;
            countNode.innerText = `${count} Records`;
        });
        observer.observe(target, { childList: true });
        // Initial set
        countNode.innerText = `${target.children.length} Records`;
    }
};
$(document).ready(initStudentCounter);

// --- SKELETON UI SYSTEM ---
window.renderSkeleton = (containerId, count = 5, type = 'list') => {
    const container = $(`#${containerId}`);
    if (!container.length) return;

    let html = '';
    if (type === 'list') {
        for (let i = 0; i < count; i++) {
            html += `
                        <tr class="animate-pulse border-b border-slate-50 dark:border-slate-800">
                            <td class="px-5 py-4"><div class="h-4 bg-slate-100 dark:bg-slate-700 rounded w-32"></div></td>
                            <td class="px-5 py-4 hidden sm:table-cell"><div class="h-4 bg-slate-100 dark:bg-slate-700 rounded w-20 mx-auto"></div></td>
                            <td class="px-5 py-4"><div class="h-4 bg-slate-100 dark:bg-slate-700 rounded w-24 mx-auto"></div></td>
                            <td class="px-5 py-4"><div class="h-4 bg-slate-100 dark:bg-slate-700 rounded w-16 mx-auto"></div></td>
                            <td class="px-5 py-4"><div class="h-5 bg-slate-100 dark:bg-slate-700 rounded-full w-20 mx-auto"></div></td>
                            <td class="px-5 py-4"><div class="h-6 bg-slate-100 dark:bg-slate-700 rounded w-8 ml-auto"></div></td>
                        </tr>`;
        }
    } else if (type === 'card') {
        for (let i = 0; i < count; i++) {
            html += `
                        <div class="p-5 rounded-xl border border-slate-100 dark:border-slate-800 bg-white dark:bg-slate-900 animate-pulse">
                            <div class="flex justify-between items-start mb-4">
                                <div class="w-10 h-10 rounded-xl bg-slate-100 dark:bg-slate-800"></div>
                                <div class="w-16 h-5 rounded bg-slate-100 dark:bg-slate-800"></div>
                            </div>
                            <div class="h-4 w-3/4 mb-2 rounded bg-slate-100 dark:bg-slate-800"></div>
                            <div class="h-3 w-1/2 mb-4 rounded bg-slate-100 dark:bg-slate-800"></div>
                            <div class="h-8 w-full rounded-lg bg-slate-100 dark:bg-slate-800"></div>
                        </div>`;
        }
    }
    container.html(html);
};


window.switchAuth = (role) => {
    const isStudent = role === 'student';

    // Tab Styling
    $('#tab-student').toggleClass('bg-white dark:bg-[#1e293b] shadow-sm text-indigo-600 dark:text-indigo-400', isStudent)
        .toggleClass('text-slate-500 hover:bg-slate-200 dark:hover:bg-slate-800', !isStudent);

    $('#tab-admin').toggleClass('bg-white dark:bg-[#1e293b] shadow-sm text-indigo-600 dark:text-indigo-400', !isStudent)
        .toggleClass('text-slate-500 hover:bg-slate-200 dark:hover:bg-slate-800', isStudent);

    // Form Fields State
    if (isStudent) {
        if ($('#auth-btn span').text() === 'Create Account') {
            $('#name-field, #avatar-field').slideDown(200);
        }
        $('#toggle-auth-mode').show();
    } else {
        // Admin is login only
        $('#name-field, #avatar-field').slideUp(200);
        $('#toggle-auth-mode').hide();
        if (typeof customToggleMode === 'function' && $('#auth-btn span').text() === 'Create Account') {
            customToggleMode();
        }
    }
};

window.handleAuthSubmit = async (e) => {
    e.preventDefault();
    console.log("[Global] Auth Submit Detected");

    const btn = $('#auth-btn');
    const originalText = btn.find('span').text();
    const errorElement = $('#auth-error');
    const email = $('#auth-email').val();
    const pass = $('#auth-pass').val();
    const name = $('#auth-name').val(); // Capture name early
    const fileInput = document.getElementById('auth-avatar');

    errorElement.addClass('hidden').text('');
    btn.prop('disabled', true).find('span').text('Verifying...');

    if (!client) {
        errorElement.removeClass('hidden').text("System Error: Supabase is not configured or offline. Login disabled.");
        btn.prop('disabled', false).find('span').text(originalText);
        return;
    }

    try {
        if (originalText === 'Create Account') {
            // SIGNUP FLOW
            if (!name) throw new Error("Full Name is required.");

            let data, error;
            // SignUp
            // We MUST pass metadata (Name) because your Supabase Database Triggers likely require it.
            // Without this, the database rejects the new user (500 Error).
            const signUpResult = await client.auth.signUp({
                email,
                password: pass,
                options: { data: { name: name } }
            });

            if (signUpResult.error && signUpResult.error.message.toLowerCase().includes('already registered')) {
                // Check for Partial Deletion (Zombie User) because SQL Script wasn't run
                const { data: loginData, error: loginError } = await client.auth.signInWithPassword({ email, password: pass });

                if (!loginError && loginData.user) {
                    const { data: existingProfile } = await client.from('profiles').select('uid').eq('uid', loginData.user.id).single();
                    if (!existingProfile) {
                        // Profile is missing - Allow Re-creation
                        console.log("Recovering Zombie Account");
                        data = { user: loginData.user };
                        error = null;
                    } else {
                        throw signUpResult.error; // Normal duplicate error
                    }
                } else {
                    throw signUpResult.error; // Password mismatch or other error
                }
            } else {
                data = signUpResult.data;
                error = signUpResult.error;
            }

            if (error) throw error;

            const userId = data.user.id;
            let avatarUrl = null;

            // Upload Avatar Logic
            if (fileInput && fileInput.files && fileInput.files.length > 0) {
                try {
                    const file = fileInput.files[0];
                    const fileExt = file.name.split('.').pop();
                    const fileName = `${userId}-${Math.random().toString(36).substring(7)}.${fileExt}`;

                    // Attempt Upload to Supabase
                    const { error: uploadError } = await client.storage
                        .from('avatars')
                        .upload(fileName, file);

                    if (!uploadError) {
                        const { data: { publicUrl } } = client.storage
                            .from('avatars')
                            .getPublicUrl(fileName);
                        avatarUrl = publicUrl;
                    } else {
                        console.warn("Cloud Upload Failed (Bucket might be missing). Using Local Fallback.");
                        // Fallback: Convert to Base64 and save locally
                        const getBase64 = (f) => new Promise((resolve) => {
                            const reader = new FileReader();
                            reader.readAsDataURL(f);
                            reader.onload = () => resolve(reader.result);
                            reader.onerror = () => resolve(null);
                        });

                        const base64Data = await getBase64(file);
                        if (base64Data) {
                            localStorage.setItem(`cached_avatar_${userId}`, base64Data);
                        }
                    }
                } catch (uploadErr) {
                    console.warn("Avatar upload exception:", uploadErr);
                }
            }

            // Create or Update Profile (Upsert ensures data sync)
            const { error: profileError } = await client.from('profiles').upsert({
                uid: userId,
                full_name: name, name: name,
                email,
                role: 'student',
                status: 'pending',
                avatar_url: avatarUrl
            }, { onConflict: 'uid' });

            if (profileError) throw profileError;

            showToast("Account created! Waiting for Admin Approval.", "success");
            await client.auth.signOut();
            $('#auth-error').removeClass('hidden').text("Registration Successful! Please wait for Admin Approval before logging in.");

            // Switch back to Login View
            // Reset UI manually since toggleMode checks classes
            customToggleMode();
            btn.prop('disabled', false);
        } else {
            // Standard Login
            const intendedRole = $('#tab-student').hasClass('bg-white') ? 'student' : 'admin';

            const { data, error } = await client.auth.signInWithPassword({ email, password: pass });
            if (error) throw error;

            if (data?.user) {
                // Strict Role Validation
                const { data: profile } = await client.from('profiles').select('role').eq('uid', data.user.id).single();
                if (profile && profile.role !== intendedRole) {
                    await client.auth.signOut();
                    throw new Error('Access Denied: You cannot log into the ' + intendedRole.toUpperCase() + ' portal with a ' + profile.role.toUpperCase() + ' account. Please use the correct login tab.');
                }

                // EXPLICIT MODE: Immediately handle the user session
                // This prevents sticking on "Verifying..." if onAuthStateChange is slow/missed.
                await handleUserSession(data.user);
            }
        }
    } catch (err) {
        console.error("Auth Error:", err);
        let msg = err.message;
        // Specific handling for the 500 Trigger Error (Duplicate Key / Zombie Profile)
        if (msg.includes('500') || (err.status === 500) || msg.includes('Database error')) {
            msg = "Database Error (500). An old Profile is likely blocking registration. Please run the 'fix_signup_error.sql' script in your Supabase Dashboard.";
        }
        errorElement.text(msg).removeClass('hidden');
        btn.prop('disabled', false).find('span').text(originalText);
    }
};

// --- AUTOMATED PROGRESS ANALYSIS SYSTEM ---
window.runAutoProgressAnalysis = async () => {
    console.log("Running Auto-Progress Analysis...");
    if (!window.allSubmissions || !window.allUsersCache) return;

    // 1. Calculate Averages
    const stats = {};
    window.allSubmissions.filter(s => s.status === 'graded').forEach(s => {
        if (!stats[s.student_id]) stats[s.student_id] = { total: 0, count: 0, name: s.student_name };
        stats[s.student_id].total += s.grade;
        stats[s.student_id].count++;
    });

    // 2. Identify Top Performers (> 85% Average)
    const topPerformers = [];
    Object.keys(stats).forEach(uid => {
        const avg = stats[uid].total / stats[uid].count;
        if (avg >= 85 && stats[uid].count >= 2) { // Minimum 2 tasks
            topPerformers.push({ id: uid, name: stats[uid].name, avg: Math.round(avg) });
        }
    });

    // 3. Check & Notify (Simulated Backend Job)
    // We use the Notice system with a private tag mechanism.
    // Check if we already notified them recently (Client-side check for now)
    const today = new Date().toDateString();
    const lastRun = localStorage.getItem('last_progress_analysis');

    if (lastRun === today) {
        console.log("Analysis already ran today.");
        return;
    }

    // In a real backend, this would happen on server. Here Admin client does it.
    for (const student of topPerformers) {
        // Check if notice exists
        const { data: existing } = await client.from('notices')
            .select('id')
            .ilike('title', `@${student.name}%`)
            .gt('created_at', new Date(Date.now() - 86400000 * 7).toISOString()); // Last 7 days

        if (!existing || existing.length === 0) {
            // Insert Commendation
            await client.from('notices').insert({
                title: `@${student.name} - Outstanding Progress!`,
                content: `Congratulations! Your performance is exceptional with an average score of ${student.avg}%. Keep up the fantastic work!`,
                priority: 'normal',
                created_by: currentUser.id,
                is_active: true
            });
            showToast(`Auto-Commendation sent to ${student.name}`);
        }
    }
    localStorage.setItem('last_progress_analysis', today);
};




// --- NOTICE BOARD LOGIC ---
window.openNoticeModal = () => {
    new bootstrap.Modal(document.getElementById('createNoticeModal')).show();
};

window.submitNotice = async () => {
    const title = $('#notice-title').val();
    const content = $('#notice-content').val();
    const priority = $('input[name="notice-priority"]:checked').val();

    if (!title) return showToast("Title is required.");

    try {
        const { error } = await client.from('notices').insert({
            title: title,
            content: content || '',
            priority: priority,
            created_by: currentUser.id
        });

        if (error) throw error;
        showToast("Notice Posted Successfully!", "success");

        const modal = bootstrap.Modal.getInstance(document.getElementById('createNoticeModal'));
        if (modal) modal.hide();

        fetchNotices(); // Refresh list

    } catch (err) {
        showToast("Failed to post notice: " + err.message);
    }
};

window.refreshNotices = () => {
    const icon = $('#refreshNotices i');
    icon.addClass('animate-spin');
    fetchNotices().then(() => setTimeout(() => icon.removeClass('animate-spin'), 1000));
};

window.fetchNotices = async () => {
    try {
        const { data: notices, error } = await client.from('notices')
            .select('*')
            .eq('is_active', true)
            .order('created_at', { ascending: false });

        if (error) {
            // Fail silently if table doesn't exist yet
            console.warn("Notice fetch warning (table might be missing):", error);
            return;
        }

        renderNotices(notices || []);

    } catch (e) {
        console.error("Error fetching notices:", e);
    }
};

window.renderNotices = (notices) => {
    const list = $('#notice-list');
    list.empty();
    let hasUrgent = false;

    // Personalized Filtering
    const relevantNotices = notices.filter(n => {
        const title = n.title || '';

        // Admin sees EVERYTHING to monitor the system
        if (userProfile.role === 'admin') return true;

        // If it starts with @, it's a private message.
        // Only show if it matches @[MyName]
        if (title.startsWith('@')) {
            if (title.toLowerCase().startsWith(`@${userProfile.name.toLowerCase()}`)) return true;
            return false; // Hide other people's private messages
        }
        return true; // Show global notices
    });

    if (!relevantNotices || relevantNotices.length === 0) {
        list.html('<div class="text-center py-8 text-slate-400 text-xs font-bold uppercase tracking-wide">No new announcements.</div>');
        $('#urgent-ticker').addClass('hidden');
        return;
    }

    relevantNotices.forEach(n => {
        const isUrgent = n.priority === 'urgent';
        const isPersonal = n.title.startsWith('@');

        if (isUrgent && !hasUrgent && !isPersonal) {
            $('#ticker-text').text(n.title + ": " + (n.content || ""));
            $('#urgent-ticker').removeClass('hidden');
            hasUrgent = true;
        }

        const date = new Date(n.created_at).toLocaleDateString();
        const badge = isUrgent
            ? `<span class="px-2 py-0.5 rounded bg-rose-100 text-rose-600 text-[9px] font-black uppercase">Urgent</span>`
            : `<span class="px-2 py-0.5 rounded bg-slate-100 text-slate-500 text-[9px] font-black uppercase">Info</span>`;

        list.append(`
                    <div class="p-3 bg-slate-50 dark:bg-slate-900/50 rounded-xl border border-slate-100 dark:border-slate-800 hover:border-indigo-200 transition-colors">
                        <div class="flex justify-between items-start mb-1">
                            <h4 class="text-xs font-bold text-slate-900 dark:text-slate-200 line-clamp-1">${n.title}</h4>
                            <span class="text-[8px] font-bold text-slate-400">${date}</span>
                        </div>
                        <p class="text-[10px] text-slate-500 font-medium line-clamp-2 leading-relaxed mb-2">${n.content || ''}</p>
                        ${badge}
                    </div>
                `);
    });

    if (!hasUrgent) $('#urgent-ticker').addClass('hidden');
};

// --- FORGOT PASSWORD LOGIC ---
window.handleForgotPassword = (e) => {
    if (e) e.preventDefault();
    new bootstrap.Modal(document.getElementById('forgotPasswordModal')).show();
};

window.submitForgotPassword = async (e) => {
    e.preventDefault();
    const btn = $('#forgot-btn');
    const msgEl = $('#forgot-msg');
    const email = $('#forgot-email').val();

    msgEl.addClass('hidden').removeClass('text-rose-500');

    if (!email) return;

    btn.prop('disabled', true).text('Sending Link...');
    try {
        console.log("Sending reset to:", email);
        const { error } = await client.auth.resetPasswordForEmail(email, {
            redirectTo: window.location.origin
        });
        if (error) throw error;

        // Switch to Success UI
        $('#forgot-ui-content').addClass('hidden');
        $('#forgot-ui-success').removeClass('hidden');
        lucide.createIcons();

    } catch (err) {
        msgEl.text("Error: " + err.message).addClass('text-rose-500').removeClass('hidden');
    } finally {
        btn.prop('disabled', false).text('Send Recovery Link');
    }
};

// --- NOTICE BOARD LOGIC ---
window.openNoticeModal = () => {
    new bootstrap.Modal(document.getElementById('createNoticeModal')).show();
};

window.submitNotice = async () => {
    const title = $('#notice-title').val();
    const content = $('#notice-content').val();
    const priority = $('input[name="notice-priority"]:checked').val();

    if (!title) return showToast("Title is required.");

    try {
        const { error } = await client.from('notices').insert({
            title: title,
            content: content || '',
            priority: priority,
            created_by: currentUser.id
        });

        if (error) throw error;
        showToast("Notice Posted Successfully!", "success");

        const modal = bootstrap.Modal.getInstance(document.getElementById('createNoticeModal'));
        if (modal) modal.hide();

        fetchNotices(); // Refresh list

    } catch (err) {
        showToast("Failed to post notice: " + err.message);
    }
};

window.refreshNotices = () => {
    const icon = $('#refreshNotices i');
    icon.addClass('animate-spin');
    fetchNotices().then(() => setTimeout(() => icon.removeClass('animate-spin'), 1000));
};

window.fetchNotices = async () => {
    try {
        const { data: notices, error } = await client.from('notices')
            .select('*')
            .eq('is_active', true)
            .order('created_at', { ascending: false });

        if (error) {
            // Fail silently if table doesn't exist yet
            console.warn("Notice fetch warning (table might be missing):", error);
            return;
        }

        renderNotices(notices || []);

    } catch (e) {
        console.error("Error fetching notices:", e);
    }
};

window.renderNotices = (notices) => {
    const list = $('#notice-list');
    list.empty();
    let hasUrgent = false;

    if (!notices || notices.length === 0) {
        list.html('<div class="text-center py-8 text-slate-400 text-xs font-bold uppercase tracking-wide">No new announcements.</div>');
        $('#urgent-ticker').addClass('hidden');
        return;
    }

    notices.forEach(n => {
        const isUrgent = n.priority === 'urgent';
        if (isUrgent && !hasUrgent) {
            $('#ticker-text').text(n.title + ": " + (n.content || ""));
            $('#urgent-ticker').removeClass('hidden');
            hasUrgent = true;
        }

        const date = new Date(n.created_at).toLocaleDateString();
        const badge = isUrgent
            ? `<span class="px-2 py-0.5 rounded bg-rose-100 text-rose-600 text-[9px] font-black uppercase">Urgent</span>`
            : `<span class="px-2 py-0.5 rounded bg-slate-100 text-slate-500 text-[9px] font-black uppercase">Info</span>`;

        list.append(`
                    <div class="p-3 bg-slate-50 dark:bg-slate-900/50 rounded-xl border border-slate-100 dark:border-slate-800 hover:border-indigo-200 transition-colors">
                        <div class="flex justify-between items-start mb-1">
                            <h4 class="text-xs font-bold text-slate-900 dark:text-slate-200 line-clamp-1">${n.title}</h4>
                            <span class="text-[8px] font-bold text-slate-400">${date}</span>
                        </div>
                        <p class="text-[10px] text-slate-500 font-medium line-clamp-2 leading-relaxed mb-2">${n.content || ''}</p>
                        ${badge}
                    </div>
                `);
    });

    if (!hasUrgent) $('#urgent-ticker').addClass('hidden');
};

// --- PASSWORD RESET (LOGGED IN) ---
window.submitResetPassword = async (e) => {
    e.preventDefault();
    const btn = $('#reset-pass-btn');
    const msgEl = $('#reset-msg');
    const pass = $('#reset-new-pass').val();

    msgEl.addClass('hidden').removeClass('text-rose-500');

    if (pass.length < 6) {
        msgEl.text("Password must be at least 6 characters").addClass('text-rose-500').removeClass('hidden');
        return;
    }

    btn.prop('disabled', true).text('Updating...');
    try {
        const { error } = await client.auth.updateUser({ password: pass });
        if (error) throw error;

        await client.auth.signOut(); // Ensure fresh login

        // Switch to Success UI (Professional View)
        $('#reset-ui-content').addClass('hidden');
        $('#reset-ui-success').removeClass('hidden');
        lucide.createIcons();

        // Delay reload so user sees the message
        setTimeout(() => {
            window.location.href = window.location.pathname;
        }, 3000);

    } catch (err) {
        msgEl.text("Update Failed: " + err.message).addClass('text-rose-500').removeClass('hidden');
        btn.prop('disabled', false).text('Update Password');
    }
};

window.toggleMode = () => {
    $('#auth-error').addClass('hidden').text('');
    const isReg = $('#auth-btn span').text() === "Create Account";
    if (isReg) {
        $('#name-field').addClass('hidden');
        $('#auth-tabs').removeClass('hidden');
        $('#auth-btn span').text('Sign In');
        $('#auth-footer').html('New here? <button onclick="toggleMode()" class="text-indigo-500 font-black uppercase tracking-widest text-[9px] hover:underline">Create Account</button>');
    } else {
        switchAuth('student');
        $('#name-field').removeClass('hidden');
        $('#auth-tabs').addClass('hidden');
        $('#auth-btn span').text('Create Account');
        $('#auth-footer').html('Already have an account? <button onclick="toggleMode()" class="text-indigo-500 font-black uppercase tracking-widest text-[9px] hover:underline">Sign In</button>');
    }
};

// [Moved to $(document).ready]

window.togglePasswordVisibility = () => {
    const passInput = document.getElementById('auth-pass');
    const iconEye = document.getElementById('icon-eye');
    const iconEyeOff = document.getElementById('icon-eye-off');

    if (passInput.type === 'password') {
        passInput.type = 'text';
        // Show "Eye Off", Hide "Eye"
        iconEye.classList.add('hidden');
        iconEyeOff.classList.remove('hidden');
    } else {
        passInput.type = 'password';
        // Show "Eye", Hide "Eye Off"
        iconEye.classList.remove('hidden');
        iconEyeOff.classList.add('hidden');
    }
};

window.checkAndShowEncouragement = () => {
    const tasks = window.allTasks || [];
    const subs = window.allSubmissions || [];
    if (!tasks.length) return;

    // Only for students
    if (!userProfile || userProfile.role !== 'student') return;

    const mySubs = subs.filter(s => s.student_id === currentUser.id);
    const total = tasks.length;
    const completed = mySubs.filter(s => s.status === 'graded').length;
    const progressPct = total ? Math.round((completed / total) * 100) : 0;
    const gradedSubs = mySubs.filter(s => s.status === 'graded');
    const avgScore = gradedSubs.length ? gradedSubs.reduce((a, b) => a + (parseInt(b.grade) || 0), 0) / gradedSubs.length : 0;

    // Session check to avoid spam
    if (sessionStorage.getItem('encouragementShown')) return;

    let msg = "";
    let type = "success";

    // Progressive encouragement logic
    if (progressPct >= 80) {
        msg = `Outstanding! You've completed ${progressPct}% of the course. You are unstoppable!`;
    } else if (progressPct >= 50) {
        msg = `Halfway There! You've completed ${progressPct}% of your tasks. Great momentum!`;
    } else if (avgScore >= 90) {
        msg = `High Performer Alert! Your average score is ${Math.round(avgScore)}%. Excellent work!`;
    } else if (completed >= 3) {
        msg = "Good Start! You're making steady progress. Keep going!";
        type = "info";
    }

    if (msg) {
        // Show a nice toast notification
        // Using existing showToast function
        if (typeof showToast === 'function') {
            showToast(msg, type);
        } else {
            console.log("Encouragement:", msg);
        }

        // If it's a big achievement, throw confetti
        if ((progressPct >= 80 || avgScore >= 90) && typeof confetti === 'function') {
            confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
        }

        sessionStorage.setItem('encouragementShown', 'true');
    }
};

// GLOBAL TOAST FUNCTION
window.showToast = function (msg, type = 'success') {
    const bgClass = type === 'error' ? 'bg-rose-600' : 'bg-slate-900 dark:bg-[#1e293b]';
    const icon = type === 'error' ? 'alert-circle' : 'bell';

    const toast = $(`<div class="fixed bottom-10 right-10 ${bgClass} text-white px-8 py-4 rounded-2xl shadow-2xl z-[5000] font-black uppercase text-[10px] tracking-widest animate-in slide-in-from-bottom-5 border border-white/10 backdrop-blur-xl flex items-center gap-3"><i data-lucide="${icon}" class="w-4 h-4 text-white"></i>${msg}</div>`);
    $('body').append(toast);
    lucide.createIcons();
    setTimeout(() => toast.fadeOut(() => toast.remove()), 3000);
};

function initDashboard() {
    if (!userProfile) {
        console.error("Critical: initDashboard called but userProfile is null.");
        showToast("System failed to load user profile. Please try logging in again.", "error");
        return;
    }
    // Ensure backwards compatibility between name and full_name
    userProfile.name = userProfile.name || userProfile.full_name || 'User';

    // OPTIMIZATION: Render "shell" and cached content IMMEDIATELY before hiding loader

    // 1. Basic Text & Profile Info
    $('#user-name').text(userProfile.name);
    $('#header-user-name').text(userProfile.name);
    $('#user-role').text(userProfile.role.toUpperCase());

    // Sidebar Mini-Profile Update
    $('#sidebar-mini-name').text(userProfile.name);
    $('#sidebar-mini-role').text(userProfile.role);

    // 2. Avatar Rendering
    const initial = userProfile.name.charAt(0).toUpperCase();
    $('#header-initial').text(initial);
    $('#profile-initial-lg').text(initial);

    // Avatar Prioritization: Cloud -> Local Fallback -> Initials
    const cachedAvatar = localStorage.getItem(`cached_avatar_${userProfile.uid || userProfile.id}`);
    const finalAvatar = userProfile.avatar_url || cachedAvatar;

    if (finalAvatar) {
        const imgTag = `<img src="${finalAvatar}" class="w-full h-full object-cover">`;
        $('#header-avatar-container').html(imgTag);
        $('#profile-avatar-display').html(imgTag);
        $('#sidebar-mini-avatar').html(imgTag);
    } else {
        $('#header-avatar-container').html(`<span id="header-initial">${initial}</span>`);
        $('#profile-avatar-display').html(`<span id="profile-initial-lg">${initial}</span>`);
        $('#sidebar-mini-avatar').text(initial);
    }

    // 3. Navigation & Mode Setup
    if (userProfile.role === 'admin') {
        $('#nav-dashboard, #nav-grading, #nav-users, #nav-leaderboard').removeClass('hidden');
        $('#admin-nav').removeClass('hidden');
        $('#nav-tasks').removeClass('hidden').html('<i data-lucide="clipboard-list" class="w-5 h-5"></i> <span class="hide-on-collapse">Manage Tasks</span>');
        // Admin Storage View
        $('#nav-storage').html('<i data-lucide="database" class="w-5 h-5"></i> <span class="hide-on-collapse">Student\'s Storage</span>').attr('data-tooltip', 'Student Files');
        $('#nav-arcade, #nav-playground, #nav-verify').addClass('hidden');
    } else {
        $('#nav-dashboard, #nav-tasks, #nav-leaderboard, #nav-resources, #profile-tab, #nav-arcade, #nav-playground, #nav-verify').removeClass('hidden');
        $('#nav-tasks').html('<i data-lucide="clipboard-list" class="w-5 h-5"></i> <span class="hide-on-collapse">My Tasks</span>');
        // Student Storage View
        $('#nav-storage').html('<i data-lucide="hard-drive" class="w-5 h-5"></i> <span class="hide-on-collapse">My Storage</span>').attr('data-tooltip', 'My Storage');
        $('#admin-nav').addClass('hidden');
    }

    // 4. Load Cached Data & Render Charts (CRITICAL FOR INSTANT FEEL)
    switchTab('dashboard');
    startSync(); // This calls loadCachedData() internally
    initChart();

    // 5. Daily Streak Logic (Local Storage - Fast)
    const today = new Date().toDateString();
    const lastLogin = localStorage.getItem('last_login_date');
    let streak = parseInt(localStorage.getItem('login_streak') || 0);

    if (lastLogin !== today) {
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        if (lastLogin === yesterday.toDateString()) streak++;
        else streak = 1;

        localStorage.setItem('last_login_date', today);
        localStorage.setItem('login_streak', streak);

        if (streak > 1) {
            showToast(`${streak} Day Streak! Keep it up!`);
            confetti({ particleCount: 50, spread: 50, origin: { y: 0.1 } });
        }
    }

    // Render Streak Badge immediately
    if ($('#streak-badge').length === 0) {
        const streakHtml = `
                    <div id="streak-badge" class="hidden sm:flex items-center gap-2 px-3 py-1.5 bg-orange-50 dark:bg-orange-900/10 border border-orange-100 dark:border-orange-500/20 rounded-xl mr-2 animate-in fade-in zoom-in duration-500">
                        <div class="p-1 bg-white dark:bg-orange-900/30 rounded-lg shadow-sm">
                            <i data-lucide="flame" class="w-3.5 h-3.5 text-orange-500 fill-orange-500 animate-pulse"></i>
                        </div>
                        <div class="flex flex-col leading-none">
                            <span class="text-[8px] font-black uppercase text-orange-400 tracking-wider mb-0.5">Day Streak</span>
                            <span class="text-xs font-black text-orange-600 dark:text-orange-400">${streak} Day${streak !== 1 ? 's' : ''}</span>
                        </div>
                    </div>
                `;
        $('#header-user-name').closest('.flex.items-center.gap-3').parent().prepend(streakHtml);
    } else {
        $('#streak-badge').find('span:last').text(`${streak} Day${streak !== 1 ? 's' : ''}`);
    }

    // 6. Live Clock (Instant)
    const updateClock = () => {
        const now = new Date();
        const hours = now.getHours();
        const greeting = hours < 12 ? "Good Morning" : hours < 18 ? "Good Afternoon" : "Good Evening";
        $('#live-clock').text(now.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true }));
        $('#live-date').text(now.toLocaleDateString('en-US', { weekday: 'long', day: 'numeric', month: 'short' }));
        $('#dynamic-greeting-text').text(`${greeting}, ${userProfile.name.split(' ')[0]}`);

        // SYNC MOBILE SIDEBAR PROFILE
        $('.mobile-user-name').text(userProfile.name);
        if (userProfile.avatar_url) {
            $('#mobile-sidebar-avatar').attr('src', userProfile.avatar_url).removeClass('hidden');
            $('.mobile-avatar-initial').addClass('hidden');
        } else {
            $('.mobile-avatar-initial').text(userProfile.name.charAt(0)).removeClass('hidden');
            $('#mobile-sidebar-avatar').addClass('hidden');
        }
    };
    updateClock();
    setInterval(updateClock, 1000);

    // 7. Initialize Icons ONCE globally for the initial view
    lucide.createIcons();

    // 8. FINAL STEP: Hide Loader NOW.
    // result: User sees fully rendered dashboard instantly.
    finishInitialization(true);
    isInitializing = false;

    // --- DEFERRED / BACKGROUND TASKS ---
    // These fetch fresh data but assume UI is already usable
    if (typeof fetchArcadeConfig === 'function') fetchArcadeConfig();
    if (typeof syncArcadeProgress === 'function') syncArcadeProgress();
    fetchNotices();
    fetchAchievements();
    if (window.setupRealtime) window.setupRealtime();



    // Re-define Award Badge (abbreviated)
    window.awardBadge = async (badgeKey) => {
        if (userProfile.role !== 'student') return;
        if (!BADGES[badgeKey]) return;
        try {
            const { error } = await client.from('user_achievements').upsert(
                { user_id: currentUser.id, badge_key: badgeKey },
                { onConflict: 'user_id, badge_key', ignoreDuplicates: true }
            );
            if (!error) {
                // Only show toast if it was a new insertion (difficult to know with upsert/ignore, 
                // but we can check local cache or just rely on the fact that existing ones won't throw error)
                // Ideally we check if it existed before, but for now we just suppress the error.
                // We will rely on fetchAchievements to update the UI correctly.
                fetchAchievements();
            }
        } catch (e) { }
    };

    // Define Badges Const
    const BADGES = {
        'first_login': { title: 'First Steps', icon: 'footprints', desc: 'Logged in for the first time.' },
        'profile_pic': { title: 'Identity', icon: 'camera', desc: 'Updated profile picture.' },
        'arcade_win': { title: 'Arcade Champion', icon: 'trophy', desc: 'Won an arcade game level.' },
        'streak_3': { title: 'On Fire', icon: 'flame', desc: 'Reached a 3-day login streak.' },
        'code_runner': { title: 'Scripter', icon: 'code-2', desc: 'Ran code in the Live Editor.' }
    };

    async function fetchAchievements() {
        try {
            const { data: userBadges, error } = await client.from('user_achievements').select('badge_key');
            if (error) throw error;
            const earnedKeys = new Set(userBadges.map(b => b.badge_key));
            renderBadges(earnedKeys);
            if (!earnedKeys.has('first_login')) awardBadge('first_login');
            if (streak >= 3 && !earnedKeys.has('streak_3')) awardBadge('streak_3');
        } catch (e) { renderBadges(new Set()); }
    }

    function renderBadges(earnedKeys) {
        const grid = $('#achievements-grid');
        grid.empty();
        Object.entries(BADGES).forEach(([key, badge]) => {
            const isUnlocked = earnedKeys.has(key);
            const opacity = isUnlocked ? 'opacity-100' : 'opacity-40 grayscale';
            const bg = isUnlocked ? 'bg-indigo-50 dark:bg-indigo-900/20 border-indigo-200 dark:border-indigo-800' : 'bg-slate-50 dark:bg-slate-900/50 border-slate-100 dark:border-slate-800';
            const iconColor = isUnlocked ? 'text-indigo-500' : 'text-slate-400';
            grid.append(`
                        <div class="p-4 ${bg} rounded-xl border flex flex-col items-center justify-center ${opacity} transition-all duration-500 group relative hover:scale-[1.02]">
                            <i data-lucide="${badge.icon}" class="w-8 h-8 ${iconColor} mb-2"></i>
                            <span class="text-[9px] font-black uppercase ${isUnlocked ? 'text-indigo-600 dark:text-indigo-300' : 'text-slate-400'} text-center">${badge.title}</span>
                            ${!isUnlocked ? '<i data-lucide="lock" class="absolute top-2 right-2 w-3 h-3 text-slate-300"></i>' : ''}
                        </div>
                    `);
        });
        lucide.createIcons();
    }

    // Check and show encouragement notification for students
    if (userProfile && userProfile.role === 'student') {
        setTimeout(() => {
            checkAndShowEncouragement();
        }, 1500); // Show after dashboard loads
    }
}



window.handleLogout = async () => {
    // 1. Trigger Full Screen Professional Loader
    $('#logout-loader').removeClass('hidden').addClass('flex');
    lucide.createIcons();

    try {
        // No race condition - await completion
        await client.auth.signOut();
    } catch (err) {
        console.warn("Logout error:", err);
    } finally {
        // Explicitly clear Supabase tokens
        Object.keys(localStorage).forEach(key => {
            if (key.startsWith('sb-') && key.endsWith('-auth-token')) {
                localStorage.removeItem(key);
            }
        });

        // Clear app-specific caches
        localStorage.removeItem('supabase_profile_cache');
        localStorage.removeItem('cached_tasks');
        localStorage.removeItem('cached_subs');

        // Clear cookies
        document.cookie.split(";").forEach((c) => {
            document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
        });

        // Immediate reload without arbitrary delay
        window.location.reload();
    }
};

// --- INSTANT LOAD CACHE SYSTEM ---
function loadCachedData() {
    const cachedTasks = localStorage.getItem('cached_tasks');
    const cachedSubs = localStorage.getItem('cached_subs');

    if (cachedTasks && cachedSubs) {
        const tasks = JSON.parse(cachedTasks);
        const subs = JSON.parse(cachedSubs);

        window.allTasks = tasks;
        window.allSubmissions = subs;

        console.log("? Instant Load from Cache triggered");
        renderStats(tasks, subs);
        if (activeTab === 'tasks') renderTasks(tasks, subs);
        if (activeTab === 'leaderboard') renderLeaderboard(subs);
        if (userProfile.role === 'admin' && activeTab === 'grading') renderGrading(subs);
    }
}

function startSync() {
    // Instant load before network fetch
    loadCachedData();
    fetchData();
    syncInterval = setInterval(fetchData, 5000);
}

// NEW: AJAX Version of fetchData
async function fetchData() {
    // Use Supabase Client SDK instead of raw AJAX for better stability & auth handling
    const { data: { session } } = await client.auth.getSession();
    if (!session) return;

    try {
        const [tasksRes, subsRes] = await Promise.all([
            client.from('tasks').select('*').order('deadline', { ascending: true }),
            client.from('submissions').select('*')
        ]);

        if (tasksRes.error) throw tasksRes.error;
        if (subsRes.error) throw subsRes.error;

        const tasks = tasksRes.data;
        const subs = subsRes.data;

        window.allTasks = tasks;
        window.allSubmissions = subs;

        // SAVE TO CACHE FOR NEXT LOAD
        localStorage.setItem('cached_tasks', JSON.stringify(tasks));
        localStorage.setItem('cached_subs', JSON.stringify(subs));

        renderStats(tasks, subs);
        if (activeTab === 'tasks') renderTasks(tasks, subs);
        if (activeTab === 'leaderboard') renderLeaderboard(subs);
        if (userProfile.role === 'admin') {
            if (activeTab === 'grading') renderGrading(subs);
            // fetchUsers is called separately when needed/tab switches, to save bandwidth
            if (activeTab === 'users') fetchUsers();

            // Update feedback notification badge
            checkFeedbackCount();
        }
    } catch (err) {
        console.error("Data Sync Error:", err);
        // Reduce noise, only alert on critical failures that persist
    }
    // Live Chart Update
    if (activeTab === 'dashboard' && performanceChart) updateChart();
}
function renderStats(tasks, subs) {
    const isStudent = userProfile.role === 'student';

    if (isStudent) {
        const mySubs = subs.filter(s => s.student_id === currentUser.id);
        const total = tasks.length;
        const completed = mySubs.filter(s => s.status === 'graded').length;
        const progressPct = total ? Math.round((mySubs.length / total) * 100) : 0;
        const avgScore = mySubs.filter(s => s.status === 'graded').reduce((a, b) => a + (parseInt(b.grade) || 0), 0) / (mySubs.filter(s => s.status === 'graded').length || 1);

        const pendingCount = tasks.filter(t => {
            const isSubmitted = mySubs.some(s => s.task_id === t.id);
            // Also check if it's graded - if so, it's definitely not pending
            const isGraded = mySubs.some(s => s.task_id === t.id && s.status === 'graded');
            const isExpired = t.deadline && new Date().getTime() > new Date(t.deadline).getTime();
            return !isGraded && !isSubmitted && !isExpired;
        }).length;
        $('#stat-label-1').text("Pending Tasks"); $('#stat-active').text(pendingCount);
        $('#stat-label-2').text("Completed"); $('#stat-completed').text(completed);
        $('#stat-label-3').text("Avg. Grade"); $('#stat-score').text(Math.round(avgScore) + '%');

        // --- 1. Pending Tasks Popup Logic ---
        if (pendingCount > 0 && !sessionStorage.getItem('pendingAlertShown')) {
            sessionStorage.setItem('pendingAlertShown', 'true');
            // Create and show modal dynamically
            const modalId = 'pending-task-modal-' + Date.now();
            const modalHtml = `
                        <div class="modal fade" id="${modalId}" tabindex="-1" aria-hidden="true" data-bs-backdrop="static">
                            <div class="modal-dialog modal-dialog-centered">
                                <div class="modal-content border-0 rounded-3xl shadow-2xl bg-white dark:bg-[#0f172a] overflow-hidden">
                                     <!-- Clean Header Strip -->
                                     <div class="h-1.5 w-full bg-gradient-to-r from-indigo-500 to-purple-600"></div>

                                     <div class="p-8 pb-6">
                                        <div class="flex items-start gap-5">
                                            <!-- Icon Box -->
                                            <div class="w-14 h-14 rounded-2xl bg-indigo-50 dark:bg-indigo-900/20 text-indigo-600 dark:text-indigo-400 flex items-center justify-center shrink-0">
                                                 <i data-lucide="clipboard-list" class="w-7 h-7"></i>
                                            </div>
                                            
                                            <div class="flex-1">
                                                <h3 class="text-xl font-black text-slate-900 dark:text-white uppercase tracking-tight leading-none mb-2">Attention Required</h3>
                                                <p class="text-xs text-slate-500 dark:text-slate-400 font-medium leading-relaxed">
                                                    You have <span class="text-indigo-600 dark:text-indigo-400 font-bold">${pendingCount} pending task${pendingCount > 1 ? 's' : ''}</span> waiting for your submission. Consistent effort is the key to mastery!
                                                </p>
                                            </div>
                                        </div>

                                        <!-- Mini Progress Preview -->
                                        <div class="mt-8 mb-6 p-4 rounded-xl bg-slate-50 dark:bg-[#1e293b] border border-slate-100 dark:border-slate-800/50">
                                            <div class="flex justify-between items-end mb-2">
                                                <span class="text-[9px] font-black uppercase tracking-widest text-slate-400">Current Progress</span>
                                                <span class="text-[10px] font-bold text-slate-700 dark:text-slate-300">${progressPct}% Complete</span>
                                            </div>
                                            <div class="h-2 w-full bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden">
                                                <div class="h-full bg-indigo-500 rounded-full" style="width: ${progressPct}%"></div>
                                            </div>
                                        </div>

                                        <div class="grid grid-cols-2 gap-3">
                                             <button data-bs-dismiss="modal" class="py-3.5 rounded-xl border border-slate-200 dark:border-slate-700 text-slate-500 dark:text-slate-400 text-[10px] font-black uppercase tracking-widest hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">
                                                Remind Later
                                             </button>
                                             <button onclick="switchTab('tasks'); bootstrap.Modal.getInstance(document.getElementById('${modalId}')).hide();" class="py-3.5 rounded-xl bg-indigo-600 text-white text-[10px] font-black uppercase tracking-widest hover:bg-indigo-700 shadow-lg shadow-indigo-500/30 transition-all flex items-center justify-center gap-2">
                                                View Tasks <i data-lucide="arrow-right" class="w-3.5 h-3.5"></i>
                                             </button>
                                        </div>
                                     </div>
                                </div>
                            </div>
                        </div>`;
            $('body').append(modalHtml);
            const modalEl = document.getElementById(modalId);
            const modal = new bootstrap.Modal(modalEl);
            modalEl.addEventListener('shown.bs.modal', () => lucide.createIcons());
            modal.show();
        }

        // --- 2. Motivational Banner Logic ---
        $('#student-alerts').removeClass('hidden');
        let msg = "Every step counts! Keep pushing forward to reach your goals.";
        let accentColor = "indigo";

        if (progressPct < 30) {
            msg = "Beginnings are always hardest. Believe in yourself and tackle those tasks!";
            accentColor = "rose"; // Warning/Urgency
        } else if (progressPct >= 30 && progressPct < 60) {
            msg = "You're making solid progress! Consistency is the key to mastery. Keep it up!";
            accentColor = "indigo"; // Steady
        } else if (progressPct >= 60 && progressPct < 90) {
            msg = "You are doing amazing! You're well on your way to becoming an expert.";
            accentColor = "violet"; // High achievement
        } else if (progressPct >= 90) {
            msg = "Outstanding! You are a true champion. Limitless potential!";
            accentColor = "emerald"; // Success
        }
        // Level System Logic
        const totalXP = mySubs.filter(s => s.status === 'graded').reduce((a, b) => a + (parseInt(b.grade) || 0), 0);
        const level = Math.floor(totalXP / 100) + 1;
        const xpProgress = totalXP % 100;
        const ranks = ["Newbie", "Apprentice", "Novice", "Scholar", "Expert", "Master", "Legend"];
        const rankName = ranks[Math.min(level - 1, ranks.length - 1)];

        if (userProfile.role === 'student') {
            $('#student-level-ui').removeClass('hidden').addClass('flex');
            $('#rank-name').text(`${rankName} (Lvl ${level})`);

            // Simple animation for the bar
            setTimeout(() => {
                $('#xp-bar').css('width', `${xpProgress}%`);
                $('#xp-bar-bg').css('transform', `scaleY(${xpProgress / 100})`);
            }, 500);
        } else {
            $('#student-level-ui').addClass('hidden');
        }

        $('#student-alert-msg').text(msg);
        $('#student-alerts > div').removeClass('border-l-indigo-500 border-l-rose-500 border-l-cyan-500 bg-indigo-500/5 bg-rose-500/5 bg-cyan-500/5').addClass(`border-l-${accentColor}-500 bg-${accentColor}-500/5`);

        // Recent Activity
        const list = $('#recent-activity-list').empty();
        const cutoff = new Date(new Date().getTime() - 24 * 60 * 60 * 1000);
        const recentSubs = mySubs.filter(s => new Date(s.submitted_at) > cutoff).slice(0, 4);

        if (!recentSubs.length) list.html('<div class="text-center py-10 text-slate-400 font-black uppercase tracking-widest text-[9px] italic border-2 border-dashed border-slate-100 dark:border-slate-800 rounded-3xl">No recent activity (24h)</div>');
        recentSubs.forEach(s => {
            const isGraded = s.status === 'graded';
            list.append(`
                        <div class="flex items-center gap-4 p-4 rounded-xl bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-slate-800 hover:border-indigo-500/50 transition-all group">
                            <div class="w-12 h-12 rounded-xl ${isGraded ? 'bg-emerald-500/10 text-emerald-500' : 'bg-indigo-500/10 text-indigo-500'} flex items-center justify-center transition-transform group-hover:scale-105 shadow-sm">
                                <i data-lucide="${isGraded ? 'check-circle' : 'clock'}" class="w-5 h-5"></i>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="text-[10px] font-black text-slate-900 dark:text-indigo-400 truncate uppercase tracking-tight leading-none mb-1.5">${s.task_title}</p>
                                <p class="text-[8px] text-slate-400 font-black uppercase tracking-[0.15em] leading-none">${s.status}</p>
                            </div>
                            ${isGraded ? `<div class="font-black text-base text-indigo-500 tracking-tighter">${s.grade}%</div>` : ''}
                        </div>
                    `);
        });
    } else {
        // ADMIN DASHBOARD LOGIC

        // DEDUPLICATION LOGIC:
        // We must group by (student_id + task_id) and keep only the LATEST submission.
        const uniqueSubsMap = new Map();
        subs.forEach(s => {
            const key = `${s.student_id}_${s.task_id}`;
            const existing = uniqueSubsMap.get(key);
            // If no entry exists, or this one is newer, update it
            if (!existing || new Date(s.submitted_at) > new Date(existing.submitted_at)) {
                uniqueSubsMap.set(key, s);
            }
        });
        const uniqueSubs = Array.from(uniqueSubsMap.values());

        // FIX: Filter only ACTIVE tasks (not expired) for the count
        const activeTasksCount = tasks.filter(t => {
            // Active = No deadline OR Deadline is in the future
            return !t.deadline || new Date(t.deadline) > new Date();
        }).length;

        $('#stat-label-1').text("Active Tasks"); $('#stat-active').text(activeTasksCount);

        // Stat 2: Total unique verified submissions (Graded or Pending)
        $('#stat-label-2').text("Total Submissions");
        $('#stat-completed').text(uniqueSubs.length);

        // Stat 3: Pending Review (Only if latest status is 'submitted')
        const pending = uniqueSubs.filter(s => s.status === 'submitted').length;

        $('#stat-label-3').text("Pending Review"); $('#stat-score').text(pending);
        $('#student-alerts').addClass('hidden');

        // Intelligent Notification Logic (Watermark System):
        const watermark = parseInt(localStorage.getItem('notification_watermark') || '0');
        window.lastPendingCountVal = pending; // Store for markAllRead

        // 1. Trigger: Only un-clear if we have MORE items than our watermark (suppressed count)
        if (pending > watermark) {
            localStorage.setItem('notifications_cleared', 'false');
        }

        // 2. Adaptation: If items are removed (graded), lower the watermark 
        // so that incoming new items (even if total count is same as old watermark) trigger a notif.
        if (pending < watermark) {
            localStorage.setItem('notification_watermark', pending);
        }

        // Legacy support cleanup
        localStorage.removeItem('last_pending_count');

        // Update Notification Badge
        const badge = $('#notif-badge');
        const isCleared = localStorage.getItem('notifications_cleared') === 'true';

        if (pending > 0 && !isCleared) {
            badge.removeClass('hidden').addClass('flex items-center justify-center');
            badge.text(pending > 9 ? '9+' : pending);
        } else {
            badge.addClass('hidden').removeClass('flex');
        }

        // Global Recent Activity for Admins (Deduplicated)
        const list = $('#recent-activity-list').empty();
        const cutoff = new Date(new Date().getTime() - 24 * 60 * 60 * 1000);

        // Sort unique subs by date desc AND filter last 24h
        const latest = uniqueSubs
            .filter(s => new Date(s.submitted_at) > cutoff)
            .sort((a, b) => new Date(b.submitted_at) - new Date(a.submitted_at))
            .slice(0, 4);

        if (!latest.length) list.html('<div class="text-center py-10 text-slate-400 font-black uppercase tracking-widest text-[9px] italic border-2 border-dashed border-slate-100 dark:border-slate-800 rounded-3xl">No student activity (24h)</div>');
        latest.forEach(s => {
            const isGraded = s.status === 'graded';
            list.append(`
                        <div class="flex items-center gap-4 p-4 rounded-xl bg-slate-50 dark:bg-slate-900 border border-slate-100 dark:border-slate-800 hover:border-indigo-500/50 transition-all group cursor-pointer" onclick="switchTab('grading')">
                            <div class="w-10 h-10 rounded-xl ${isGraded ? 'bg-emerald-500/10 text-emerald-500' : 'bg-amber-500/10 text-amber-500'} flex items-center justify-center shadow-sm">
                                <i data-lucide="user" class="w-4 h-4"></i>
                            </div>
                            <div class="flex-1 min-w-0">
                                <p class="text-[10px] font-black text-slate-900 dark:text-indigo-400 truncate uppercase tracking-tight leading-none mb-1.5">${s.student_name}</p>
                                <p class="text-[8px] text-slate-400 font-black uppercase tracking-[0.15em] leading-none">Submitted: ${s.task_title}</p>
                            </div>
                            <div class="text-[7px] font-black bg-indigo-50 dark:bg-indigo-900/40 text-indigo-600 dark:text-indigo-300 px-2 py-1 rounded-md uppercase tracking-tighter">${s.status}</div>
                        </div>
                    `);
        });
    }
    lucide.createIcons();
}

window.filterTasks = (type) => {
    // Update Radio UI (useful if called programmatically)
    if (type === 'all') $('#radio-1').prop('checked', true);
    else if (type === 'pending') $('#radio-2').prop('checked', true);
    else if (type === 'completed') $('#radio-3').prop('checked', true);
    else if (type === 'expired') $('#radio-4').prop('checked', true);

    window.currentTaskFilter = type;
    renderTasks(window.allTasks, window.allSubmissions, type);
};

function renderTasks(tasks, subs, filter = 'all') {
    // ADMIN: Hide filters, show all
    if (userProfile.role === 'admin') {
        $('.task-tabs-container').parent().addClass('hidden');
        filter = 'all';
    } else {
        $('.task-tabs-container').parent().removeClass('hidden');
    }

    const container = $('#task-grid').empty();
    let filteredTasks = tasks;

    // 0. Auto-Hide Old Tasks (Clutter Reduction)
    // Hides tasks created >7 days ago from the main 'All' view, unless searched/filtered specifically
    if (filter === 'all') {
        const cleanupDate = new Date();
        cleanupDate.setDate(cleanupDate.getDate() - 7);
        filteredTasks = tasks.filter(t => new Date(t.created_at) > cleanupDate);
    }

    // 1. Status Filter
    if (filter === 'pending') {
        filteredTasks = tasks.filter(t => {
            const isSubmitted = subs.find(s => s.student_id === currentUser?.id && s.task_id === t.id);
            const isExpired = t.deadline && new Date().getTime() > new Date(t.deadline).getTime();
            return !isSubmitted && !isExpired;
        });
    } else if (filter === 'completed') {
        filteredTasks = tasks.filter(t => subs.find(s => s.student_id === currentUser?.id && s.task_id === t.id));
    } else if (filter === 'expired') {
        filteredTasks = tasks.filter(t => t.deadline && new Date().getTime() > new Date(t.deadline).getTime());
    }

    // 2. Search Filter
    const query = $('#task-search').val()?.toLowerCase() || '';
    if (query) {
        filteredTasks = filteredTasks.filter(t => t && t.title && (t.title.toLowerCase().includes(query) || (t.description && t.description.toLowerCase().includes(query))));
    }

    // 3. Empty State
    if (filteredTasks.length === 0) {
        container.html(`
                    <div class="col-span-full py-16 text-center animate-in fade-in zoom-in duration-500">
                        <div class="w-16 h-16 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center mx-auto mb-4">
                            <i data-lucide="clipboard-x" class="w-8 h-8 text-slate-400"></i>
                        </div>
                        <h3 class="text-lg font-black uppercase tracking-tighter text-slate-900 dark:text-slate-200 mb-1">No Tasks Found</h3>
                        <p class="text-[10px] font-bold uppercase tracking-widest text-slate-400">Try adjusting your filters.</p>
                    </div>
                `);
        lucide.createIcons();
        return;
    }

    filteredTasks.forEach(t => {
        if (!t) return;
        let taskCardContent = '';
        const isExpired = t.deadline ? (new Date().getTime() > new Date(t.deadline).getTime()) : false;

        if (userProfile.role === 'admin') {
            // --- ADMIN VIEW (Simplified) ---
            // Calculate stats for this task (DEDUPLICATED)
            const uniqueTaskSubsMap = new Map();
            subs.filter(s => s.task_id === t.id).forEach(s => {
                const existing = uniqueTaskSubsMap.get(s.student_id);
                if (!existing || new Date(s.submitted_at) > new Date(existing.submitted_at)) {
                    uniqueTaskSubsMap.set(s.student_id, s);
                }
            });
            const uniqueTaskSubs = Array.from(uniqueTaskSubsMap.values());

            const submissionCount = uniqueTaskSubs.filter(s => s.status === 'submitted' || s.status === 'graded').length;
            const gradedCount = uniqueTaskSubs.filter(s => s.status === 'graded').length;
            const avgScore = gradedCount ? Math.round(uniqueTaskSubs.filter(s => s.status === 'graded').reduce((a, b) => a + b.grade, 0) / gradedCount) : 0;

            taskCardContent = `
                        <div class="v-card p-5 group transition-transform hover:-translate-y-1 bg-white dark:bg-[#1e293b] animate-in fade-in slide-in-from-bottom-4 border dark:border-slate-800 relative overflow-hidden">
                             <div class="absolute top-0 right-0 p-3 opacity-10 group-hover:opacity-100 transition-opacity">
                                <i data-lucide="layout-grid" class="w-12 h-12 text-indigo-500"></i>
                             </div>
                            
                             <div class="flex justify-between items-start mb-4 gap-3 relative z-10">
                                <span class="px-3 py-1 rounded-lg text-[7px] font-black uppercase tracking-[0.15em] bg-slate-100 dark:bg-slate-800 text-slate-500 shadow-sm">ID: ${t.id.substring(0, 6)}</span>
                                <div class="text-[7px] font-black text-indigo-500 uppercase tracking-[0.15em] flex items-center gap-1 bg-indigo-50 dark:bg-indigo-900/30 px-2 py-1.5 rounded-lg">
                                    <i data-lucide="calendar" class="w-2.5 h-2.5"></i> ${t.deadline ? new Date(t.deadline).toLocaleString([], { year: 'numeric', month: 'numeric', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : 'No Date'}
                                </div>
                            </div>
                            
                            <h4 class="font-black text-lg text-slate-900 dark:text-slate-200 mb-2 uppercase tracking-tighter leading-none relative z-10 pr-8 line-clamp-1">${window.fixEncoding(t.title || '').replace(/</g, '&lt;').replace(/>/g, '&gt;')}</h4>
                            <p class="text-[9px] text-slate-500 dark:text-slate-400 line-clamp-1 mb-4 font-medium leading-relaxed tracking-tight uppercase relative z-10">${window.fixEncoding(t.description || '').replace(/</g, '&lt;').replace(/>/g, '&gt;')}</p>
                            
                            <!-- Admin Stats Grid -->
                            <div class="grid grid-cols-3 gap-2 mb-6 relative z-10">
                                <div class="p-2 bg-slate-50 dark:bg-slate-900 rounded-lg text-center border border-slate-100 dark:border-slate-800">
                                    <div class="text-[7px] font-black text-slate-400 uppercase tracking-widest mb-0.5">Total</div>
                                    <div class="text-sm font-black text-slate-900 dark:text-slate-200">${submissionCount}</div>
                                </div>
                                <div class="p-2 bg-slate-50 dark:bg-slate-900 rounded-lg text-center border border-slate-100 dark:border-slate-800">
                                    <div class="text-[7px] font-black text-slate-400 uppercase tracking-widest mb-0.5">Graded</div>
                                    <div class="text-sm font-black text-indigo-500">${gradedCount}</div>
                                </div>
                                <div class="p-2 bg-slate-50 dark:bg-slate-900 rounded-lg text-center border border-slate-100 dark:border-slate-800">
                                    <div class="text-[7px] font-black text-slate-400 uppercase tracking-widest mb-0.5">Avg %</div>
                                    <div class="text-sm font-black text-emerald-500">${avgScore}%</div>
                                </div>
                            </div>

                            <div class="flex gap-3 pt-4 border-t border-slate-100 dark:border-slate-800 relative z-10">
                                <button onclick="window.openDetail('${t.id}')" class="flex-1 py-2.5 rounded-lg bg-indigo-50 dark:bg-indigo-900/20 text-indigo-600 dark:text-indigo-400 text-[8px] font-black uppercase tracking-widest hover:bg-indigo-100 dark:hover:bg-indigo-900/40 transition-all flex items-center justify-center gap-2">
                                    <i data-lucide="eye" class="w-3 h-3"></i> View
                                </button>
                                <button onclick="openEditTaskModal('${t.id}')" class="flex-1 py-2.5 rounded-lg bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400 text-[8px] font-black uppercase tracking-widest hover:bg-emerald-100 dark:hover:bg-emerald-900/40 transition-all flex items-center justify-center gap-2">
                                    <i data-lucide="edit-2" class="w-3 h-3"></i> Edit
                                </button>
                                <button onclick="deleteTask('${t.id}')" class="flex-1 py-2.5 rounded-lg bg-rose-50 dark:bg-rose-900/20 text-rose-600 dark:text-rose-400 text-[8px] font-black uppercase tracking-widest hover:bg-rose-100 dark:hover:bg-rose-900/40 transition-all flex items-center justify-center gap-2">
                                     <i data-lucide="trash-2" class="w-3 h-3"></i>
                                </button>
                            </div>
                        </div>`;
        } else {
            // --- STUDENT VIEW (Simplified for "Details Kam Dikhao") ---
            const sub = subs.find(s => s.student_id === currentUser?.id && s.task_id === t.id);
            let badgeClass = sub ? (sub.status === 'graded' ? 'bg-emerald-500 text-white shadow-emerald-500/20' : 'bg-cyan-500 text-white shadow-cyan-500/20') : (isExpired ? 'bg-rose-500 text-white shadow-rose-500/20' : 'bg-indigo-600 text-white shadow-indigo-500/20');
            let badgeText = sub ? (sub.status === 'graded' ? `SCORE: ${sub.grade}%` : 'SUBMITTED') : (isExpired ? 'EXPIRED' : 'ACTIVE');

            taskCardContent = `
                        <div class="v-card p-5 group cursor-pointer border hover:border-indigo-500 hover:shadow-xl transition-all duration-500 bg-white dark:bg-[#1e293b] animate-in fade-in slide-in-from-bottom-4 glow-border" onclick="openDetail('${t.id}')">
                            <div class="flex justify-between items-start mb-4 gap-3">
                                <span class="px-3 py-1 rounded-lg text-[7px] font-black uppercase tracking-[0.15em] ${badgeClass} shadow-md transition-transform group-hover:scale-105">${badgeText}</span>
                                <div class="text-[7px] font-black text-slate-400 uppercase tracking-[0.15em] flex items-center gap-1 bg-slate-50 dark:bg-[#2d3748] px-2 py-1.5 rounded-lg shadow-inner whitespace-nowrap">
                                    <i data-lucide="calendar" class="w-2.5 h-2.5 text-indigo-500"></i> ${t.deadline ? new Date(t.deadline).toLocaleDateString() : 'No Deadline'}
                                </div>
                            </div>
                            <h4 class="font-black text-lg text-slate-900 dark:text-indigo-400 mb-2 group-hover:text-indigo-500 transition-colors uppercase tracking-tighter leading-none break-words line-clamp-1">${window.fixEncoding(t.title)}</h4>
                            <p class="text-[9px] text-slate-500 dark:text-slate-400 mb-4 font-medium leading-relaxed tracking-tight line-clamp-2 w-full h-8 overflow-hidden">${window.fixEncoding(t.description || '').split('<br><strong>Reference Asset:')[0].replace(/</g, '&lt;').replace(/>/g, '&gt;')}</p>
                            
                            <!-- Simplified: Tags & Reference Indicator Hidden in List View for cleaner Look -->

                            <div class="w-full h-1.5 bg-slate-100 dark:bg-[#0b1120] rounded-full overflow-hidden shadow-inner flex items-center px-0.5 mt-auto">
                                <div class="h-1 bg-gradient-to-r from-indigo-500 to-cyan-400 rounded-full transition-all duration-[1.5s]" style="width: ${sub ? '100%' : '30%'}"></div>
                            </div>
                        </div>`;
        }
        container.append(taskCardContent);
    });
    lucide.createIcons();
}

function renderLeaderboard(subs) {
    const container = $('#leaderboard-body').empty();

    if (!subs || !subs.length) {
        container.html(`
                    <tr>
                        <td colspan="5" class="py-8 text-center text-slate-400 text-[10px] font-black uppercase tracking-widest italic">
                            No active students found on the leaderboard.
                        </td>
                    </tr>
                `);
        return;
    }

    const students = Array.from(new Set(subs.map(s => s.student_id)));
    const rankings = students.map(sid => {
        // User Request: Only count GRADED tasks for Leaderboard visibility & ranking
        // User Request: Count unique tasks only (ignore resubmissions)

        const myGradedSubs = subs.filter(s => s.student_id === sid && s.status === 'graded');

        // Deduplicate by task_id: Keep the one with the HIGHEST grade
        const uniqueTasksMap = new Map();
        myGradedSubs.forEach(s => {
            const existing = uniqueTasksMap.get(s.task_id);
            if (!existing || s.grade > existing.grade) {
                uniqueTasksMap.set(s.task_id, s);
            }
        });

        const uniqueGradedSubs = Array.from(uniqueTasksMap.values());
        const count = uniqueGradedSubs.length;

        // If count is 0, this student won't show up (filtered later)
        const avg = count > 0 ? Math.round(uniqueGradedSubs.reduce((a, b) => a + b.grade, 0) / count) : 0;

        // Robust name finding
        const studentSub = subs.find(s => s.student_id === sid);
        const sName = studentSub && studentSub.student_name ? studentSub.student_name : 'Unknown Student';

        return {
            name: sName,
            count: count,
            avg: avg
        };
    })
        .filter(r => r.count > 0) // Hide students with NO graded tasks
        .sort((a, b) => b.avg - a.avg || b.count - a.count); // Rank by Marks (Avg) FIRST, then Quantity

    const totalTasks = window.allTasks ? window.allTasks.length : 0;

    rankings.forEach((r, i) => {
        const badgeColor = i === 0 ? 'bg-amber-100 text-amber-600' : (i === 1 ? 'bg-slate-300 text-slate-600' : (i === 2 ? 'bg-orange-100 text-orange-600' : 'bg-slate-50 text-slate-400'));
        const progress = totalTasks > 0 ? Math.round((r.count / totalTasks) * 100) : 0;

        container.append(`
                    <tr class="hover:bg-slate-50 dark:hover:bg-[#1e293b]/50 transition-colors border-b border-slate-50 dark:border-slate-800/50 group">
                        <td class="px-6 py-4">
                            <div class="w-8 h-8 rounded-lg ${i < 3 ? 'bg-indigo-600 text-white font-black shadow-lg shadow-indigo-500/20' : 'bg-slate-100 dark:bg-[#2d3748] text-slate-400 font-bold'} flex items-center justify-center text-[10px] tracking-tighter">#0${i + 1}</div>
                        </td>
                        <td class="px-6 py-4">
                            <div class="font-black text-slate-900 dark:text-indigo-400 uppercase tracking-tight text-xs flex items-center gap-2">
                                ${i < 3 ? `<i data-lucide="trophy" class="w-3.5 h-3.5 ${i === 0 ? 'text-amber-500' : (i === 1 ? 'text-slate-400' : 'text-orange-500')}"></i>` : ''}
                                ${r.name}
                            </div>
                        </td>
                        <td class="px-6 py-4 font-black text-slate-400 text-[9px] uppercase tracking-widest text-center hidden sm:table-cell">${r.count} / ${totalTasks} Tasks</td>
                        <td class="px-6 py-4 text-center"><span class="px-3 py-1 bg-indigo-50 dark:bg-indigo-900/40 text-indigo-600 dark:text-indigo-300 rounded-lg font-black text-xs shadow-sm">${r.avg}%</span></td>
                        <td class="px-6 py-4">
                            <div class="w-24 ml-auto flex flex-col items-end gap-1">
                                <div class="w-full h-1.5 bg-slate-100 dark:bg-slate-700 rounded-full overflow-hidden">
                                    <div class="h-full bg-cyan-500 rounded-full" style="width: ${progress}%"></div>
                                </div>
                                <span class="text-[8px] font-black text-cyan-500">${progress}% Complete</span>
                            </div>
                        </td>
                    </tr>
                `);
    });
    lucide.createIcons();
}

// Helper to force download for Cloudinary raw files
function formatDownloadUrl(url) {
    if (!url) return "#";
    if (url.includes("cloudinary.com") && url.includes("/raw/upload/")) {
        return url.replace("/raw/upload/", "/raw/upload/fl_attachment/");
    }
    return url;
}

// Helper to parse submission content (String vs JSON)
function parseSubmission(content) {
    try {
        if (content.trim().startsWith('{')) return JSON.parse(content);
    } catch (e) { }
    return { file: content }; // Legacy fallback
}

// --- TASK DETAIL MODAL LOGIC (FIXED) ---
window.openDetail = async (tid) => {
    if (!tid) return;
    const taskIdStr = String(tid);

    // Find task using string comparison
    const t = window.allTasks.find(x => String(x.id) === taskIdStr);
    if (!t) {
        console.error("Task not found for ID:", tid);
        return;
    }
    window.currentTask = t;
    console.log("Opening details for:", t.id, t.title);

    $('#detail-title').text(t.title);
    // Render Description: Handle Mixed Content (User Text + System HTML)
    const descEl = $('#detail-desc');
    let rawDesc = t.description || 'No description provided.';
    const refMarker = '<br><strong>Reference Asset:</strong>';

    // Helper to unescape ONLY if double-escaped (e.g. from DB)
    const decodeHtml = (html) => {
        const txt = document.createElement("textarea");
        txt.innerHTML = html;
        return txt.value;
    };

    // Check if content is escaped in DB (contains &lt;)
    const isEscaped = rawDesc.includes('&lt;');
    // If escaped, we assume the whole string is escaped including the refMarker.
    // But refMarker might be encoded as &lt;br&gt; or <br> depending on save method.

    if (rawDesc.includes(refMarker) || (isEscaped && rawDesc.includes('&lt;br&gt;&lt;strong&gt;Reference Asset:'))) {
        // Determine split point
        const marker = rawDesc.includes(refMarker) ? refMarker : '&lt;br&gt;&lt;strong&gt;Reference Asset:';
        const parts = rawDesc.split(marker);

        let userPart = parts[0];
        let sysPart = marker + parts.slice(1).join(marker); // Reconstruct system part

        // If DB was escaped, we need to unescape the User Part so .text() doesn't double-escape it
        if (isEscaped) userPart = decodeHtml(userPart);

        // System Part is HTML. If it was escaped, we MUST unescape it to make it clickable.
        if (isEscaped) sysPart = decodeHtml(sysPart);

        descEl.empty().text(userPart).append(sysPart);
    } else {
        // No reference asset. Just render as text to preserve code tags.
        // If DB is escaping it, we unescape first.
        if (isEscaped) rawDesc = decodeHtml(rawDesc);
        descEl.text(rawDesc);
    }

    // Render Tags
    const tags = (t.tags && (Array.isArray(t.tags) ? t.tags : (typeof t.tags === 'string' ? t.tags.split(',') : []))) || [];
    if (tags.length > 0) {
        const tagsHtml = tags.map(tag =>
            `<span class="px-2.5 py-1 rounded-md bg-indigo-50 dark:bg-indigo-900/30 text-[10px] font-black uppercase tracking-widest text-indigo-600 dark:text-indigo-400 border border-indigo-100 dark:border-indigo-800">${tag.trim()}</span>`
        ).join('');
        $('#detail-tags').html(tagsHtml).removeClass('hidden');
    } else {
        $('#detail-tags').empty().addClass('hidden');
    }
    $('#detail-hints').html(formatTeacherHints(t.hints));

    // SHOW LOADER IN FOOTER
    // This prevents the "New Form" from flashing or appearing falsely while we check the DataBase
    const footer = $('#submission-section');

    // TRACKING: Update Activity
    if (typeof window.updateActivity === 'function') {
        const taskTitle = t.title ? t.title.substring(0, 15) + (t.title.length > 15 ? '...' : '') : 'Task';
        window.updateActivity(`Viewing Task: ${taskTitle}`);
    }

    footer.html(`
                <div class="py-10 text-center flex flex-col items-center justify-center animate-in fade-in">
                    <i data-lucide="loader-2" class="w-6 h-6 text-indigo-500 animate-spin mb-3"></i>
                    <p class="text-[9px] font-black uppercase tracking-[0.2em] text-indigo-400">Verifying Submission...</p>
                </div>
            `).removeClass('hidden');
    lucide.createIcons();

    // ROBUST SUBMISSION FINDER (Async)
    const findSub = async () => {
        // 1. Try Local Cache First (Fastest)
        if (window.allSubmissions) {
            const cached = window.allSubmissions.find(s =>
                s.student_id === currentUser?.id &&
                String(s.task_id) === taskIdStr
            );
            if (cached) return cached;
        }

        // 2. Direct DB Fetch (Fallback)
        // This guarantees we find it if it exists in Supabase
        if (currentUser) {
            try {
                // Create a timeout promise for this specific check
                const timeoutCheck = new Promise((_, reject) =>
                    setTimeout(() => reject(new Error("Sub check timeout")), 5000)
                );

                const { data, error } = await Promise.race([
                    client.from('submissions')
                        .select('*')
                        .eq('task_id', taskIdStr)
                        .eq('student_id', currentUser.id)
                        .maybeSingle(),
                    timeoutCheck
                ]);

                if (error) console.warn("Submission Check Error:", error);
                if (data) {
                    // Sync to cache so we don't fetch again next time
                    if (window.allSubmissions) window.allSubmissions.push(data);
                    return data;
                }
            } catch (err) {
                console.error("Network Error during submission check:", err);
            }
        }
        return null;
    };

    const sub = await findSub();
    window.currentSub = sub; // Store for global access

    if (t.hints) $('#detail-guidance').removeClass('hidden'); else $('#detail-guidance').addClass('hidden');

    // Timer Logic
    if (window.detailTimer) clearInterval(window.detailTimer);
    if (t.deadline) {
        const deadline = new Date(t.deadline).getTime();
        window.detailTimer = setInterval(() => {
            const now = new Date().getTime();
            const dist = deadline - now;
            if (dist < 0) {
                $('#detail-time-container').text("EXPIRED").addClass('text-rose-500');
            } else {
                const days = Math.floor(dist / (1000 * 60 * 60 * 24));
                const hours = Math.floor((dist % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
                const mins = Math.floor((dist % (1000 * 60 * 60)) / (1000 * 60));
                $('#detail-time-container').text(`${days}d ${hours}h ${mins}m`).removeClass('text-rose-500');
            }
        }, 1000);
    } else {
        $('#detail-time-container').text("No Deadline");
    }



    // ADMIN VIEW IN MODAL
    if (userProfile.role === 'admin') {
        footer.html(`
                    <div class="p-6 bg-indigo-50 dark:bg-indigo-900/20 rounded-xl border border-indigo-100 dark:border-indigo-800 text-center">
                        <i data-lucide="shield-check" class="w-8 h-8 text-indigo-500 mx-auto mb-2"></i>
                        <p class="text-xs font-bold text-indigo-800 dark:text-indigo-300">Admin Mode Preview</p>
                        <p class="text-[9px] text-indigo-400 uppercase tracking-widest mt-1">This is how students see the task.</p>
                    </div>`);
    }
    // STUDENT VIEW IN MODAL
    else if (sub) {
        // Already Submitted View -> Use the Helper Function
        if (sub.status === 'graded') {
            // Graded View (Keep separate as it has feedback/score)
            const feedbackHtml = `
                        <div class="mt-4 p-4 bg-emerald-50 dark:bg-emerald-900/20 rounded-xl border border-emerald-100 dark:border-emerald-800">
                            <h6 class="font-black text-emerald-700 dark:text-emerald-400 uppercase tracking-widest text-[9px] mb-1">Teacher Feedback</h6>
                            <p class="text-xs text-emerald-900 dark:text-emerald-100 italic">"${sub.feedback}"</p>
                            <div class="mt-2 font-black text-2xl text-emerald-600">${sub.grade}/100</div>
                         <button onclick="downloadReport('${sub.task_id}')" class="mt-3 w-full py-2 bg-white border border-emerald-200 text-emerald-600 hover:bg-emerald-50 rounded-lg text-xs font-bold uppercase tracking-widest flex items-center justify-center gap-2 transition-all">
                            <i data-lucide="file-down" class="w-4 h-4"></i> PDF Report
                        </button>
                    </div>`;

            footer.html(`
                    <div class="text-center py-6">
                        <div class="w-12 h-12 mx-auto bg-emerald-100 dark:bg-emerald-900/30 text-emerald-500 rounded-full flex items-center justify-center mb-3">
                            <i data-lucide="check-circle" class="w-6 h-6"></i>
                        </div>
                        <h4 class="font-black text-slate-900 dark:text-slate-200 uppercase tracking-tight">Assignment Graded</h4>
                        <p class="text-[10px] text-slate-400 font-bold uppercase tracking-widest mb-4">Status: <span class="text-emerald-500">GRADED</span></p>
                        ${feedbackHtml}
                    </div>`);
        } else {
            // Pending Result - Show Status Card which has the "Resubmit" button
            footer.html(window.renderStatusCard(sub));
        }
    } else {
        // Submission Form for Student (Not Submitted Yet OR Resubmitting via toggle)
        if (typeof window.renderSubmitForm === 'function') {
            window.renderSubmitForm(tid);
        } else {
            footer.html('<div class="p-4 text-center text-rose-500">Error loading form.</div>');
        }
    }

    new bootstrap.Modal(document.getElementById('taskDetailModal')).show();
    fetchComments(tid);
    lucide.createIcons();
};

window.renderGrading = (subs) => {
    // Prevent UI refresh if admin is currently typing
    if ($('#grading-list input:focus, #grading-list textarea:focus').length > 0) return;

    // PRESERVE STATE
    const openAccordions = [];
    $('#grading-list [id^="grading-"]').each(function () {
        if (!$(this).hasClass('hidden')) {
            openAccordions.push($(this).attr('id'));
        }
    });

    const container = $('#grading-list').empty();

    if (!subs || !subs.length) {
        container.html('<div class="p-16 text-center text-slate-400 font-black uppercase tracking-[0.2em] text-[10px] italic">Status: No submissions found.</div>');
        return;
    }

    // Group by Student
    const studentsDict = {};
    subs.forEach(s => {
        if (!studentsDict[s.student_id]) {
            studentsDict[s.student_id] = {
                name: s.student_name,
                id: s.student_id,
                submissions: []
            };
        }
        studentsDict[s.student_id].submissions.push(s);
    });

    const students = Object.values(studentsDict).sort((a, b) => a.name.localeCompare(b.name));

    students.forEach(student => {
        // 1. Identify Graded Tasks First
        const gradedSet = new Set();
        student.submissions
            .filter(s => s.status === 'graded')
            .forEach(s => gradedSet.add(s.task_id));
        const gradedCount = gradedSet.size;

        // 2. Calculate Pending (Excluding tasks that are already graded)
        const pendingSet = new Set();
        student.submissions
            .filter(s => s.status === 'submitted') // Only pending
            .filter(s => !gradedSet.has(s.task_id)) // CRITICAL: If graded, don't count as pending
            .sort((a, b) => new Date(b.submitted_at) - new Date(a.submitted_at))
            .forEach(s => pendingSet.add(s.task_id));

        const pendingCount = pendingSet.size;
        const accordionId = `grading-${student.id}`;

        // Check if this card was previously open
        const isOpen = openAccordions.includes(accordionId);

        // Card Header with Dynamic State
        const cardHtml = `
                    <div class="bg-white dark:bg-[#1e293b] rounded-2xl border border-slate-100 dark:border-slate-800 shadow-sm overflow-hidden animate-in fade-in slide-in-from-bottom-2">
                        <div class="p-5 flex items-center justify-between cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors select-none" onclick="$('#${accordionId}').toggleClass('hidden'); $(this).find('.chevron').toggleClass('rotate-180')">
                            <div class="flex items-center gap-4">
                                <div class="w-12 h-12 rounded-xl bg-indigo-100 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400 flex items-center justify-center font-black text-lg border border-indigo-200 dark:border-indigo-800/50">
                                    ${student.name.charAt(0).toUpperCase()}
                                </div>
                                <div>
                                    <h5 class="font-black text-slate-900 dark:text-slate-200 uppercase tracking-tight leading-none mb-1.5 text-sm">${student.name}</h5>
                                    <div class="text-[9px] font-bold uppercase tracking-widest text-slate-400 flex items-center gap-3">
                                        <span class="${pendingCount > 0 ? 'text-amber-500 bg-amber-50 dark:bg-amber-900/20 px-2 py-0.5 rounded border border-amber-100 dark:border-amber-900/30' : 'text-slate-400'}">${pendingCount} Pending</span>
                                        <span class="text-emerald-500 bg-emerald-50 dark:bg-emerald-900/20 px-2 py-0.5 rounded border border-emerald-100 dark:border-emerald-900/30">${gradedCount} Graded</span>
                                    </div>
                                </div>
                            </div>
                            <div class="w-8 h-8 flex items-center justify-center rounded-lg bg-slate-50 dark:bg-slate-800 text-slate-400 transition-transform duration-300 chevron ${isOpen ? 'rotate-180' : ''}">
                                <i data-lucide="chevron-down" class="w-4 h-4"></i>
                            </div>
                        </div>
                        
                        <div id="${accordionId}" class="${isOpen ? '' : 'hidden'} border-t border-slate-100 dark:border-slate-800 bg-slate-50/50 dark:bg-[#0b1120]/30 divide-y divide-slate-100 dark:divide-slate-800">
                           <!-- Submissions will go here --> 
                        </div>
                    </div>`;

        const $card = $(cardHtml);
        const $list = $card.find(`#${accordionId}`);

        // Add Submissions to the list
        const rawPending = student.submissions
            .filter(s => s.status !== 'graded')
            .filter(s => !gradedSet.has(s.task_id)) // Hide if already graded
            .sort((a, b) => new Date(b.submitted_at) - new Date(a.submitted_at));

        const sortedSubs = [];
        const seenTasks = new Set();
        rawPending.forEach(s => {
            if (!seenTasks.has(s.task_id)) {
                seenTasks.add(s.task_id);
                sortedSubs.push(s);
            }
        });

        // Add valid submissions
        if (sortedSubs.length > 0) {
            sortedSubs.forEach(s => {
                const isGraded = s.status === 'graded'; // Should be false here due to filters, but kept for robustness
                const subHtml = `
                             <div class="p-6 flex flex-col lg:flex-row gap-6 items-start ${isGraded ? 'opacity-70 hover:opacity-100 bg-slate-50 dark:bg-slate-900/20' : 'bg-white dark:bg-[#1e293b]'} transition-all">
                                <div class="flex-1 w-full">
                                    <div class="flex items-center justify-between mb-3">
                                        <p class="text-[8px] ${isGraded ? 'text-emerald-500 bg-emerald-100 dark:bg-emerald-900/30 border-emerald-200 dark:border-emerald-900/40' : 'text-amber-600 bg-amber-100 dark:bg-amber-900/30 border-amber-200 dark:border-amber-900/40'} border px-2 py-1 rounded inline-flex items-center gap-1.5 font-black uppercase tracking-[0.15em]">
                                            <i data-lucide="${isGraded ? 'check-circle' : 'clock'}" class="w-3 h-3"></i> ${isGraded ? 'GRADED' : 'PENDING REVIEW'}
                                        </p>
                                        <div class="text-[9px] text-slate-400 font-bold uppercase tracking-widest flex items-center gap-1.5">
                                            <i data-lucide="calendar" class="w-3 h-3"></i> ${new Date(s.submitted_at).toLocaleDateString()}
                                        </div>
                                    </div>
                                    
                                    <h6 class="font-black text-slate-900 dark:text-slate-200 text-base uppercase tracking-tight mb-2 leading-none">${s.task_title}</h6>
                                    
                                    <div class="flex flex-wrap gap-2 mb-4 mt-3">
                                         ${(() => {
                        const data = parseSubmission(s.content);
                        let html = '';
                        if (data.file) html += `<a href="${formatDownloadUrl(data.file)}" target="_blank" class="px-4 py-2 rounded-xl bg-white dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 text-[9px] font-black uppercase tracking-widest flex items-center gap-2 hover:border-indigo-500 hover:text-indigo-500 transition-all text-slate-600 dark:text-slate-400"><i data-lucide="file" class="w-3.5 h-3.5"></i> Download File</a>`;
                        if (data.github) html += `<a href="${data.github}" target="_blank" class="px-4 py-2 rounded-xl bg-slate-900 text-white border-2 border-slate-900 text-[9px] font-black uppercase tracking-widest flex items-center gap-2 hover:bg-slate-800 transition-all"><i data-lucide="github" class="w-3.5 h-3.5"></i> View Code</a>`;
                        if (data.live) html += `<a href="${data.live}" target="_blank" class="px-4 py-2 rounded-xl bg-emerald-500 text-white border-2 border-emerald-500 text-[9px] font-black uppercase tracking-widest flex items-center gap-2 hover:bg-emerald-600 transition-all"><i data-lucide="globe" class="w-3.5 h-3.5"></i> Live Demo</a>`;
                        return html || '<span class="px-3 py-1.5 rounded-lg bg-rose-50 text-rose-500 border border-rose-100 text-[8px] font-black uppercase tracking-widest">No Assets</span>';
                    })()}
                                    </div>
                                </div>
                                
                                <div class="w-full lg:w-auto flex flex-col gap-3 min-w-[240px]">
                                    ${!isGraded ? `
                                    <div class="bg-indigo-50 dark:bg-indigo-900/10 p-4 rounded-xl border border-indigo-100 dark:border-indigo-900/20">
                                        <div class="flex gap-2 mb-2">
                                            <input type="number" id="grade-${s.id}" class="w-20 p-2 text-center bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-sm font-black outline-none focus:ring-2 focus:ring-indigo-500 dark:text-slate-200 placeholder:font-normal" placeholder="0-100">
                                            <button onclick="window.submitGrade('${s.id}')" class="flex-1 btn-command px-4 py-2 rounded-lg text-[9px] shadow-none">Submit Grade</button>
                                        </div>
                                        <textarea id="feedback-${s.id}" class="w-full p-3 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-lg text-[10px] font-bold outline-none focus:ring-2 focus:ring-indigo-500 resize-none dark:text-slate-200" placeholder="Write feedback for student..." rows="2"></textarea>
                                    </div>
                                    ` : ''}
                                </div>
                             </div>
                             `;
                $list.append(subHtml);
            });

            container.append($card);
        }
    });
    lucide.createIcons();
};

async function fetchUsers() {
    // Select all fields to ensure status, avatar_url, and email are available
    console.log("Fetching users...");
    const { data: users, error } = await client.from('profiles').select('*').order('created_at', { ascending: false });

    if (error) {
        console.error("fetchUsers Error:", error);
        showToast("Failed to fetch students. Check console.");
    } else {
        if (users) { users.forEach(u => u.name = u.name || u.full_name || 'Student'); }
        window.allUsersCache = users || []; // Cache users IMMEDIATELY after fetch
        const studentCount = users ? users.filter(u => u.role === 'student').length : 0;
        console.log(`Fetched ${users ? users.length : 0} total users. ${studentCount} are students.`);

        // CRITICAL: Ensure student directory is updated if storage is open
        if ($('#view-storage').is(':visible') && userProfile.role === 'admin' && !window.currentViewingStudentId) {
            renderStudentDirectory();
        }
    }

    const { data: progress } = await client.from('user_arcade_progress').select('*');

    window.allArcadeProgress = progress || [];
    renderUsers(window.allUsersCache);
}

function renderUsers(users) {
    const container = $('#user-table-body').empty();
    const query = $('#user-search').val().toLowerCase();

    users.filter(u => u.role === 'student' && ((u.name || u.full_name || "").toLowerCase().includes(query) || (u.email && u.email.toLowerCase().includes(query)))).forEach(u => {
        // ROBUST ID CHECK: Use uid or id
        const userId = u.uid || u.id;

        // Real-time Online Check
        const isOnline = window.onlineUsers && window.onlineUsers.some(ou => ou.user_id === userId);

        const uSubsRaw = window.allSubmissions.filter(s => s.student_id === userId);

        // DEDUPLICATE: Map task_id -> latest submission
        const uniqueSubsMap = new Map();
        uSubsRaw.forEach(s => {
            const existing = uniqueSubsMap.get(s.task_id);
            if (!existing || new Date(s.submitted_at) > new Date(existing.submitted_at)) {
                uniqueSubsMap.set(s.task_id, s);
            }
        });
        const uSubs = Array.from(uniqueSubsMap.values());

        const gradedSubs = uSubs.filter(s => s.status === 'graded');
        const avg = gradedSubs.length ? Math.round(gradedSubs.reduce((a, b) => a + b.grade, 0) / gradedSubs.length) : 0;

        // Get Arcade Progress 
        const prog = window.allArcadeProgress ? window.allArcadeProgress.find(p => p.user_id === userId) : null;
        const htmlLvl = prog?.html_level || '-';
        const cssLvl = prog?.css_level || '-';
        const jsLvl = prog?.js_level || '-';

        // Fallback for avatar: DB -> Local Cache (Same Device) -> Initials
        const localCache = localStorage.getItem(`cached_avatar_${userId}`);
        const dbAvatar = u.avatar_url;

        // Strict check: if dbAvatar is "null", "undefined", or empty/whitespace, treat as null.
        const isValidDb = dbAvatar && dbAvatar !== "null" && dbAvatar !== "undefined" && dbAvatar.trim() !== "";
        const isValidLocal = localCache && localCache !== "null" && localCache !== "undefined" && localCache.trim() !== "";

        const avatar = isValidDb ? dbAvatar : (isValidLocal ? localCache : `https://ui-avatars.com/api/?name=${encodeURIComponent(u.name)}&background=random`);
        // Default status if null
        const status = u.status || 'active';

        const levelBadge = (lvl, color) => {
            const displayLvl = (lvl === '-') ? 'easy' : lvl;
            const short = displayLvl.charAt(0).toUpperCase();
            return `<span class="inline-flex items-center justify-center w-5 h-5 rounded text-[8px] font-black uppercase bg-${color}-100 dark:bg-${color}-900/30 text-${color}-600 dark:text-${color}-400 border border-${color}-200 dark:border-${color}-800/50" title="${displayLvl}">${short}</span>`;
        };

        container.append(`
                    <tr class="hover:bg-slate-50 dark:hover:bg-slate-900/50 transition-colors border-b border-slate-50 dark:border-slate-800/50 text-xs ${isOnline ? 'bg-emerald-50/30 dark:bg-emerald-900/10' : ''}">
                        <td class="px-6 py-4">
                            <div class="flex items-center gap-3">
                                <div class="relative w-8 h-8 shrink-0">
                                    <div class="w-8 h-8 rounded-full overflow-hidden border border-slate-200 dark:border-slate-700 shadow-sm">
                                        <img src="${avatar}" class="w-full h-full object-cover" alt="${u.name}" onerror="this.onerror=null; this.src='https://ui-avatars.com/api/?name=${encodeURIComponent(u.name)}&background=random';">
                                    </div>
                                    ${isOnline ? '<span class="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-emerald-500 border-2 border-white dark:border-slate-900 rounded-full animate-pulse" title="Online Now"></span>' : ''}
                                </div>
                                <div class="min-w-0">
                                    <div class="font-black text-slate-900 dark:text-indigo-400 uppercase tracking-tight text-sm mb-0.5 truncate">${u.name}</div>
                                    <div class="text-[8px] text-slate-400 font-bold uppercase tracking-widest flex items-center gap-1.5 truncate">
                                        <i data-lucide="mail" class="w-2.5 h-2.5 text-indigo-500"></i> ${u.email || 'No Email'}
                                    </div>
                                </div>
                            </div>
                        </td>
                        <td class="px-6 py-4 text-center hidden sm:table-cell">
                        <div class="flex flex-col items-center justify-center gap-1">
                                <div class="flex items-center gap-2">
                                    <span class="text-[9px] font-black uppercase tracking-widest text-emerald-500 bg-emerald-50 dark:bg-emerald-900/20 px-1.5 py-0.5 rounded border border-emerald-100 dark:border-emerald-900/30" title="Completed/Submitted">
                                        ${uSubs.length} Done
                                    </span>
                                    <span class="text-[9px] font-black uppercase tracking-widest text-slate-400 bg-slate-50 dark:bg-slate-800 px-1.5 py-0.5 rounded border border-slate-100 dark:border-slate-700" title="Not Attempted">
                                        ${Math.max(0, (window.allTasks ? window.allTasks.length : 0) - uSubs.length)} Pending
                                    </span>
                                </div>
                             </div>
                        </td>
                        <td class="px-6 py-4 text-center">
                            <div class="font-black text-slate-900 dark:text-slate-200 text-xs">${avg}%</div>
                        </td>
                        <td class="px-4 py-4 text-center">
                            <div class="flex gap-1 justify-center">
                                ${levelBadge(htmlLvl, 'orange')}
                                ${levelBadge(cssLvl, 'cyan')}
                                ${levelBadge(jsLvl, 'yellow')}
                            </div>
                        </td>
                        <td class="px-6 py-4 text-center">
                            <span class="px-3 py-1 rounded-lg text-[8px] font-black uppercase tracking-[0.15em] shadow-sm ${status === 'approved' || status === 'active' || status === 'online' ? 'bg-emerald-500 text-white' : 'bg-amber-500 text-white'}">${status === 'online' ? 'approved' : status}</span>
                        </td>
                        <td class="px-6 py-4 text-right space-x-1 whitespace-nowrap flex justify-end gap-1">
                             ${status === 'pending' ? `<button onclick="approveUser('${userId}')" class="p-2 text-emerald-500 hover:bg-emerald-50 dark:hover:bg-emerald-500/10 rounded-lg transition-all"><i data-lucide="shield-check" class="w-4 h-4"></i></button>` : ''}
                            <button onclick="window.viewStudentFiles('${userId}', '${(u.name || "").replace(/'/g, "\\'")}')" class="p-2 text-blue-500 hover:bg-blue-50 dark:hover:bg-blue-500/10 rounded-lg transition-all" title="View Student Files"><i data-lucide="folder-open" class="w-4 h-4"></i></button>
                            <button onclick="window.adminResetPassword('${userId}', '${(u.name || "").replace(/'/g, "\\'")}')" class="p-2 text-indigo-500 hover:bg-indigo-50 dark:hover:bg-indigo-500/10 rounded-lg transition-all" title="Reset Credentials"><i data-lucide="key-round" class="w-4 h-4"></i></button>
                            <button onclick="window.adminResetExam('${userId}', '${(u.name || "").replace(/'/g, "\\'")}')" class="p-2 text-amber-500 hover:bg-amber-50 dark:hover:bg-amber-500/10 rounded-lg transition-all" title="Reset Exam"><i data-lucide="rotate-ccw" class="w-4 h-4"></i></button>
                            <button onclick="generateResult('${userId}')" class="p-2 text-teal-500 hover:bg-teal-50 dark:hover:bg-teal-500/10 rounded-lg transition-all" title="Intelligence Report"><i data-lucide="file-bar-chart-2" class="w-4 h-4"></i></button>
                            <button onclick="deleteUser('${userId}')" class="p-2 text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-500/10 rounded-lg transition-all" title="Purge Record"><i data-lucide="trash-2" class="w-4 h-4"></i></button>
                        </td >
                    </tr >
                    `);
    });
    lucide.createIcons();
}

// --- FEEDBACK LOGIC ---
// NEW: Check for feedback count for admin notification
async function checkFeedbackCount() {
    // Only admins need this
    if (!userProfile || userProfile.role !== 'admin') return;

    try {
        // Count only UNREAD feedback
        const { count, error } = await client
            .from('feedback')
            .select('*', { count: 'exact', head: true })
            .eq('is_read', false);

        if (!error) {
            const badge = document.getElementById('feedback-notification');
            if (badge) {
                if (count > 0) {
                    badge.textContent = count;
                    badge.classList.remove('hidden');
                } else {
                    badge.classList.add('hidden');
                }
            }
        }
    } catch (e) {
        console.warn("Feedback count check failed", e);
    }
}

// Mark feedback as read when viewing details
window.viewFeedbackDetails = async (id) => {
    // 1. Open Window Immediately (UX priority)
    window.open(`feedback_details.html?id=${id}`, '_blank', 'width=800,height=900');

    // 2. Mark as Read in Background
    try {
        const { error } = await client
            .from('feedback')
            .update({ is_read: true })
            .eq('id', id);

        if (!error) {
            // 3. Update Badge immediately
            checkFeedbackCount();

            // 4. Update row visual style immediately (Optimistic UI)
            const dot = document.getElementById(`dot-${id}`);
            if (dot) dot.remove();

            const row = document.getElementById(`row-${id}`);
            if (row) {
                row.classList.remove('bg-slate-50/50', 'dark:bg-slate-800/50', 'font-bold');
            }

        } else {
            console.error("Supabase Update Error:", error);
            // If permission error, alert user (useful for debugging)
            if (error.code === '42501') {
                alert("Permission Denied: Cannot mark feedback as read. Please run the Fix SQL.");
            }
        }
    } catch (e) {
        console.error("Error marking feedback read:", e);
    }
};

async function fetchFeedback() {
    console.log("Fetching feedback...");
    const { data: feedback, error } = await client.from('feedback')
        .select('*')
        .order('submitted_at', { ascending: false });

    if (error) {
        console.error("fetchFeedback Error:", error);
        showToast("Failed to fetch feedback.");
    } else {
        renderFeedbackTable(feedback || []);
        $('#total-feedback-count').text(`${feedback ? feedback.length : 0} Records`);
    }
}

window.renderFeedback = fetchFeedback;

// Helper to fetch image as base64 (for PDF)
const fetchImage = async (url) => {
    if (!url) return null;
    try {
        // If it's already base64, return it
        if (url.startsWith('data:')) return url;

        const response = await fetch(url);
        const blob = await response.blob();
        return new Promise((resolve) => {
            const reader = new FileReader();
            reader.onloadend = () => resolve(reader.result);
            reader.readAsDataURL(blob);
        });
    } catch (e) {
        console.warn("Image fetch failed", e);
        return null;
    }
};

// --- PROFESSIONAL REPORT GENERATION ---
window.generateResult = async (userId) => {
    const user = window.allUsersCache.find(u => (u.uid || u.id) === userId);
    if (!user) return showToast("User not found");

    // Fetch Profile Image (Async)
    let profileImgData = null;
    const profileUrl = user.avatar_url || user.profile_pic || user.profileImage;
    if (profileUrl) {
        try {
            profileImgData = await fetchImage(profileUrl);
        } catch (e) { console.warn("Profile image fetch failed", e); }
    }

    // Deduplicate submissions (keep highest grade) and filter valid grades
    const rawSubmissions = window.allSubmissions.filter(s => s.student_id === userId && s.status === 'graded' && s.grade != null && s.grade !== '');
    const uniqueTasksMap = new Map();

    rawSubmissions.forEach(s => {
        const existing = uniqueTasksMap.get(s.task_id);
        const sGrade = parseFloat(s.grade) || 0;
        const existingGrade = existing ? (parseFloat(existing.grade) || 0) : -1;

        if (!existing || sGrade > existingGrade) {
            uniqueTasksMap.set(s.task_id, s);
        }
    });

    const submissions = Array.from(uniqueTasksMap.values()).sort((a, b) => new Date(b.submitted_at) - new Date(a.submitted_at));
    const progress = window.allArcadeProgress ? window.allArcadeProgress.find(p => p.user_id === userId) : null;

    // Calculate Stats
    const totalGraded = submissions.length;
    const avgGrade = totalGraded > 0
        ? Math.round(submissions.reduce((a, b) => a + (parseInt(b.grade) || 0), 0) / totalGraded)
        : 0;

    const pdfLib = window.jsPDF || window.jspdf?.jsPDF;
    if (!pdfLib) return showToast("PDF Library not loaded");

    const doc = new pdfLib();

    // Verify autoTable plugin is available
    if (typeof doc.autoTable !== 'function') {
        console.error("AutoTable plugin not loaded properly");
        return showToast("PDF AutoTable plugin not loaded. Please refresh the page.");
    }

    const pageWidth = doc.internal.pageSize.getWidth();
    const pageHeight = doc.internal.pageSize.getHeight();

    // --- 1. HEADER & BRANDING ---
    // Header Background Strip (Light Blue-Gray) - Increased height for better layout
    doc.setFillColor(241, 245, 249); // Slate 100
    doc.rect(0, 0, pageWidth, 50, 'F');

    // Logo (Left) - Professional Small Size
    if (window.bbsydpLogo) {
        try {
            // Reduced to 18mm height for subtle professional look
            // Auto-width (0) preserves aspect ratio
            const logoH = 18;

            // Vertically centered in 50px header: (50 - 18) / 2 = 16
            doc.addImage(window.bbsydpLogo, 'PNG', 14, 16, 0, logoH);
        } catch (e) {
            console.warn("Logo error", e);
            doc.addImage(window.bbsydpLogo, 'PNG', 14, 16, 18, 18);
        }
    }

    // Organization Text (Right of logo)
    const textX = 55; // Moved right to prevent overlap with wide logo

    // Line 1: Organization Prefix
    doc.setFont("helvetica", "bold");
    doc.setFontSize(10);
    doc.setTextColor(71, 85, 105); // Slate 600
    doc.text("BENAZIR BHUTTO SHAHEED", textX, 19); // Shifted down for centering

    // Line 2: Main Board Name
    doc.setFontSize(14);
    doc.setTextColor(15, 23, 42); // Slate 900
    doc.text("Human Resource Research & Development Board", textX, 27);

    // Line 3: Government Affiliation
    doc.setFontSize(9);
    doc.setTextColor(100, 116, 139); // Slate 500
    doc.setFont("helvetica", "normal");
    doc.text("Government of Sindh", textX, 34);

    // Title Strip (Indigo Gradient Effect)
    doc.setFillColor(79, 70, 229); // Indigo 600
    doc.rect(0, 50, pageWidth, 14, 'F'); // Adjusted Y position
    doc.setTextColor(255, 255, 255);
    doc.setFontSize(16);
    doc.setFont("helvetica", "bold");
    doc.text("STUDENT PERFORMANCE REPORT", pageWidth / 2, 59, { align: "center" }); // Adjusted Y position

    // --- 2. STUDENT BIO-DATA SECTION ---
    let yPos = 75; // Adjusted starting Y for content
    doc.setFont("helvetica", "bold");
    doc.setFontSize(11);
    doc.setTextColor(70);
    doc.text("STUDENT PROFILE", 14, yPos);
    doc.setLineWidth(0.5);
    doc.setDrawColor(200);
    doc.line(14, yPos + 2, 196, yPos + 2);

    yPos += 10;
    const avatarSize = 24;

    // Avatar - Show student's profile image or initial
    if (profileImgData) {
        try {
            doc.addImage(profileImgData, 'PNG', 14, yPos, avatarSize, avatarSize);
            // Border for avatar
            doc.setDrawColor(226, 232, 240);
            doc.setLineWidth(0.5);
            doc.rect(14, yPos, avatarSize, avatarSize);
        } catch (e) {
            // Fallback to initial if image fails
            doc.setDrawColor(220);
            doc.setFillColor(245);
            doc.roundedRect(14, yPos, avatarSize, avatarSize, 3, 3, 'FD');
            doc.setFontSize(20);
            doc.setTextColor(150);
            doc.text(user.name.charAt(0).toUpperCase(), 14 + (avatarSize / 2), yPos + 16, { align: "center" });
        }
    } else {
        // Avatar Placeholder with initial
        doc.setDrawColor(220);
        doc.setFillColor(245);
        doc.roundedRect(14, yPos, avatarSize, avatarSize, 3, 3, 'FD');
        doc.setFontSize(20);
        doc.setTextColor(150);
        doc.text(user.name.charAt(0).toUpperCase(), 14 + (avatarSize / 2), yPos + 16, { align: "center" });
    }

    // Info Grid
    doc.setFontSize(10);
    const leftColX = 45;
    const rightColX = 135; // Moved right to prevent overlap with long emails
    const rowHeight = 7;

    // Row 1
    doc.setTextColor(100); doc.setFont("helvetica", "normal");
    doc.text("Full Name:", leftColX, yPos + 6);
    doc.setTextColor(0); doc.setFont("helvetica", "bold");
    doc.text(user.name, leftColX + 25, yPos + 6);

    doc.setTextColor(100); doc.setFont("helvetica", "normal");
    doc.text("Student ID:", rightColX, yPos + 6);
    doc.setTextColor(0); doc.setFont("helvetica", "bold");
    doc.text((user.uid || user.id).substring(0, 8).toUpperCase(), rightColX + 25, yPos + 6);

    // Row 2
    doc.setTextColor(100); doc.setFont("helvetica", "normal");
    doc.text("Email:", leftColX, yPos + 6 + rowHeight);
    doc.setTextColor(0); doc.setFont("helvetica", "bold");
    doc.text(user.email || "N/A", leftColX + 25, yPos + 6 + rowHeight);

    doc.setTextColor(100); doc.setFont("helvetica", "normal");
    doc.text("Report Date:", rightColX, yPos + 6 + rowHeight);
    doc.setTextColor(0); doc.setFont("helvetica", "bold");
    doc.text(new Date().toLocaleDateString(), rightColX + 25, yPos + 6 + rowHeight);

    // Row 3 (Role)
    doc.setTextColor(100); doc.setFont("helvetica", "normal");
    doc.text("Program:", leftColX, yPos + 6 + (rowHeight * 2));
    doc.setTextColor(0); doc.setFont("helvetica", "bold");
    doc.text("Web Development With Python", leftColX + 25, yPos + 6 + (rowHeight * 2));

    yPos += 35;

    // --- 3. PERFORMANCE SUMMARY (Visual Cards) ---
    doc.setFont("helvetica", "bold");
    doc.setFontSize(11);
    doc.setTextColor(70);
    doc.text("PERFORMANCE METRICS", 14, yPos);
    doc.line(14, yPos + 2, 196, yPos + 2);
    yPos += 8;

    // Draw 3 Cards
    const cardW = 55;
    const cardH = 25;
    const gap = 8;
    let cardX = 14;

    // Function to draw card with colored accent
    const drawStatCard = (label, value, subtext, colorV) => {
        // Card background
        doc.setFillColor(255, 255, 255);
        doc.setDrawColor(226, 232, 240); // Slate 200
        doc.setLineWidth(0.5);
        doc.roundedRect(cardX, yPos, cardW, cardH, 3, 3, 'FD');

        // Colored left accent bar
        doc.setFillColor(colorV[0], colorV[1], colorV[2]);
        doc.roundedRect(cardX, yPos, 3, cardH, 3, 3, 'F');

        // Label
        doc.setFontSize(8);
        doc.setTextColor(100, 116, 139); // Slate 500
        doc.setFont("helvetica", "bold");
        doc.text(label.toUpperCase(), cardX + (cardW / 2), yPos + 8, { align: "center" });

        // Value
        doc.setFontSize(16);
        doc.setFont("helvetica", "bold");
        doc.setTextColor(colorV[0], colorV[1], colorV[2]);
        doc.text(String(value), cardX + (cardW / 2), yPos + 17, { align: "center" });

        // Subtext
        if (subtext) {
            doc.setFontSize(7);
            doc.setTextColor(148, 163, 184); // Slate 400
            doc.setFont("helvetica", "normal");
            doc.text(subtext, cardX + (cardW / 2), yPos + 22, { align: "center" });
        }
        cardX += cardW + gap;
    };

    drawStatCard("Tasks Completed", totalGraded, "Verified Submissions", [79, 70, 229]); // Indigo
    drawStatCard("Average Grade", avgGrade + "%", "Overall Score", [16, 185, 129]); // Emerald

    // Arcade Level Summary
    let arcadeSummary = "No Data";
    if (progress) {
        const h = progress.html_level || '-';
        const c = progress.css_level || '-';
        const j = progress.js_level || '-';
        arcadeSummary = `H:${h} | C:${c} | J:${j}`;
    }
    drawStatCard("Arcade Rank", (window.allArcadeProgress?.find(p => p.user_id === userId)?.rank_name || "Novice"), arcadeSummary, [245, 158, 11]); // Amber

    yPos += 35;

    // --- 4. SUBMISSION TABLE ---
    doc.autoTable({
        startY: yPos,
        head: [['Task Title', 'Submission Date', 'Status', 'Grade', 'Feedback/Remarks']],
        body: submissions.map(s => [
            window.fixEncoding(s.task_title || "Unknown Task"),
            new Date(s.submitted_at).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }),
            "GRADED",
            s.grade + "%",
            window.fixEncoding(s.feedback || "-")
        ]),
        theme: 'striped',
        headStyles: {
            fillColor: [79, 70, 229], // Indigo 600
            textColor: 255,
            fontSize: 9,
            fontStyle: 'bold',
            halign: 'center'
        },
        bodyStyles: {
            fontSize: 8,
            textColor: [51, 65, 85], // Slate 700
            cellPadding: 4
        },
        alternateRowStyles: {
            fillColor: [248, 250, 252] // Slate 50
        },
        columnStyles: {
            0: { cellWidth: 55, fontStyle: 'bold', halign: 'left' },
            1: { cellWidth: 30, halign: 'center' },
            2: { cellWidth: 25, halign: 'center', textColor: [16, 185, 129] }, // Green for status
            3: { cellWidth: 20, halign: 'center', fontStyle: 'bold', textColor: [79, 70, 229] }, // Indigo for grade
            4: { cellWidth: 'auto', halign: 'left' }
        },
        margin: { top: 20, left: 14, right: 14 },

        // HOOKS FOR EMOJI RENDERING
        didParseCell: function (data) {
            // Check Body Cells in Title (0) and Feedback (4) columns
            if (data.section === 'body' && (data.column.index === 0 || data.column.index === 4)) {
                const text = Array.isArray(data.cell.text) ? data.cell.text.join(' ') : data.cell.text;

                // Check for Emojis (Surrogates) or Non-ASCII
                if (/[\uD800-\uDBFF][\uDC00-\uDFFF]/.test(text) || /[^\x00-\x7F]/.test(text)) {
                    data.cell.customText = text;

                    // Hide the original text by setting color to match background (or transparent-ish)
                    // Note: We keep the text so autoTable calculates row height correctly!
                    data.cell.styles.textColor = data.cell.styles.fillColor || [255, 255, 255];
                }
            }
        },
        didDrawCell: function (data) {
            if (data.cell.customText) {
                try {
                    const text = data.cell.customText;
                    const ptSize = data.cell.styles.fontSize;
                    const pxSize = ptSize * 1.333; // Convert pt to px

                    // Get color (force dark slate for readability)
                    // We ignore the hidden text color and use our own
                    const colorStyle = '#334155';

                    // Get Cell Width (converted to pixels for canvas)
                    // data.cell.width is in mm (default jsPDF unit)
                    // 1 mm = 3.7795 px (approx 96 DPI)
                    const availableWidthMm = data.cell.width - data.cell.padding('left') - data.cell.padding('right');
                    const cellWidthPx = availableWidthMm * 3.78;

                    // Generate Image with Wrapping and High DPI (Scale 4)
                    // We use the pixel width calculated from mm to ensure 1:1 visual scaling
                    let weight = data.cell.styles.fontStyle || 'normal';
                    if (weight === 'bolditalic') weight = 'italic bold';

                    const imgObj = window.textToImage(text, pxSize, colorStyle, cellWidthPx, 4, weight);

                    // Dimensions for PDF (mm)
                    // We want to fill the available width in the cell

                    // Calculate height based on aspect ratio
                    const ratio = imgObj.height / imgObj.width;
                    const drawHeight = availableWidthMm * ratio;

                    // Position
                    const x = data.cell.x + data.cell.padding('left');
                    const y = data.cell.y + data.cell.padding('top'); // Align top

                    // Draw Image
                    data.doc.addImage(imgObj.dataUrl, 'PNG', x, y, availableWidthMm, drawHeight);

                } catch (e) {
                    console.error("Error rendering emoji cell", e);
                }
            }
        },

        didDrawPage: function (data) {
            // Footer logic if table spans multiple pages
        }
    });

    // --- 4.5 INSTRUCTOR REMARKS (UPDATED) ---
    let remarksY = doc.lastAutoTable.finalY + 15;

    // Check if we need space for remarks
    if (remarksY > pageHeight - 70) {
        doc.addPage();
        remarksY = 40;
    }

    // Section Header
    doc.setFont("helvetica", "bold");
    doc.setFontSize(11);
    doc.setTextColor(79, 70, 229); // Indigo 600
    doc.text("INSTRUCTOR REMARKS", 14, remarksY);

    remarksY += 8;

    // Generate remarks based on average grade (WITH EMOJIS)
    let instructorRemarks = "";
    if (avgGrade >= 90) {
        instructorRemarks = "Outstanding performance! 🌟 The student has demonstrated exceptional understanding and mastery of the concepts. Keep up the excellent work and continue to challenge yourself with advanced topics. 🚀";
    } else if (avgGrade >= 80) {
        instructorRemarks = "Excellent work! ✨ The student shows strong grasp of the material and consistent effort. Continue this momentum and focus on refining advanced skills for even better results. 💪";
    } else if (avgGrade >= 70) {
        instructorRemarks = "Good progress! 👍 The student is performing well and shows solid understanding. With more practice and attention to detail, performance can reach the next level. 📈";
    } else if (avgGrade >= 60) {
        instructorRemarks = "Satisfactory performance. The student demonstrates basic understanding but needs to focus more on core concepts. Additional practice and review of fundamentals is recommended. 📚";
    } else if (avgGrade >= 50) {
        instructorRemarks = "Needs improvement. ⚠️ The student should dedicate more time to studying and seek help when needed. Regular practice and consultation with instructors will help improve performance.";
    } else {
        instructorRemarks = "Requires immediate attention. 🚨 The student is struggling with the material and needs significant support. Please schedule one-on-one sessions and focus on building foundational skills.";
    }

    // Render Remarks as Image (for Emoji support)
    try {
        const pxSize = 9 * 1.333; // 9pt to px
        const colorStyle = '#5C4033'; // Amber 900
        const maxWidthMm = pageWidth - 40; // 210 - 40 = 170mm approx
        const maxWidthPx = maxWidthMm * 3.78; // mm to px

        // Generate High-Res Image of Text
        const imgObj = window.textToImage(instructorRemarks, pxSize, colorStyle, maxWidthPx, 4, 'normal');

        // Calculate dimensions
        const ratio = imgObj.height / imgObj.width;
        const drawHeight = maxWidthMm * ratio;
        const remarksBoxHeight = Math.max(25, drawHeight + 10);

        // Remarks Box with light background
        doc.setFillColor(254, 252, 232); // Amber 50
        doc.setDrawColor(251, 191, 36); // Amber 400
        doc.setLineWidth(0.5);
        doc.roundedRect(14, remarksY, pageWidth - 28, remarksBoxHeight, 2, 2, 'FD');

        // Draw Image
        doc.addImage(imgObj.dataUrl, 'PNG', 18, remarksY + 5, maxWidthMm, drawHeight);

        remarksY += remarksBoxHeight + 5;

    } catch (e) {
        console.error("Remarks rendering failed", e);
        // Fallback to text (No Emojis)
        doc.setFont("helvetica", "normal");
        doc.setFontSize(9);
        const remarksLines = doc.splitTextToSize(instructorRemarks.replace(/[^\x00-\x7F]/g, ""), pageWidth - 40); // Strip emojis for fallback
        const remarksBoxHeight = Math.max(25, (remarksLines.length * 4) + 10);

        doc.setFillColor(254, 252, 232); // Amber 50
        doc.setDrawColor(251, 191, 36); // Amber 400
        doc.setLineWidth(0.5);
        doc.roundedRect(14, remarksY, pageWidth - 28, remarksBoxHeight, 2, 2, 'FD');

        // Draw remarks text with proper wrapping
        doc.setTextColor(92, 64, 51); // Amber 900
        doc.text(remarksLines, 18, remarksY + 6);

        remarksY += remarksBoxHeight + 5;
    }

    // --- 5. FOOTER & SIGNATURE ---
    let finalY = remarksY + 10;

    // Check if we need a new page for signature
    if (finalY > pageHeight - 50) {
        doc.addPage();
        finalY = 40;
    }

    // Separator line
    doc.setDrawColor(203, 213, 225); // Slate 300
    doc.setLineWidth(0.5);
    doc.line(14, finalY, pageWidth - 14, finalY);

    finalY += 10;

    // Signature section
    if (window.adminSignature) {
        try {
            // Right aligned signature
            doc.addImage(window.adminSignature, 'PNG', pageWidth - 60, finalY, 40, 15);
            doc.setLineWidth(0.5);
            doc.setDrawColor(148, 163, 184); // Slate 400
            doc.line(pageWidth - 60, finalY + 17, pageWidth - 20, finalY + 17);

            doc.setFontSize(9);
            doc.setTextColor(15, 23, 42); // Slate 900
            doc.setFont("helvetica", "bold");
            doc.text("Authorized Signature", pageWidth - 40, finalY + 30, { align: "center" });

            doc.setFontSize(7);
            doc.setTextColor(100, 116, 139); // Slate 500
            doc.setFont("helvetica", "normal");
            doc.text("NAVTTC Administration", pageWidth - 40, finalY + 36, { align: "center" });
        } catch (e) { console.warn("Signature error", e); }
    }

    // Left side: Document metadata
    doc.setFontSize(7);
    doc.setTextColor(100, 116, 139); // Slate 500
    doc.setFont("helvetica", "normal");
    doc.text("Document ID: " + Date.now().toString(36).toUpperCase(), 14, finalY + 15);
    doc.text("Generated: " + new Date().toLocaleString('en-US'), 14, finalY + 20);
    doc.text("System: NAVTTC LMS v2.0", 14, finalY + 25);

    finalY += 50;

    // Disclaimer box with light background
    doc.setFillColor(248, 250, 252); // Slate 50
    doc.roundedRect(14, finalY, pageWidth - 28, 12, 2, 2, 'F');

    doc.setFontSize(8);
    doc.setTextColor(100, 116, 139); // Slate 500
    doc.setFont("helvetica", "italic");
    doc.text("This document is electronically generated and serves as an official performance record.", pageWidth / 2, finalY + 5, { align: "center" });
    doc.text("For verification, please contact NAVTTC Administration.", pageWidth / 2, finalY + 9, { align: "center" });

    // Generate filename with date
    const reportDate = new Date().toISOString().split('T')[0]; // YYYY-MM-DD format
    const sanitizedName = user.name.replace(/\s+/g, '_');
    doc.save(`NAVTTC_Performance_Report_${sanitizedName}_${reportDate}.pdf`);
};

window.downloadReport = async (taskId) => {
    const currentUser = window.userProfile;
    if (!currentUser) {
        console.error("[PDF] No user profile found.");
        showToast("Please login first.");
        return;
    }

    showToast("Generating Report... Please wait.", "info");
    console.log("[PDF] Generating report for taskId:", taskId);

    const uid = currentUser.uid || currentUser.id;

    // 1. Find submission (Cache or DB)
    let sub = window.allSubmissions?.find(s =>
        String(s.task_id) === String(taskId) &&
        String(s.student_id) === String(uid)
    );

    if (!sub) {
        console.log("[PDF] Not in cache, fetching from DB...");
        try {
            const { data, error } = await client
                .from('submissions')
                .select('*')
                .eq('task_id', taskId)
                .eq('student_id', uid)
                .maybeSingle();

            if (error) throw error;
            sub = data;
        } catch (e) {
            console.error("[PDF] DB Fetch Error:", e);
        }
    }

    if (!sub) {
        console.error("[PDF] Submission not found.");
        showToast("Report data not found.");
        return;
    }

    console.log("[PDF] Found submission:", sub);

    // 2. Prepare Container
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF('p', 'pt', 'a4');

    const reportContainer = document.createElement('div');
    reportContainer.id = "temp-pdf-report";
    reportContainer.style.width = '800px'; // Fixed width for better scaling
    reportContainer.style.padding = '40px';
    reportContainer.style.background = '#ffffff';
    reportContainer.style.position = 'fixed';
    reportContainer.style.top = '0';
    reportContainer.style.left = '0';
    reportContainer.style.zIndex = '-1'; // Behind everything
    reportContainer.style.opacity = '1'; // Must be 1 for capture
    reportContainer.style.fontFamily = "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif";

    const feedbackText = sub.feedback ? window.fixEncoding(sub.feedback).replace(/\n/g, '<br>') : "No feedback provided.";
    const taskTitle = window.fixEncoding(sub.task_title || "Untitled Task");

    const fetchBase64 = async (url) => {
        try {
            const response = await fetch(url);
            const blob = await response.blob();
            return new Promise((resolve) => {
                const reader = new FileReader();
                reader.onloadend = () => resolve(reader.result);
                reader.readAsDataURL(blob);
            });
        } catch (e) { return null; }
    };

    const logoBase64 = await fetchBase64('assets/logo.png');

    reportContainer.innerHTML = `
                <div style="border: 2px solid #f1f5f9; padding: 40px; border-radius: 15px; position: relative; overflow: hidden;">
                    <!-- Header Decor -->
                    <div style="position: absolute; top: 0; left: 0; width: 100%; height: 5px; background: linear-gradient(90deg, #4f46e5, #06b6d4);"></div>
                    
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 40px;">
                        <div style="display: flex; align-items: center; gap: 20px;">
                            ${logoBase64 ? `<img src="${logoBase64}" style="height: 60px;">` : ''}
                            <div>
                                <h2 style="margin: 0; color: #1e293b; font-size: 18pt; font-weight: 900; letter-spacing: -1px;">NAVTTC LMS</h2>
                                <p style="margin: 0; color: #64748b; font-size: 9pt; font-weight: 700; text-transform: uppercase;">Performance Record</p>
                            </div>
                        </div>
                        <div style="text-align: right;">
                            <div style="color: #4f46e5; font-weight: 900; font-size: 10pt;">OFFICIAL REPORT</div>
                            <div style="color: #94a3b8; font-size: 8pt; font-weight: 600;">Date: ${new Date().toLocaleDateString()}</div>
                        </div>
                    </div>

                    <div style="margin-bottom: 40px;">
                        <div style="color: #64748b; font-size: 10pt; font-weight: 800; text-transform: uppercase; margin-bottom: 5px;">Task Title</div>
                        <h1 style="margin: 0; color: #1e293b; font-size: 26pt; font-weight: 900; line-height: 1.1;">${taskTitle}</h1>
                    </div>

                    <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 30px; margin-bottom: 40px;">
                        <div style="background: #f8fafc; padding: 25px; border-radius: 20px; border: 1px solid #e2e8f0;">
                            <div style="color: #64748b; font-size: 9pt; font-weight: 800; text-transform: uppercase; margin-bottom: 10px;">Student Information</div>
                            <div style="color: #1e293b; font-size: 14pt; font-weight: 800;">${currentUser.name}</div>
                            <div style="color: #94a3b8; font-size: 9pt; font-weight: 600; margin-top: 5px;">ID: ${uid.substring(0, 8).toUpperCase()}</div>
                        </div>
                        <div style="background: #4f46e5; padding: 25px; border-radius: 20px; color: white;">
                            <div style="opacity: 0.8; font-size: 9pt; font-weight: 800; text-transform: uppercase; margin-bottom: 10px;">Final Grade</div>
                            <div style="font-size: 32pt; font-weight: 900;">${sub.grade}<span style="font-size: 16pt; opacity: 0.7;">/100</span></div>
                        </div>
                    </div>

                    <div style="background: #ffffff; padding: 30px; border-radius: 20px; border: 2px solid #f1f5f9; margin-bottom: 40px;">
                        <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 15px;">
                            <div style="width: 30px; height: 30px; background: #e0e7ff; color: #4f46e5; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-weight: 900;">i</div>
                            <h3 style="margin: 0; color: #1e293b; font-size: 11pt; font-weight: 800; text-transform: uppercase;">Instructor Feedback</h3>
                        </div>
                        <div style="color: #475569; font-size: 12pt; line-height: 1.6; font-style: italic;">"${feedbackText}"</div>
                    </div>

                    <div style="display: flex; justify-content: space-between; align-items: flex-end; margin-top: 60px;">
                        <div>
                            <div style="color: #94a3b8; font-size: 8pt; font-weight: 600; margin-bottom: 4px;">VERIFICATION CODE</div>
                            <div style="font-family: monospace; color: #1e293b; font-size: 9pt; font-weight: 800; background: #f1f5f9; padding: 4px 10px; border-radius: 5px;">${sub.id}</div>
                        </div>
                        <div style="text-align: right;">
                            <div style="color: #cbd5e1; font-size: 8pt; font-weight: 900; letter-spacing: 2px; text-transform: uppercase;">NAVTTC LMS V2.0</div>
                        </div>
                    </div>
                </div>
            `;

    document.body.appendChild(reportContainer);

    setTimeout(async () => {
        try {
            const canvas = await html2canvas(reportContainer, {
                scale: 2,
                useCORS: true,
                logging: false,
                backgroundColor: '#ffffff'
            });

            const imgData = canvas.toDataURL('image/jpeg', 0.95);
            const pdfWidth = doc.internal.pageSize.getWidth();
            const pdfHeight = (canvas.height * pdfWidth) / canvas.width;

            doc.addImage(imgData, 'JPEG', 0, 0, pdfWidth, pdfHeight);
            doc.save(`Performance_Report_${taskId}.pdf`);
            showToast("Report downloaded successfully!", "success");
        } catch (err) {
            console.error("[PDF] Error:", err);
            showToast("Failed to generate PDF.", "error");
        } finally {
            document.body.removeChild(reportContainer);
        }
    }, 800);
};

function renderFeedbackTable(feedbackList) {
    const container = $('#feedback-table-body').empty();

    if (!feedbackList || feedbackList.length === 0) {
        container.html('<tr><td colspan="7" class="px-6 py-8 text-center text-slate-400 font-bold uppercase tracking-widest text-xs">No feedback received yet.</td></tr>');
        return;
    }

    feedbackList.forEach(item => {
        const date = new Date(item.created_at).toLocaleDateString();

        let stars = '';
        for (let i = 1; i <= 5; i++) {
            if (i <= item.rating) stars += '<i data-lucide="star" class="w-3 h-3 fill-amber-400 text-amber-400 inline"></i>';
            else stars += '<i data-lucide="star" class="w-3 h-3 text-slate-300 inline"></i>';
        }

        const badgeClass = "px-2 py-1 rounded text-[9px] font-black uppercase tracking-widest border";
        let qBadge = `<span class="${badgeClass} bg-slate-100 text-slate-500 border-slate-200">${item.content_quality}</span>`;
        if (item.content_quality === 'excellent') qBadge = `<span class="${badgeClass} bg-emerald-50 text-emerald-600 border-emerald-200">${item.content_quality}</span>`;
        else if (item.content_quality === 'good') qBadge = `<span class="${badgeClass} bg-indigo-50 text-indigo-600 border-indigo-200">${item.content_quality}</span>`;
        else if (item.content_quality === 'average') qBadge = `<span class="${badgeClass} bg-amber-50 text-amber-600 border-amber-200">${item.content_quality}</span>`;
        else if (item.content_quality === 'poor') qBadge = `<span class="${badgeClass} bg-rose-50 text-rose-600 border-rose-200">${item.content_quality}</span>`;

        let uBadge = `<span class="${badgeClass} bg-slate-100 text-slate-500 border-slate-200">${item.usability}</span>`;
        if (item.usability === 'yes') uBadge = `<span class="${badgeClass} bg-emerald-50 text-emerald-600 border-emerald-200">Easy</span>`;
        else if (item.usability === 'somewhat') uBadge = `<span class="${badgeClass} bg-amber-50 text-amber-600 border-amber-200">Okay</span>`;
        else if (item.usability === 'no') uBadge = `<span class="${badgeClass} bg-rose-50 text-rose-600 border-rose-200">Hard</span>`;

        // Unread Indicator
        const unreadDot = (!item.is_read)
            ? `<span id="dot-${item.id}" class="absolute top-1/2 left-2 -translate-y-1/2 w-2 h-2 bg-rose-500 rounded-full animate-pulse shadow-sm"></span>`
            : '';
        const rowClass = (!item.is_read) ? "bg-slate-50/50 dark:bg-slate-800/50 font-bold" : "";

        container.append(`
                    <tr id="row-${item.id}" class="relative hover:bg-slate-50 dark:hover:bg-slate-900/50 transition-colors border-b border-slate-50 dark:border-slate-800/50 text-xs ${rowClass}">
                        <td class="px-6 py-4 relative pl-8">
                            ${unreadDot}
                            <div class="font-black text-slate-900 dark:text-slate-200 uppercase tracking-tight">${item.student_name || 'Anonymous'}</div>
                        </td>
                        <td class="px-6 py-4 text-center">
                            <div class="flex items-center justify-center gap-0.5">${stars}</div>
                        </td>
                        <td class="px-6 py-4 text-center">${qBadge}</td>
                        <td class="px-6 py-4 text-center">${uBadge}</td>
                        <td class="px-6 py-4 max-w-xs truncate" title="${item.comments || ''}">
                            <span class="text-slate-600 dark:text-slate-400 font-medium italic">"${item.comments || 'No comments'}"</span>
                        </td>
                        <td class="px-6 py-4 text-right">
                            <span class="text-[10px] font-bold text-slate-400 uppercase tracking-wider">${date}</span>
                        </td>
                        <td class="px-6 py-4 text-right">
                             <div class="flex items-center justify-end gap-2">
                                <button onclick="viewFeedbackDetails('${item.id}')" 
                                    class="p-1.5 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors" title="View Details">
                                    <i data-lucide="eye" class="w-4 h-4"></i>
                                </button>
                                <button onclick="deleteFeedback('${item.id}')" 
                                    class="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors" title="Delete Feedback">
                                    <i data-lucide="trash-2" class="w-4 h-4"></i>
                                </button>
                            </div>
                        </td>
                    </tr>
                `);
    });
    lucide.createIcons();
}

window.deleteFeedback = async (id) => {
    console.log("Delete requested for:", id);

    if (!confirm("Are you sure you want to delete this feedback? This action cannot be undone.")) return;

    try {
        // 1. Attempt Delete
        const { data, error } = await client
            .from('feedback')
            .delete()
            .eq('id', id)
            .select(); // IMPORTANT: Return the deleted data to verify RLS allowed it

        // 2. Check for Supabase Error
        if (error) {
            console.error("Supabase Delete Error:", error);
            if (error.code === '42501') {
                alert("Permission Denied: You do not have permission to delete this. (RLS Policy)");
            } else {
                throw error;
            }
            return;
        }

        // 3. Check for Silent Failure (RLS hidden filtering)
        if (!data || data.length === 0) {
            console.warn("Delete succeeded but no rows returned. RLS likely hid the row.");
            alert("Delete Failed: The server ignored the request. This usually means the 'Delete Policy' is missing or you are not recognized as an Admin.");
            return;
        }

        // 4. Success
        showToast("Feedback deleted successfully");

        // Optimistic UI Update
        const row = document.getElementById(`row-${id}`);
        if (row) row.remove();

        checkFeedbackCount();

        // Refresh data to be sure
        fetchFeedback();

    } catch (err) {
        console.error("Error deleting feedback:", err);
        alert("Error: " + (err.message || "Unknown error occurred"));
    }
};

window.toggleGlobalArcadeAccess = async () => {
    const isUnlocked = localStorage.getItem('global_arcade_unlock') === 'true';
    const newState = !isUnlocked;

    // 1. Optimistic UI Update (Immediate)
    localStorage.setItem('global_arcade_unlock', newState);
    if (newState) showToast("Arcade GLOBAL UNLOCK Enabled.");
    else showToast("Arcade GLOBAL LOCK Enabled.");
    switchTab(activeTab); // Refresh UI

    // 2. Database Update
    try {
        const { error } = await client.from('arcade_config').update({ is_unlocked: newState }).eq('id', 1);

        if (error) {
            console.error("Arcade Config DB Update Failed:", error);
            // Revert UI if DB fails? Or just retry? For now, we assume success or retry next time.
            // If table doesn't exist, this might fail silently in UI but log error.
            // Fallback to local is already done above.
        }
    } catch (e) {
        console.error("Arcade DB Error:", e);
        // Fallback for "First run" or "Table missing" scenario:
        // We keep the local setting derived from optimistic update.
    }
};

// New DB Sync Function
async function fetchArcadeConfig() {
    try {
        const { data, error } = await client.from('arcade_config').select('is_unlocked').eq('id', 1).maybeSingle();
        if (data) {
            const serverState = data.is_unlocked.toString();
            // Always update local storage to match server truth
            if (localStorage.getItem('global_arcade_unlock') !== serverState) {
                localStorage.setItem('global_arcade_unlock', serverState);
                console.log("[Arcade] Synced from DB:", serverState);

                // Force UI Refresh to show correct lock/unlock status or button state
                if (typeof switchTab === 'function') switchTab(activeTab);
            }
        }
    } catch (e) { console.warn("[Arcade] Config sync failed (Table likely missing). Using local override."); }
}

function getTaskDeadlineDefault() {
    const date = new Date();
    date.setDate(date.getDate() + 1); // Set to tomorrow
    date.setHours(9, 30, 0, 0); // Set to 9:30 AM

    // Format to local ISO (YYYY-MM-DDTHH:mm)
    const pad = (n) => n.toString().padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

window.openCreateTaskModal = () => {
    editingTaskId = null;
    $('#create-task-form')[0].reset();
    $('#new-task-date').val(getTaskDeadlineDefault());
    $('#ref-file-name').text('Attach a helpful file');
    $('#task-submit-btn').text('Create Task');
    bootstrap.Modal.getOrCreateInstance(document.getElementById('createTaskModal')).show();
};

window.openEditTaskModal = (id) => {
    const task = window.allTasks.find(t => t.id === id);
    if (!task) return;
    editingTaskId = id;
    $('#new-task-title').val(task.title);
    $('#new-task-desc').val(task.description);
    $('#new-task-hints').val(task.hints || '');
    $('#new-task-date').val('');
    if (task.deadline) {
        try {
            const d = new Date(task.deadline);
            const offset = d.getTimezoneOffset() * 60000;
            const localISOTime = (new Date(d - offset)).toISOString().slice(0, 16);
            $('#new-task-date').val(localISOTime);
        } catch (e) {
            $('#new-task-date').val(task.deadline.substring(0, 16));
        }
    }
    $('#task-submit-btn').text('Update Task');
    bootstrap.Modal.getOrCreateInstance(document.getElementById('createTaskModal')).show();
};

window.openEditFromDetail = () => {
    const id = currentTask.id;
    bootstrap.Modal.getOrCreateInstance(document.getElementById('taskDetailModal')).hide();
    setTimeout(() => openEditTaskModal(id), 400); // Wait for hide animation
};

window.deleteTask = async (id) => {
    if (!confirm('Are you sure you want to delete this task?')) return;
    const { error } = await client.from('tasks').delete().eq('id', id);
    if (!error) {
        showToast('Task deleted successfully');
        loadCachedData();
    } else {
        showToast("Error deleting task: " + error.message, 'error');
    }
};

// Feedback Popup Logic
window.showFeedbackPopup = async () => {
    // 1. Check if user is logged in and is a student
    if (!userProfile || userProfile.role !== 'student') return;

    // 2. Check LocalStorage Cache first (fast check)
    // We use 'uid' (UUID) to be consistent with feedback.html and auth.user.id
    if (localStorage.getItem(`feedback_submitted_${userProfile.uid}`) === 'true') {
        console.log("Feedback already submitted (Cached).");
        return;
    }

    // 3. Check Supabase DB (Robust check)
    try {
        const { data, error } = await client
            .from('feedback')
            .select('id')
            .eq('student_id', userProfile.uid) // Use UUID to match feedback table
            .maybeSingle(); // Returns null if not found, instead of error for 0 rows

        if (data) {
            // Feedback exists
            console.log("Feedback already found in DB. Skipping popup.");
            localStorage.setItem(`feedback_submitted_${userProfile.uid}`, 'true'); // Update cache
            return;
        }
    } catch (err) {
        console.error("Error checking feedback status:", err);
        // If error (e.g. offline), maybe skip to avoid annoying user? 
        // Or show it? Let's skip to be safe.
        return;
    }

    const modal = document.getElementById('feedback-modal');

    if (modal && modal.classList.contains('hidden')) {
        modal.classList.remove('hidden');
        modal.classList.add('flex'); // Enable flexbox for centering
        setTimeout(() => {
            modal.classList.remove('opacity-0');
            const innerDiv = modal.querySelector('div');
            if (innerDiv) {
                innerDiv.classList.remove('scale-95');
                innerDiv.classList.add('scale-100');
            }
        }, 10);
    }
};

window.closeFeedbackModal = () => {
    const modal = document.getElementById('feedback-modal');
    if (modal) {
        modal.classList.add('opacity-0');
        const innerDiv = modal.querySelector('div');
        if (innerDiv) {
            innerDiv.classList.remove('scale-100');
            innerDiv.classList.add('scale-95');
        }
        setTimeout(() => {
            modal.classList.remove('flex'); // Disable flexbox
            modal.classList.add('hidden');
        }, 300);
    }
};

window.switchTab = (tabId) => {
    console.log("Switching to:", tabId);
    activeTab = tabId;

    // --- 1. PRE-SWITCH CLEANUP (Arcade & Game Logic) ---
    $('#game-stage').addClass('hidden');
    if (window.activeGameTimer) clearInterval(window.activeGameTimer);
    if (typeof window.gameActive !== 'undefined') window.gameActive = false;

    // --- 2. NAVIGATION STATE UPDATES ---
    // Desktop Sidebar
    $('.nav-item').removeClass('active');
    $(`#nav-${tabId}`).addClass('active');
    // Support onclick selector style
    $(`.nav-item[onclick*="${tabId}"]`).addClass('active');

    // Mobile Bottom Nav
    $('.mobile-nav-btn').removeClass('active');
    $(`#mob-nav-${tabId}`).addClass('active');

    // --- 3. VIEW SWITCHING ---
    // Hide all views
    document.querySelectorAll('.content-view').forEach(el => {
        el.style.display = 'none';
        el.classList.add('hidden');
    });
    $('.content-view').addClass('hidden'); // jQuery backup

    // Show Target View
    const targetEl = document.getElementById(`view-${tabId}`);
    if (targetEl) {
        targetEl.style.display = 'block';
        targetEl.classList.remove('hidden');

        // Animations
        const $target = $(targetEl);
        $target.removeClass('animate-in fade-in slide-in-from-bottom-5');
        void targetEl.offsetWidth; // trigger reflow
        $target.addClass('animate-in fade-in slide-in-from-bottom-5');
    } else {
        console.error("Target view not found:", tabId);
    }

    // Special Banner Handling
    if (tabId === 'dashboard') {
        $('#v2-banner').show().removeClass('hidden');
        // Show feedback popup for students (or everyone for now)
        if (typeof showFeedbackPopup === 'function') showFeedbackPopup();
    } else {
        $('#v2-banner').hide().addClass('hidden');
    }

    if (tabId === 'storage') {
        if (userProfile && userProfile.role === 'admin' && !window.currentViewingStudentId) {
            $('#storage-top-grid').addClass('hidden');
        }
        if (typeof loadUserFiles === 'function') loadUserFiles();
    }

    // --- 4. TITLE UPDATES ---
    const titles = {
        'chat': 'Messages',
        'dashboard': 'My Dashboard',
        'tasks': (userProfile && userProfile.role === 'admin') ? "Student Tasks" : "My Tasks",
        'resources': 'Learning Resources',
        'leaderboard': 'Leaderboard',
        'grading': 'Task Grading (Admin)',
        'users': 'User Management',
        'feedback': 'Student Feedback',
        'profile': 'My Profile',
        'exam': 'Online Examination',

        'storage': 'My Personal Storage'
    };
    $('#page-title').text(titles[tabId] || 'NAVTTC LMS');

    // --- 5. MOBILE SIDEBAR HANDLING ---
    if (window.innerWidth < 1024) {
        $('#sidebar-overlay').removeClass('show');
        $('aside').removeClass('translate-x-0').addClass('-translate-x-full');

        // Ensure mobile-open class is also removed if used
        const sidebar = document.getElementById('main-sidebar');
        if (sidebar && sidebar.classList.contains('mobile-open')) {
            if (typeof window.toggleMobileSidebar === 'function') window.toggleMobileSidebar();
        }
    }

    // --- 6. SCROLL TO TOP ---
    window.scrollTo({ top: 0, behavior: 'smooth' });

    // --- 7. SPECIFIC TAB INITIALIZATIONS & LOGIC ---

    // TRACKING: Update Activity
    if (typeof window.updateActivity === 'function') {
        const activityMap = {
            'dashboard': 'Dashboard',
            'tasks': 'Viewing Tasks',
            'resources': 'Resources',
            'leaderboard': 'Checking Leaderboard',

            'grading': 'Grading Tasks',
            'users': 'Managing Users',
            'profile': 'Editing Profile',
            'exam': 'Taking Exam',

            'storage': 'Managing Files'
        };
        window.updateActivity(activityMap[tabId] || 'Browsing LMS');
    }

    // Exam
    if (tabId === 'exam') {
        if (typeof initExamSystem === 'function') initExamSystem();
    }

    // Tasks
    if (tabId === 'tasks') {
        if (!window.allTasks || window.allTasks.length === 0) {
            if (typeof renderSkeleton === 'function') renderSkeleton('task-grid', 6, 'card');
        }
        if (typeof filterTasks === 'function') filterTasks('all');
    }

    // Users
    if (tabId === 'users') {
        if (!window.allUsersCache || window.allUsersCache.length === 0) {
            if (typeof renderSkeleton === 'function') renderSkeleton('user-table-body', 8, 'list');
        }
    }

    // Feedback
    if (tabId === 'feedback') {
        if (typeof renderFeedback === 'function') renderFeedback();
    }

    // Chat
    if (tabId === 'chat') {
        if (typeof initChat === 'function') initChat();
    } else {
        if (typeof cleanupChat === 'function') cleanupChat();
    }

    // Profile
    if (tabId === 'profile') {
        if (typeof renderProfileChart === 'function') renderProfileChart();

        if (userProfile) {
            $('#profile-name').val(userProfile.name);
            $('#profile-email').val(userProfile.email);
            const initial = userProfile.name.charAt(0).toUpperCase();
            if (userProfile.avatar_url) {
                $('#profile-avatar-display').html(`<img src="${userProfile.avatar_url}" class="w-full h-full object-cover">`);
            } else {
                $('#profile-avatar-display').html(`<span id="profile-initial-lg">${initial}</span>`);
            }
            $('#user-role').html(`<span class="text-indigo-600 dark:text-indigo-400 font-black">${userProfile.role.toUpperCase()}</span>`);

            // Toggle Achievements Visibility
            if (userProfile.role === 'student') {
                $('#trophy-section').removeClass('hidden');
                if (window.renderBadges) window.renderBadges();
            } else {
                $('#trophy-section').addClass('hidden');
            }
        }
    }

    // Performance
    if (tabId === 'performance') {
        if (typeof renderPerformanceChart === 'function') renderPerformanceChart();
    }

    // Dashboard
    if (tabId === 'dashboard') {
        if (userProfile && userProfile.role === 'student') {
            setTimeout(() => {
                if (typeof checkAndShowEncouragement === 'function') checkAndShowEncouragement();
            }, 500);
        }
        if (typeof performanceChart !== 'undefined' && performanceChart) {
            if (typeof updateChart === 'function') updateChart();
        }
    }

    // Resources
    if (tabId === 'resources') {
        if (window.fetchResources) window.fetchResources();
    }

    // Playground
    if (tabId === 'playground') {
        if (window.runCode) setTimeout(window.runCode, 100);
    }

    // Arcade
    if (tabId === 'arcade') {
        const isGlobalUnlocked = localStorage.getItem('global_arcade_unlock') === 'true';
        if (isGlobalUnlocked) {
            $('#arcade-locked').addClass('hidden');
            $('#arcade-menu').removeClass('hidden');
        } else {
            $('#arcade-locked').removeClass('hidden');
            $('#arcade-menu').addClass('hidden');
        }
        if (typeof window.syncArcadeProgress === 'function') window.syncArcadeProgress();
    }

    // --- 8. ADMIN UI UPDATES ---
    if (userProfile && userProfile.role === 'admin') {
        $('#create-task-btn, #admin-notif-btn, #add-resource-btn, #arcade-toggle-btn').removeClass('hidden');
        if (tabId === 'dashboard') $('#admin-notice-actions').removeClass('hidden');
        else $('#admin-notice-actions').addClass('hidden');

        const isUnlocked = localStorage.getItem('global_arcade_unlock') === 'true';
        const btn = $('#arcade-toggle-btn');
        const dot = $('#arcade-dot');
        const ping = $('#arcade-ping');

        if (isUnlocked) {
            btn.removeClass('text-slate-400').addClass('text-emerald-500 bg-emerald-50 dark:bg-emerald-900/20');
            dot.removeClass('hidden'); ping.removeClass('hidden');
        } else {
            btn.removeClass('text-emerald-500 bg-emerald-50 dark:bg-emerald-900/20').addClass('text-slate-400');
            dot.addClass('hidden'); ping.addClass('hidden');
        }
    } else {
        $('#create-task-btn, #admin-notif-btn, #add-resource-btn, #arcade-toggle-btn, #admin-notice-actions').addClass('hidden');
    }

    // --- 9. GLOBAL UPDATES ---
    if (typeof fetchData === 'function') fetchData();

    // Fix for stuck modal backdrops
    $('.modal').on('hidden.bs.modal', function () {
        if ($('.modal.show').length === 0) {
            $('.modal-backdrop').remove();
            $('body').removeClass('modal-open').css('padding-right', '');
        }
    });

    if (typeof lucide !== 'undefined' && lucide.createIcons) lucide.createIcons();
};

// --- PERSONAL STORAGE LOGIC (CLOUDINARY + SUPABASE METADATA) ---
window.userFiles = [];
window.storageView = 'list';
window.storageFilter = 'all';
window.storageSort = 'date_desc';
window.currentViewingStudentId = null;

window.loadUserFiles = async (targetUserId = null, studentName = null) => {
    if (!userProfile) return;

    // If Admin and no target user, show Student Directory
    if (userProfile.role === 'admin' && !targetUserId) {
        renderStudentDirectory();
        return;
    }

    const uid = targetUserId || userProfile.uid || userProfile.id;
    window.currentViewingStudentId = targetUserId;

    console.log("Loading files for UID:", uid, "Is Student View:", !!targetUserId);

    // Show storage UI elements that might have been hidden by Directory view
    $('#storage-files-container').find('.p-5.border-b, .px-5.py-3.border-b').removeClass('hidden');

    // Update UI Title if viewing student
    if (targetUserId) {
        $('#storage-page-title').html(`
                    <div class="flex items-center gap-4">
                        <button onclick="loadUserFiles()" 
                                class="p-3 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-2xl shadow-sm hover:bg-slate-50 dark:hover:bg-slate-700 transition-all group">
                            <i data-lucide="arrow-left" class="w-5 h-5 text-slate-600 dark:text-slate-400 group-hover:-translate-x-1 transition-transform"></i>
                        </button>
                        <div>
                            <h1 class="text-2xl font-black text-slate-800 dark:text-white tracking-tight">${studentName}</h1>
                            <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-0.5">Student Repository Access</p>
                        </div>
                    </div>
                `);
        $('#storage-page-subtitle').addClass('hidden');
        $('#storage-top-grid').addClass('hidden');
        if (typeof lucide !== 'undefined' && lucide.createIcons) lucide.createIcons();
    } else {
        $('#storage-page-title').html(`
                    <div class="flex items-center gap-5">
                        <div class="relative">
                            <div class="absolute -inset-1 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl blur opacity-20"></div>
                            <div class="relative p-3.5 bg-white dark:bg-slate-900 rounded-2xl shadow-sm ring-1 ring-slate-200/50 dark:ring-slate-700/50">
                                <i data-lucide="cloud" class="w-6 h-6 text-blue-600 dark:text-blue-400"></i>
                            </div>
                        </div>
                        <div>
                            <h1 class="text-2xl font-black text-slate-800 dark:text-white tracking-tight">Personal Storage</h1>
                            <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-0.5">Secure Asset Management</p>
                        </div>
                    </div>
                `);
        $('#storage-page-subtitle').addClass('hidden');
        $('#storage-top-grid').removeClass('hidden');
        if (typeof lucide !== 'undefined' && lucide.createIcons) lucide.createIcons();
    }

    try {
        // Fetch file metadata from Supabase table 'personal_storage'
        let query = client.from('personal_storage').select('*').order('created_at', { ascending: false });

        // CRITICAL FIX: Ensure correct UID filtering
        // If targetUserId is provided (Admin viewing student), use that.
        // Otherwise use the current user's ID.
        const effectiveUid = targetUserId || userProfile.uid || userProfile.id;

        if (userProfile.role !== 'admin' || (targetUserId && targetUserId !== userProfile.uid)) {
            query = query.eq('user_id', effectiveUid);
        }

        console.log("Supabase Query for UID:", effectiveUid);
        const { data, error, status } = await query;

        if (error) {
            if (status === 404 || error.message.includes('relation "personal_storage" does not exist')) {
                console.warn("CRITICAL: Supabase table 'personal_storage' is missing.");
                showToast("Storage system not initialized. (Table 'personal_storage' missing)", "error");

                // Log the SQL needed for the user
                console.log("%c ACTION REQUIRED: Run this SQL in Supabase SQL Editor:", "background: #ef4444; color: white; font-weight: bold; padding: 4px;");
                console.log(`
-- 1. Create Table
CREATE TABLE IF NOT EXISTS personal_storage (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  public_id TEXT,
  size BIGINT,
  type TEXT,
  format TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS
ALTER TABLE personal_storage ENABLE ROW LEVEL SECURITY;

-- 3. Create Safe Admin Check Function (Prevents Recursion)
CREATE OR REPLACE FUNCTION check_admin_access()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM profiles
    WHERE uid = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Set Policies
DROP POLICY IF EXISTS "Users can manage their own files" ON personal_storage;
CREATE POLICY "Users can manage their own files" ON personal_storage
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all files" ON personal_storage;
DROP POLICY IF EXISTS "Admins can manage all files" ON personal_storage;
CREATE POLICY "Admins can manage all files" ON personal_storage
  FOR ALL USING (check_admin_access());
                        `);
            } else {
                throw error;
            }
        }

        window.userFiles = data || [];
        renderStorageList(window.userFiles);
        if (typeof lucide !== 'undefined' && lucide.createIcons) lucide.createIcons();
    } catch (err) {
        console.error("Storage Load Error:", err);
        renderStorageList([]);
    }
};

let isRenderingDirectory = false;
let globalFileStatsCache = null;

/**
 * 🔒 PROTECTED STORAGE UI CONFIGURATION
 * Yeh section storage ki UI settings ko handle karta hai.
 * Isay edit karte waqt dhyan rakhein taaki persistence kharab na ho.
 */
const STORAGE_CONFIG_KEY = 'lms_admin_storage_config_v1';

window.getStorageUIConfig = () => {
    const defaults = {
        gridClass: 'grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 2xl:grid-cols-6 gap-3 p-4',
        cardPadding: 'p-3',
        iconSize: 'w-12 h-12',
        folderIconSize: 'w-8 h-8',
        titleSize: 'text-[11px]',
        subtextSize: 'text-[9px]',
        sortBy: 'recent',
        version: '1.0'
    };
    try {
        const saved = localStorage.getItem(STORAGE_CONFIG_KEY);
        if (!saved) {
            // Pehli baar defaults save karein
            window.saveStorageUIConfig(defaults);
            return defaults;
        }
        return { ...defaults, ...JSON.parse(saved) };
    } catch (e) {
        console.warn("Storage Config Load Error, using defaults");
        return defaults;
    }
};

window.saveStorageUIConfig = (config) => {
    try {
        localStorage.setItem(STORAGE_CONFIG_KEY, JSON.stringify(config));
    } catch (e) { console.error("Failed to save storage config:", e); }
};

// Initialize/Sync Settings on Load
const currentStorageConfig = window.getStorageUIConfig();

window.renderStudentDirectory = async (searchTerm = '') => {
    if (isRenderingDirectory) return;
    isRenderingDirectory = true;

    const config = window.getStorageUIConfig();
    const container = $('#storage-list');
    const emptyState = $('#storage-empty');

    // IMMEDIATE CLEANUP: Hide student-side elements to prevent flicker
    $('#storage-page-subtitle, #storage-top-grid').addClass('hidden');
    $('#storage-files-container').find('.p-5.border-b, .px-5.py-3.border-b').addClass('hidden');

    try {
        // Show Loading State if cache is empty
        if (!window.allUsersCache || window.allUsersCache.length === 0) {
            container.html(`
                        <div class="col-span-full flex flex-col items-center justify-center py-20">
                            <div class="w-16 h-16 border-4 border-indigo-600/10 border-t-indigo-600 rounded-full animate-spin mb-6"></div>
                            <p class="text-xs font-black text-slate-400 animate-pulse uppercase tracking-[0.3em]">Syncing Directory</p>
                        </div>
                    `).show();
            await fetchUsers();
        }

        // Apply Configured Grid Layout
        container.removeClass('hidden divide-y divide-slate-100 dark:divide-slate-800')
            .addClass(config.gridClass)
            .show();
        emptyState.addClass('hidden');

        // Update Header with Ultra-Professional Look (Compact)
        if ($('#directory-search').length === 0 || !searchTerm) {
            $('#storage-page-title').html(`
                        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4 w-full">
                            <div class="flex items-center gap-3">
                                <div class="w-10 h-10 bg-slate-900 dark:bg-white rounded-lg flex items-center justify-center">
                                    <i data-lucide="folder-tree" class="w-5 h-5 text-white dark:text-slate-900"></i>
                                </div>
                                <div>
                                    <h1 class="text-lg font-bold text-slate-900 dark:text-white leading-none">Student Directory</h1>
                                    <p class="text-[9px] font-medium text-slate-500 uppercase tracking-widest mt-1">Cloud Assets</p>
                                </div>
                            </div>
                            
                            <div class="relative group min-w-[280px]">
                                <i data-lucide="search" class="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-400"></i>
                                <input type="text" id="directory-search" placeholder="Search student..." 
                                       value="${searchTerm || ''}"
                                       class="w-full pl-9 pr-3 py-2 bg-slate-100 dark:bg-slate-800/50 border-none rounded-lg text-xs font-bold text-slate-700 dark:text-slate-200 focus:ring-2 focus:ring-slate-200 dark:focus:ring-slate-700 transition-all outline-none"
                                       oninput="debounceRenderDirectory(this.value)">
                            </div>
                        </div>
                    `);
        }

        // Stats Fetch Logic (Cached)
        if (!globalFileStatsCache || !searchTerm) {
            try {
                const { data: files } = await client.from('personal_storage').select('user_id, created_at');
                if (files) {
                    let stats = { mapping: {}, total: files.length, activeToday: 0 };
                    const today = new Date().setHours(0, 0, 0, 0);

                    files.forEach(f => {
                        const uid = f.user_id;
                        if (uid) {
                            if (!stats.mapping[uid]) {
                                stats.mapping[uid] = { count: 0, lastUpload: f.created_at };
                                if (new Date(f.created_at) > today) stats.activeToday++;
                            }
                            stats.mapping[uid].count++;
                            if (new Date(f.created_at) > new Date(stats.mapping[uid].lastUpload)) {
                                stats.mapping[uid].lastUpload = f.created_at;
                            }
                        }
                    });
                    globalFileStatsCache = stats;
                }
            } catch (e) { console.error("Stats Error:", e); }
        }

        // Filter and Deduplicate Students
        let studentsRaw = window.allUsersCache ? window.allUsersCache.filter(u => u.role === 'student') : [];
        const studentMap = new Map();
        studentsRaw.forEach(u => {
            const id = u.uid || u.id;
            if (!id) return;
            const name = (u.name || "").toLowerCase();
            if (searchTerm) {
                const s = searchTerm.toLowerCase();
                if (!name.includes(s) && !id.includes(s)) return;
            }
            if (!studentMap.has(id)) studentMap.set(id, u);
        });
        let students = Array.from(studentMap.values());

        if (students.length === 0) {
            container.html(`
                        <div class="col-span-full flex flex-col items-center justify-center py-20 text-center opacity-50">
                            <i data-lucide="folder-x" class="w-12 h-12 text-slate-400 mb-4"></i>
                            <h4 class="text-sm font-medium text-slate-500">No folders found</h4>
                        </div>
                    `);
        } else {
            const statsMap = globalFileStatsCache ? globalFileStatsCache.mapping : {};

            // Apply Configured Sorting
            if (config.sortBy === 'recent') {
                students.sort((a, b) => {
                    const aStats = statsMap[a.uid || a.id];
                    const bStats = statsMap[b.uid || b.id];
                    if (!aStats && !bStats) return 0;
                    if (!aStats) return 1;
                    if (!bStats) return -1;
                    return new Date(bStats.lastUpload) - new Date(aStats.lastUpload);
                });
            }

            let html = '';
            students.forEach(student => {
                const id = student.uid || student.id;
                const stats = statsMap[id] || { count: 0 };

                html += `
                            <div onclick="loadUserFiles('${id}', '${(student.name || student.full_name || "Unknown").replace(/'/g, "\\'")}')" 
                                 class="group flex flex-col items-center text-center ${config.cardPadding} bg-white dark:bg-slate-800 rounded-lg border border-slate-100 dark:border-slate-700/50 hover:bg-slate-50 dark:hover:bg-slate-700/30 transition-all cursor-pointer">
                                
                                <!-- Configurable Folder Icon -->
                                <div class="${config.iconSize} bg-amber-50 dark:bg-amber-900/20 rounded-lg flex items-center justify-center mb-2 group-hover:bg-amber-500 transition-colors">
                                    <i data-lucide="folder" class="${config.folderIconSize} text-amber-500 group-hover:text-white transition-colors"></i>
                                </div>

                                <!-- Core Details -->
                                <div class="w-full">
                                    <h4 class="${config.titleSize} font-bold text-slate-800 dark:text-white truncate leading-tight group-hover:text-indigo-600 transition-colors">
                                        ${student.name || student.full_name || "Unknown"}
                                    </h4>
                                    <p class="${config.subtextSize} font-medium text-slate-400 mt-0.5">
                                        ${stats.count} Files
                                    </p>
                                </div>
                            </div>
                        `;
            });
            container.html(html);
        }
        if (typeof lucide !== 'undefined' && lucide.createIcons) lucide.createIcons();
    } catch (err) {
        console.error("Directory Error:", err);
    } finally {
        isRenderingDirectory = false;
    }
};

// Sync logic verification: Ensure defaults are preserved if corrupted
if (!currentStorageConfig.version) window.saveStorageUIConfig(currentStorageConfig);

// Instant Search Debounce
let directorySearchTimer;
window.debounceRenderDirectory = (val) => {
    clearTimeout(directorySearchTimer);
    directorySearchTimer = setTimeout(() => {
        renderStudentDirectory(val);
    }, 300);
};

window.viewStudentFiles = (studentId, studentName) => {
    if (!userProfile || userProfile.role !== 'admin') return;
    switchTab('storage');
    loadUserFiles(studentId, studentName);
};

window.renameFile = async (fileId, currentName) => {
    const newName = prompt("Enter new name for the file:", currentName);
    if (!newName || newName === currentName) return;

    try {
        const { error } = await client
            .from('personal_storage')
            .update({ full_name: newName })
            .eq('id', fileId);

        if (error) throw error;
        showToast("File renamed successfully.");
        loadUserFiles(window.currentViewingStudentId);
    } catch (err) {
        console.error("Rename Error:", err);
        showToast("Failed to rename file.", "error");
    }
};

window.replacingFileId = null;
window.replaceFile = (fileId) => {
    console.log("? Replace Triggered for ID:", fileId);
    window.replacingFileId = fileId;
    $('#storage-replace-input').click();
};

window.handleReplaceUpload = async (fileId, file) => {
    if (!file || !fileId) {
        console.error("Missing data for replace:", { fileId, file });
        return showToast("Invalid request. Missing file ID.", "error");
    }
    if (!userProfile) return showToast("Please login.", "error");

    const uid = userProfile.uid || userProfile.id;
    const CLOUD_NAME = "dwowte8ny";
    const UPLO_PRESET = "navttc-lms";

    $('#storage-upload-progress').removeClass('hidden');
    $('#storage-upload-percent').text(`0%`);
    $('#storage-progress-bar').css('width', `0%`);

    try {
        // 1. Upload new file to Cloudinary
        const formData = new FormData();
        formData.append('file', file);
        formData.append('upload_preset', UPLO_PRESET);
        formData.append('folder', `personal_storage/${uid}`);
        formData.append('public_id', `${file.name.split('.')[0]}_${Date.now()}`);

        const res = await fetch(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/auto/upload`, {
            method: 'POST',
            body: formData
        });

        const cloudinaryData = await res.json();
        if (cloudinaryData.error) throw new Error(cloudinaryData.error.message);

        // 2. Update metadata in Supabase
        // Convert fileId to Number if it's a numeric string (common issue in JS comparisons)
        const targetId = isNaN(fileId) ? fileId : Number(fileId);

        const { error: dbError, data: updatedData } = await client
            .from('personal_storage')
            .update({
                name: file.name,
                url: cloudinaryData.secure_url,
                size: file.size,
                type: file.type,
                created_at: new Date().toISOString()
            })
            .eq('id', fileId)
            .select();

        if (dbError) throw dbError;

        // If update failed, try one more time with number conversion
        if (!updatedData || updatedData.length === 0) {
            console.log("? First Update Failed (String ID). Trying Number...");
            const targetId = Number(fileId);

            if (!isNaN(targetId)) {
                const { error: retryError, data: retryData } = await client
                    .from('personal_storage')
                    .update({
                        name: file.name,
                        url: cloudinaryData.secure_url,
                        size: file.size,
                        type: file.type,
                        created_at: new Date().toISOString()
                    })
                    .eq('id', targetId)
                    .select();

                if (retryError) throw retryError;
                if (retryData && retryData.length > 0) {
                    console.log("? Fixed via Number conversion!");
                } else {
                    throw new Error(`Record with ID ${fileId} was found but couldn't be updated. This is likely a permission issue (RLS). Please ensure you have run the latest SQL update for Admin permissions.`);
                }
            } else {
                throw new Error(`Record with ID ${fileId} not found or permission denied. If you are an Admin, please update your RLS policies.`);
            }
        }

        // 3. Clear global stats cache
        if (window.globalFileStatsCache) delete window.globalFileStatsCache[window.currentViewingStudentId || uid];

        showToast("File updated successfully!", "success");

        // 4. Force immediate refresh
        await loadUserFiles(window.currentViewingStudentId);
    } catch (err) {
        console.error("Replace Error:", err);
        showToast(`Failed to update file: ${err.message}`, "error");
    } finally {
        $('#storage-upload-progress').addClass('hidden');
        $('#storage-replace-input').val(''); // Reset input
    }
};

window.uploadFile = async (files) => {
    if (!files || files.length === 0) return;
    if (!userProfile) return showToast("Please login to upload files.", "error");

    const uid = userProfile.uid || userProfile.id;
    const CLOUD_NAME = "dwowte8ny";
    const UPLO_PRESET = "navttc-lms";

    $('#storage-upload-progress').removeClass('hidden');
    let successCount = 0;

    for (let i = 0; i < files.length; i++) {
        const file = files[i];
        const percent = Math.round(((i) / files.length) * 100);
        $('#storage-upload-percent').text(`${percent}%`);
        $('#storage-progress-bar').css('width', `${percent}%`);

        try {
            // 1. Upload to Cloudinary
            const formData = new FormData();
            formData.append('file', file);
            formData.append('upload_preset', UPLO_PRESET);
            formData.append('folder', `personal_storage/${uid}`);
            formData.append('public_id', `${file.name.split('.')[0]}_${Date.now()}`); // Allowed in unsigned upload

            const res = await fetch(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/auto/upload`, {
                method: 'POST',
                body: formData
            });

            const cloudinaryData = await res.json();
            if (cloudinaryData.error) throw new Error(cloudinaryData.error.message);

            // 2. Save metadata to Supabase
            const { error: dbError, status: dbStatus } = await client
                .from('personal_storage')
                .insert([{
                    user_id: uid,
                    name: file.name,
                    url: cloudinaryData.secure_url,
                    size: file.size,
                    type: file.type,
                    created_at: new Date().toISOString()
                }]);

            if (dbError) {
                if (dbStatus === 404 || dbError.message.includes('relation "personal_storage" does not exist')) {
                    showToast("Critical Error: Database table 'personal_storage' not found.", "error");
                    throw new Error("Table 'personal_storage' missing. Check console for SQL setup.");
                }
                throw dbError;
            }
            successCount++;
        } catch (err) {
            console.error("Upload Error:", err);
            showToast(`Failed to upload ${file.name}: ${err.message}`, "error");
        }
    }

    $('#storage-upload-percent').text(`100%`);
    $('#storage-progress-bar').css('width', `100%`);

    setTimeout(() => {
        $('#storage-upload-progress').addClass('hidden');
        $('#storage-progress-bar').css('width', `0%`);
        if (successCount > 0) {
            showToast(`Successfully uploaded ${successCount} file(s)!`, "success");
            loadUserFiles(window.currentViewingStudentId);
        }
    }, 1000);
};

window.deleteFile = async (fileId) => {
    if (!confirm("Are you sure you want to delete this file from your storage?")) return;

    try {
        // Remove from Supabase (Metadata)
        const { error } = await client
            .from('personal_storage')
            .delete()
            .eq('id', fileId);

        if (error) throw error;

        showToast("File removed from storage.");
        loadUserFiles(window.currentViewingStudentId);

        // Note: Deleting from Cloudinary requires a signed request or Admin API 
        // which is usually handled via an Edge Function/Backend for security.
        // For now, we remove the record from our database.
    } catch (err) {
        console.error("Delete Error:", err);
        showToast("Failed to delete file.", "error");
    }
};

window.downloadFile = (url, filename) => {
    if (!filename) {
        window.open(url, '_blank');
        return;
    }

    // Fetch the file and trigger download with original name
    fetch(url)
        .then(response => response.blob())
        .then(blob => {
            const blobUrl = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.style.display = 'none';
            a.href = blobUrl;
            a.download = filename;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(blobUrl);
            document.body.removeChild(a);
        })
        .catch(err => {
            console.error("Download error:", err);
            window.open(url, '_blank'); // Fallback
        });
};

window.toggleFullScreenPreview = () => {
    const modalContent = document.querySelector('#filePreviewModal .modal-content');
    const icon = document.getElementById('preview-maximize-icon');
    const btn = document.getElementById('preview-fullscreen-btn');

    if (!document.fullscreenElement) {
        modalContent.requestFullscreen().then(() => {
            modalContent.classList.add('is-fullscreen');
            if (icon) {
                icon.setAttribute('data-lucide', 'minimize');
                if (typeof lucide !== 'undefined') lucide.createIcons();
            }
            if (btn) btn.setAttribute('title', 'Exit Full Screen');
        }).catch(err => {
            console.error(`Error attempting to enable full-screen mode: ${err.message}`);
            modalContent.classList.add('is-fullscreen');
            if (icon) {
                icon.setAttribute('data-lucide', 'minimize');
                if (typeof lucide !== 'undefined') lucide.createIcons();
            }
            if (btn) btn.setAttribute('title', 'Exit Full Screen');
        });
    } else {
        document.exitFullscreen().then(() => {
            modalContent.classList.remove('is-fullscreen');
            if (icon) {
                icon.setAttribute('data-lucide', 'maximize');
                if (typeof lucide !== 'undefined') lucide.createIcons();
            }
            if (btn) btn.setAttribute('title', 'Full Screen');
        }).catch(err => {
            console.error(`Error attempting to exit full-screen mode: ${err.message}`);
            modalContent.classList.remove('is-fullscreen');
            if (icon) {
                icon.setAttribute('data-lucide', 'maximize');
                if (typeof lucide !== 'undefined') lucide.createIcons();
            }
            if (btn) btn.setAttribute('title', 'Full Screen');
        });
    }

    document.onfullscreenchange = () => {
        if (!document.fullscreenElement) {
            modalContent.classList.remove('is-fullscreen');
            if (icon) {
                icon.setAttribute('data-lucide', 'maximize');
                if (typeof lucide !== 'undefined') lucide.createIcons();
            }
            if (btn) btn.setAttribute('title', 'Full Screen');
        }
    };
};

window.printPreview = () => {
    const contentArea = document.getElementById('preview-content-area');
    const iframe = contentArea.querySelector('iframe');
    if (iframe) {
        iframe.contentWindow.print();
    } else {
        // Fallback for non-iframe content (like images or code view)
        const printWindow = window.open('', '_blank');
        printWindow.document.write('<html><head><title>Print Preview</title></head><body>');
        printWindow.document.write(contentArea.innerHTML);
        printWindow.document.write('<' + '/body><' + '/html>');
        printWindow.document.close();
        printWindow.print();
    }
};

window.previewFile = async (url, name, size, type, fileList = [], currentIndex = -1) => {
    const modalEl = document.getElementById('filePreviewModal');
    const modal = bootstrap.Modal.getOrCreateInstance(modalEl);
    const ext = name.split('.').pop().toLowerCase();
    const isPdf = ext === 'pdf' || url.toLowerCase().includes('.pdf') || (type && type.includes('pdf'));
    const filenameEl = $('#preview-filename');
    const filesizeEl = $('#preview-filesize');
    const iconEl = $('#preview-icon');
    const iconContainer = $('#preview-icon-container');
    const contentArea = $('#preview-content-area');
    const loading = $('#preview-loading');
    const downloadLink = $('#preview-download-link');
    const printBtn = $('#preview-print-btn');
    const prevBtn = $('#preview-prev-btn');
    const nextBtn = $('#preview-next-btn');

    // 🛠️ CLOUDINARY PREVIEW FIX
    let previewUrl = url;
    if (url.includes('cloudinary.com')) {
        previewUrl = url.replace(/\/fl_attachment\//g, '/')
            .replace(/,fl_attachment/g, '')
            .replace(/fl_attachment,/g, '');
        previewUrl = previewUrl.replace(/([^:])\/\//g, '$1/');
    }

    // Reset UI
    filenameEl.text(name);
    filesizeEl.text(size);
    downloadLink.attr('href', url);
    contentArea.empty().addClass('hidden');
    loading.removeClass('hidden');

    // Print button visibility
    if (isPdf || ['jpg', 'jpeg', 'png', 'txt', 'html'].includes(ext)) {
        printBtn.removeClass('hidden');
    } else {
        printBtn.addClass('hidden');
    }

    // Navigation buttons
    if (fileList.length > 1 && currentIndex !== -1) {
        prevBtn.removeClass('hidden').off('click').on('click', () => {
            const prevIdx = (currentIndex - 1 + fileList.length) % fileList.length;
            const prevFile = fileList[prevIdx];
            window.previewFile(prevFile.url || prevFile.link, prevFile.name || prevFile.title, formatBytes(prevFile.size || 0), prevFile.type, fileList, prevIdx);
        });
        nextBtn.removeClass('hidden').off('click').on('click', () => {
            const nextIdx = (currentIndex + 1) % fileList.length;
            const nextFile = fileList[nextIdx];
            window.previewFile(nextFile.url || nextFile.link, nextFile.name || nextFile.title, formatBytes(nextFile.size || 0), nextFile.type, fileList, nextIdx);
        });
    } else {
        prevBtn.addClass('hidden');
        nextBtn.addClass('hidden');
    }

    // Set Icon/Color
    let icon = 'file';
    let colorClass = 'bg-slate-100 text-slate-500';
    if (['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'].includes(ext)) { icon = 'image'; colorClass = 'bg-rose-50 text-rose-500'; }
    else if (isPdf) { icon = 'file-text'; colorClass = 'bg-red-50 text-red-500'; }
    else if (['zip', 'rar', '7z'].includes(ext)) { icon = 'archive'; colorClass = 'bg-amber-50 text-amber-500'; }
    else if (['html', 'js', 'py', 'php', 'css', 'txt', 'sql', 'json'].includes(ext)) { icon = 'code'; colorClass = 'bg-indigo-50 text-indigo-500'; }

    iconContainer.attr('class', `w-10 h-10 rounded-xl flex items-center justify-center ${colorClass}`);
    iconEl.attr('data-lucide', icon);
    if (typeof lucide !== 'undefined') lucide.createIcons();

    modal.show();

    try {
        // Handle Preview Types
        let previewHtml = '';

        // 📹 VIDEO HANDLING (YouTube/Vimeo)
        const isYouTube = url.includes('youtube.com') || url.includes('youtu.be');
        const isVimeo = url.includes('vimeo.com');

        if (isYouTube || isVimeo) {
            let embedUrl = url;
            if (isYouTube) {
                const videoId = url.includes('v=') ? url.split('v=')[1].split('&')[0] : url.split('/').pop();
                embedUrl = `https://www.youtube.com/embed/${videoId}`;
            } else if (isVimeo) {
                const videoId = url.split('/').pop();
                embedUrl = `https://player.vimeo.com/video/${videoId}`;
            }
            previewHtml = `<iframe src="${embedUrl}" class="w-full h-full border-0 rounded-lg" allowfullscreen></iframe>`;
        } else if (['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'].includes(ext)) {
            previewHtml = `<div class="flex-1 flex items-center justify-center p-8 h-full overflow-auto">
                                    <img src="${previewUrl}" class="max-w-full max-h-full object-contain rounded-lg shadow-lg">
                                   </div>`;
        } else if (isPdf) {
            // 🛠️ USE GOOGLE DOCS VIEWER FOR RELIABLE PDF PREVIEW
            const gDocsUrl = `https://docs.google.com/viewer?url=${encodeURIComponent(previewUrl)}&embedded=true`;
            previewHtml = `<iframe src="${gDocsUrl}" class="w-full h-full border-0 bg-white rounded-lg"></iframe>`;
        } else if (['html', 'txt', 'js', 'css', 'json', 'py', 'php', 'sql'].includes(ext)) {
            try {
                let response;
                try {
                    response = await fetch(url);
                } catch (e) {
                    response = await fetch(previewUrl);
                }

                if (!response.ok) throw new Error(`Failed to load: ${response.status} ${response.statusText}`);
                const text = await response.text();

                if (ext === 'html') {
                    previewHtml = `<iframe srcdoc="${text.replace(/"/g, "&quot;")}" class="w-full h-full border-0 bg-white rounded-lg"></iframe>`;
                } else {
                    const escapedText = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                    previewHtml = `<div class="w-full h-full bg-[#0f172a] p-6 overflow-auto custom-scrollbar">
                                            <pre class="text-slate-300 font-mono text-sm leading-relaxed whitespace-pre-wrap break-words"><code>${escapedText}</code></pre>
                                           </div>`;
                }
            } catch (e) {
                console.error("Preview fetch error:", e);
                const gDocsUrl = `https://docs.google.com/viewer?url=${encodeURIComponent(previewUrl)}&embedded=true`;
                previewHtml = `<iframe src="${gDocsUrl}" class="w-full h-full border-0 bg-white rounded-lg"></iframe>`;
            }
        } else {
            previewHtml = `<div class="flex-1 flex flex-col items-center justify-center gap-6 h-full text-center p-10">
                                    <div class="w-24 h-24 bg-slate-100 dark:bg-slate-900 rounded-3xl flex items-center justify-center">
                                        <i data-lucide="eye-off" class="w-12 h-12 text-slate-400"></i>
                                    </div>
                                    <div>
                                        <h4 class="text-lg font-bold text-slate-800 dark:text-white mb-2">No Preview Available</h4>
                                        <p class="text-xs text-slate-500 dark:text-slate-400 max-w-xs mx-auto">This file type (${ext.toUpperCase()}) cannot be previewed directly.</p>
                                    </div>
                                    <a href="${url}" target="_blank" class="px-8 py-3 bg-indigo-600 text-white rounded-xl font-bold text-xs uppercase tracking-widest hover:bg-indigo-700 transition-all shadow-lg shadow-indigo-500/20">
                                        Download to View
                                    </a>
                                   </div>`;
        }

        contentArea.html(previewHtml).removeClass('hidden');
        loading.addClass('hidden');
        if (typeof lucide !== 'undefined') lucide.createIcons();
    } catch (err) {
        console.error("Preview Render Error:", err);
        contentArea.html(`<div class="p-10 text-center text-slate-500">Failed to load preview.</div>`).removeClass('hidden');
        loading.addClass('hidden');
    }
};

window.renderStorageList = (files) => {
    const container = $('#storage-list');
    const emptyState = $('#storage-empty');
    const countDisplay = $('#storage-count');
    const usageBar = $('#storage-usage-bar');
    const usageText = $('#storage-usage-text');
    const usagePercentText = $('#storage-usage-percent');

    container.empty();
    countDisplay.text(files.length);

    // Calculate usage (fake 100MB limit)
    const totalSize = files.reduce((acc, f) => acc + (f.size || 0), 0);
    const usagePercent = Math.min(Math.round((totalSize / (100 * 1024 * 1024)) * 100), 100);
    usageBar.css('width', `${usagePercent}%`);
    usagePercentText.text(`${usagePercent}%`);
    usageText.text(`${formatBytes(totalSize)} of 100 MB Used`);

    // Filter
    let filtered = files;
    if (window.storageFilter !== 'all') {
        const types = {
            'image': ['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'],
            'document': ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'],
            'archive': ['zip', 'rar', '7z', 'tar', 'gz'],
            'code': ['html', 'css', 'js', 'py', 'php', 'json', 'sql']
        };
        filtered = files.filter(f => {
            const ext = f.name.split('.').pop().toLowerCase();
            return types[window.storageFilter].includes(ext);
        });
    }

    // Search
    const query = $('#storage-search').val()?.toLowerCase();
    if (query) {
        filtered = filtered.filter(f => f.name.toLowerCase().includes(query));
    }

    // Sort
    filtered.sort((a, b) => {
        if (window.storageSort === 'date_desc') return new Date(b.created_at) - new Date(a.created_at);
        if (window.storageSort === 'date_asc') return new Date(a.created_at) - new Date(b.created_at);
        if (window.storageSort === 'name_asc') return a.name.localeCompare(b.name);
        if (window.storageSort === 'size_desc') return (b.size || 0) - (a.size || 0);
        return 0;
    });

    if (filtered.length === 0) {
        emptyState.removeClass('hidden');
        container.addClass('hidden');

        // Customize empty state message if viewing a student
        if (window.currentViewingStudentId) {
            emptyState.find('h5').text('Student storage is empty');
            emptyState.find('p').text('This student has not uploaded any files yet.');
        } else {
            emptyState.find('h5').text('Your personal storage is empty');
            emptyState.find('p').text('Upload your first file to get started.');
        }
        return;
    }

    emptyState.addClass('hidden');
    container.removeClass('hidden');

    if (window.storageView === 'grid') {
        container.addClass('grid grid-cols-2 md:grid-cols-4 gap-4 p-5').removeClass('divide-y divide-slate-100 dark:divide-slate-800 lg:grid-cols-5 p-6');
    } else {
        container.removeClass('grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-4 p-5 p-6').addClass('divide-y divide-slate-100 dark:divide-slate-800');
    }

    // Store current files for preview navigation
    window.currentStorageFiles = filtered;

    filtered.forEach((file, index) => {
        const ext = file.name.split('.').pop().toLowerCase();
        const size = formatBytes(file.size || 0);
        const date = new Date(file.created_at).toLocaleDateString();

        let icon = 'file';
        let color = 'text-slate-400';

        if (['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'].includes(ext)) { icon = 'image'; color = 'text-rose-500'; }
        else if (['pdf'].includes(ext)) { icon = 'file-text'; color = 'text-red-500'; }
        else if (['zip', 'rar', '7z'].includes(ext)) { icon = 'archive'; color = 'text-amber-500'; }
        else if (['html', 'js', 'py', 'php'].includes(ext)) { icon = 'code'; color = 'text-indigo-500'; }

        if (window.storageView === 'grid') {
            container.append(`
                        <div class="group bg-white dark:bg-slate-800 p-4 rounded-2xl border border-slate-100 dark:border-slate-700 hover:border-indigo-500 transition-all shadow-sm flex flex-col">
                            <div class="aspect-square rounded-xl bg-slate-50 dark:bg-slate-900/50 flex items-center justify-center mb-3 relative overflow-hidden">
                                <i data-lucide="${icon}" class="w-10 h-10 ${color}"></i>
                                <div class="absolute inset-0 bg-slate-900/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                                    <span class="text-white text-[10px] font-bold uppercase tracking-wider">File Details</span>
                                </div>
                            </div>
                            <h6 class="text-xs font-bold text-slate-800 dark:text-slate-200 truncate mb-1" title="${file.name}">${file.name}</h6>
                            <div class="flex justify-between items-center text-[10px] text-slate-400 font-medium mb-3">
                                <span>${size}</span>
                                <span>${date}</span>
                            </div>
                            <div class="flex items-center gap-1.5 pt-3 border-t border-slate-50 dark:border-slate-700/50 mt-auto">
                                <button onclick="previewFile('${file.url}', '${file.name.replace(/'/g, "\\'")}', '${size}', '${ext}', window.currentStorageFiles, ${index})" class="p-1.5 bg-indigo-50 dark:bg-indigo-900/20 hover:bg-indigo-500 hover:text-white rounded-lg text-indigo-600 dark:text-indigo-400 transition-all" title="Preview File"><i data-lucide="eye" class="w-3.5 h-3.5"></i></button>
                                <button onclick="downloadFile('${file.url}', '${file.name.replace(/'/g, "\\'")}')" class="p-1.5 bg-slate-100 dark:bg-slate-700 hover:bg-indigo-500 hover:text-white rounded-lg text-slate-500 dark:text-slate-400 transition-all" title="Download"><i data-lucide="download" class="w-3.5 h-3.5"></i></button>
                                ${!window.currentViewingStudentId || (userProfile && userProfile.role === 'admin') ? `
                                    <button onclick="replaceFile('${file.id}')" class="p-1.5 bg-slate-100 dark:bg-slate-700 hover:bg-indigo-500 hover:text-white rounded-lg text-slate-500 dark:text-slate-400 transition-all" title="Update/Replace File"><i data-lucide="refresh-cw" class="w-3.5 h-3.5"></i></button>
                                    <button onclick="renameFile('${file.id}', '${file.name.replace(/'/g, "\\'")}')" class="p-1.5 bg-slate-100 dark:bg-slate-700 hover:bg-indigo-500 hover:text-white rounded-lg text-slate-500 dark:text-slate-400 transition-all" title="Rename"><i data-lucide="edit-3" class="w-3.5 h-3.5"></i></button>
                                    <button onclick="deleteFile('${file.id}')" class="p-1.5 bg-slate-100 dark:bg-slate-700 hover:bg-rose-500 hover:text-white rounded-lg text-slate-500 dark:text-slate-400 transition-all" title="Delete"><i data-lucide="trash-2" class="w-3.5 h-3.5"></i></button>
                                ` : ''}
                            </div>
                        </div>
                    `);
        } else {
            container.append(`
                        <div class="flex items-center justify-between p-4 hover:bg-slate-50 dark:hover:bg-slate-800/50 transition-colors group">
                            <div class="flex items-center gap-3 min-w-0 flex-1">
                                <div class="w-10 h-10 rounded-lg bg-slate-100 dark:bg-slate-800 flex items-center justify-center flex-shrink-0">
                                    <i data-lucide="${icon}" class="w-5 h-5 ${color}"></i>
                                </div>
                                <div class="min-w-0 flex-1">
                                    <h6 class="text-xs font-bold text-slate-800 dark:text-slate-200 truncate" title="${file.name}">${file.name}</h6>
                                    <p class="text-[10px] text-slate-400 font-medium">${size} • ${date}</p>
                                </div>
                            </div>
                            <div class="flex items-center gap-2">
                                <button onclick="previewFile('${file.url}', '${file.name.replace(/'/g, "\\'")}', '${size}', '${ext}', window.currentStorageFiles, ${index})" class="p-2 text-slate-400 hover:text-indigo-500 hover:bg-indigo-50 dark:hover:bg-indigo-500/10 rounded-lg transition-all" title="Preview File"><i data-lucide="eye" class="w-4 h-4"></i></button>
                                <button onclick="downloadFile('${file.url}', '${file.name.replace(/'/g, "\\'")}')" class="p-2 text-slate-400 hover:text-indigo-500 hover:bg-indigo-50 dark:hover:bg-indigo-500/10 rounded-lg transition-all" title="Download"><i data-lucide="download" class="w-4 h-4"></i></button>
                                ${!window.currentViewingStudentId || (userProfile && userProfile.role === 'admin') ? `
                                    <button onclick="replaceFile('${file.id}')" class="p-2 text-slate-400 hover:text-indigo-500 hover:bg-indigo-50 dark:hover:bg-indigo-500/10 rounded-lg transition-all" title="Update/Replace File"><i data-lucide="refresh-cw" class="w-4 h-4"></i></button>
                                    <button onclick="renameFile('${file.id}', '${file.name.replace(/'/g, "\\'")}')" class="p-2 text-slate-400 hover:text-indigo-500 hover:bg-indigo-50 dark:hover:bg-indigo-500/10 rounded-lg transition-all" title="Rename"><i data-lucide="edit-3" class="w-4 h-4"></i></button>
                                    <button onclick="deleteFile('${file.id}')" class="p-2 text-slate-400 hover:text-rose-500 hover:bg-rose-50 dark:hover:bg-rose-500/10 rounded-lg transition-all" title="Delete"><i data-lucide="trash-2" class="w-4 h-4"></i></button>
                                ` : ''}
                            </div>
                        </div>
                    `);
        }
    });

    lucide.createIcons();
};

window.handleStorageSearch = (val) => {
    renderStorageList(window.userFiles);
};

window.filterStorage = (type) => {
    window.storageFilter = type;
    $('.filter-btn').removeClass('active bg-indigo-50 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400 border-indigo-100 dark:border-indigo-900/50 shadow-sm')
        .addClass('text-slate-500 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 border-transparent');
    $(`#filter-${type}`).addClass('active bg-indigo-50 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400 border-indigo-100 dark:border-indigo-900/50 shadow-sm')
        .removeClass('text-slate-500 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800 border-transparent');
    renderStorageList(window.userFiles);
};

window.sortStorage = (criteria, e) => {
    if (e) e.stopPropagation();
    window.storageSort = criteria;
    $('#sort-menu-dropdown').addClass('hidden');

    // Update active state in menu
    $('#sort-menu-dropdown button').removeClass('text-indigo-600 dark:text-indigo-400 active-sort').addClass('text-slate-600 dark:text-slate-300');
    $(e.target).closest('button').addClass('text-indigo-600 dark:text-indigo-400 active-sort').removeClass('text-slate-600 dark:text-slate-300');

    renderStorageList(window.userFiles);
};

window.toggleStorageView = (view) => {
    window.storageView = view;
    if (view === 'grid') {
        $('#btn-view-grid').addClass('bg-white dark:bg-slate-700 text-indigo-600 dark:text-indigo-400 shadow-sm').removeClass('text-slate-400');
        $('#btn-view-list').removeClass('bg-white dark:bg-slate-700 text-indigo-600 dark:text-indigo-400 shadow-sm').addClass('text-slate-400');
    } else {
        $('#btn-view-list').addClass('bg-white dark:bg-slate-700 text-indigo-600 dark:text-indigo-400 shadow-sm').removeClass('text-slate-400');
        $('#btn-view-grid').removeClass('bg-white dark:bg-slate-700 text-indigo-600 dark:text-indigo-400 shadow-sm').addClass('text-slate-400');
    }
    renderStorageList(window.userFiles);
};

window.toggleSortMenu = (e) => {
    e.stopPropagation();
    $('#sort-menu-dropdown').toggleClass('hidden');
};

// Initialize drag & drop and file input listeners
$(document).ready(() => {
    const dropZone = document.getElementById('storage-upload-area');
    const fileInput = document.getElementById('storage-file-input');
    const replaceInput = document.getElementById('storage-replace-input');

    if (replaceInput) {
        replaceInput.addEventListener('change', (e) => {
            if (e.target.files && e.target.files[0]) {
                handleReplaceUpload(window.replacingFileId, e.target.files[0]);
            }
        });
    }

    if (dropZone && fileInput) {
        fileInput.addEventListener('change', (e) => {
            uploadFile(e.target.files);
        });

        dropZone.addEventListener('dragover', (e) => {
            e.preventDefault();
            dropZone.classList.add('border-indigo-500', 'bg-indigo-50/50', 'dark:bg-indigo-900/20');
        });

        ['dragleave', 'drop'].forEach(evt => {
            dropZone.addEventListener(evt, () => {
                dropZone.classList.remove('border-indigo-500', 'bg-indigo-50/50', 'dark:bg-indigo-900/20');
            });
        });

        dropZone.addEventListener('drop', (e) => {
            e.preventDefault();
            const files = e.dataTransfer.files;
            uploadFile(files);
        });
    }

    // Close sort menu on click outside
    $(document).on('click', () => $('#sort-menu-dropdown').addClass('hidden'));
});

function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

window.deleteSubmission = async (id) => {
    if (!confirm('Are you sure you want to delete this submission?')) return;
    const { error } = await client.from('submissions').delete().eq('id', id);
    if (!error) {
        showToast('Submission deleted successfully');
        loadCachedData();
    } else {
        showToast("Error deleting submission: " + error.message, 'error');
    }
};

window.deleteResource = async (id) => {
    if (!confirm('Delete this resource?')) return;
    const { error } = await client.from('resources').delete().eq('id', id);
    if (!error) {
        showToast('Resource deleted');
        if (window.fetchResources) window.fetchResources();
    } else {
        console.error(error);
        showToast('Error deleting resource (Check DB/Console)', 'error');
    }
};

// MANUAL OVERLAY LOGIC (Bypassing Bootstrap)
window.adminResetPassword = async (uid, name) => {
    const newPass = prompt(`Set new password for ${name || 'User'}: `);
    if (newPass) {
        if (newPass.length < 6) return alert("Password must be at least 6 characters.");

        try {
            // Try RPC call first (Requires 'admin_reset_password' function in DB)
            const { error } = await client.rpc('admin_reset_password', {
                target_user_id: uid,
                new_password: newPass
            });

            if (error) {
                console.warn("RPC Failed, trying fallback...", error);
                throw error;
            }

            alert("Password updated successfully!");
        } catch (e) {
            console.error("Password Reset Error:", e);
            navigator.clipboard.writeText(newPass);
            alert(`Password reset failed (Backend function missing?).\n\nNew Password: ${newPass}\n(Copied to clipboard)\n\nTech Note: Please run 'reset_password_function.sql' in Supabase SQL Editor.`);
        }
    }
};

window.adminResetExam = async (uid, name) => {
    if (!confirm(`Are you sure you want to RESET the exam for ${name}? \n\nThis will: \n1. Delete their exam result record. \n2. Allow them to retake the test.`)) return;

    try {
        // Delete from exam_results
        const { error } = await client.from('exam_results').delete().eq('student_id', uid);

        if (error) {
            console.error("Exam Reset Error:", error);
            if (error.code === '42501' || error.message.includes('row level security')) {
                alert("PERMISSION ERROR: You cannot delete exam records yet.\n\nPlease run the 'fix_exam_permissions.sql' script in your Supabase SQL Editor to enable this feature.");
            } else {
                showToast('Failed to reset exam record: ' + error.message, 'error');
            }
        } else {
            showToast(`Exam reset successfully for ${name}.`);
            // Refresh the user list to show updated status (e.g. pending instead of done)
            if (window.fetchUsers) window.fetchUsers();
        }
    } catch (e) {
        console.error("Exam Reset Exception:", e);
        showToast('An unexpected error occurred.', 'error');
    }
};

window.setupRealtime = () => {
    // Task Comments Realtime
    client.channel('public:task_comments').on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'task_comments' }, payload => {
        if (currentTask && payload.new.task_id === currentTask.id) fetchComments(currentTask.id);
    }).subscribe();

    // Submissions Realtime (Admin Notification)
    if (userProfile.role === 'admin') {
        client.channel('public:submissions').on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'submissions' }, payload => {
            window.notifyAdmin(payload.new);
            fetchData(); // Refresh data immediately
        }).subscribe();
    }

    // --- PRESENCE (Enhanced for Online Tracking) ---
    const presenceChannel = client.channel('online-users', {
        config: {
            presence: { key: currentUser.id },
            broadcast: { self: true } // Allow receiving own broadcasts for testing if needed
        }
    });

    // Activity Tracking State
    let lastActive = Date.now();
    let currentStatus = 'online'; // online, idle
    let currentActivity = 'Dashboard'; // Dashboard, Viewing Task X, etc.

    // Sync Helper
    const syncPresence = async () => {
        const newState = {
            user_id: currentUser.id,
            user_name: userProfile.name,
            role: userProfile.role,
            online_at: new Date().toISOString(),
            status: currentStatus,
            activity: currentActivity
        };
        await presenceChannel.track(newState);
    };

    // Activity Listeners (Reset Idle Timer)
    const resetIdleTimer = () => {
        lastActive = Date.now();
        if (currentStatus === 'idle') {
            currentStatus = 'online';
            syncPresence();
        }
    };
    ['mousemove', 'keydown', 'click', 'scroll'].forEach(evt => document.addEventListener(evt, resetIdleTimer));

    // Idle Check Loop (Every 1 min)
    setInterval(() => {
        if (Date.now() - lastActive > 5 * 60 * 1000) { // 5 Minutes
            if (currentStatus !== 'idle') {
                currentStatus = 'idle';
                syncPresence();
            }
        }
    }, 60000);

    // Export for Global Usage
    window.updateActivity = (activityName) => {
        if (currentActivity !== activityName) {
            currentActivity = activityName;
            syncPresence();
        }
    };

    presenceChannel.on('presence', { event: 'sync' }, () => {
        const state = presenceChannel.presenceState();
        const allPresences = [];
        for (const key in state) {
            allPresences.push(...state[key]);
        }

        // Deduplicate users (prioritize ONLINE over IDLE)
        const uniqueUsersMap = new Map();
        allPresences.forEach(p => {
            const existing = uniqueUsersMap.get(p.user_id);
            if (!existing) {
                uniqueUsersMap.set(p.user_id, p);
            } else {
                // If current stored is IDLE and new one is ONLINE, swap it
                if (existing.status === 'idle' && p.status === 'online') {
                    uniqueUsersMap.set(p.user_id, p);
                }
            }
        });

        window.onlineUsers = Array.from(uniqueUsersMap.values());

        // Admin Update Logic
        if (userProfile.role === 'admin') {
            const students = window.onlineUsers.filter(u => u.role === 'student');

            // Update User List Count
            const countEl = document.getElementById('online-student-count');
            if (countEl) {
                countEl.innerText = `${students.length} Online`;
                $(countEl).removeClass('hidden');
            }

            // Update Dashboard Widget
            const dashCount = document.getElementById('dashboard-online-count');
            if (dashCount) {
                dashCount.innerText = students.length;
                $('#admin-live-widget').removeClass('hidden');
            }

            // Initial Notification
            if (!window.hasShownOnlineNotif && students.length > 0) {
                window.hasShownOnlineNotif = true;
                showToast(`${students.length} Students are currently Online`, 'success');
            }

            // Refresh Table to show Online indicators
            if (window.allUsersCache) {
                renderUsers(window.allUsersCache);
            }

            // Live Update Modal if Open
            if ($('#onlineUsersModal').hasClass('show')) {
                window.showOnlineStudentsModal();
            }
        }
    });

    presenceChannel.subscribe(async (status) => {
        if (status === 'SUBSCRIBED') {
            await syncPresence();
        }
    });

    // Nudge Listener (Broadcast)
    presenceChannel.on('broadcast', { event: 'nudge' }, ({ payload }) => {
        if (payload.target_id === currentUser.id) {
            // Play Alert Sound
            const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3');
            audio.play().catch(e => { });

            // Show SweetAlert
            Swal.fire({
                title: '👋 Admin Nudge!',
                text: 'Admin is requesting your attention. Please check your pending tasks.',
                icon: 'info',
                confirmButtonText: 'Okay, I am here!',
                confirmButtonColor: '#6366f1',
                timer: 10000,
                timerProgressBar: true
            }).then((result) => {
                // Ack by resetting idle
                resetIdleTimer();

                // Send Acknowledgement to Admin
                if (result.isConfirmed) {
                    presenceChannel.send({
                        type: 'broadcast',
                        event: 'nudge-ack',
                        payload: {
                            user_name: userProfile.name,
                            user_id: currentUser.id
                        }
                    });
                }
            });
        }
    });

    // Nudge Acknowledgement Listener (For Admin)
    presenceChannel.on('broadcast', { event: 'nudge-ack' }, ({ payload }) => {
        if (userProfile.role === 'admin') {
            // Play subtle sound
            const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2578/2578-preview.mp3'); // Ping sound
            audio.volume = 0.5;
            audio.play().catch(e => { });

            showToast(`✅ ${payload.user_name} acknowledged your nudge!`, 'success');
        }
    });

    // Typing Indicators (Broadcast) - Only for Task Hub now
    presenceChannel.on('broadcast', { event: 'typing' }, ({ payload }) => {
        if (payload.target_id === currentTask?.id) {
            $('#comments-container').append(`<div id="typing-tmp" class="text-[7px] font-black text-slate-400 italic mb-2 uppercase tracking-widest">${payload.user_name} is typing...</div>`);
            setTimeout(() => $('#typing-tmp').remove(), 2000);
        }
    });

    window.broadcastTyping = (targetId = null) => {
        presenceChannel.send({ type: 'broadcast', event: 'typing', payload: { user_name: userProfile.name, target_id: targetId } });
    };

    // ARCADE GLOBAL SYNC (REALTIME)
    // Auto-Dismiss Update Banner
    setTimeout(() => {
        $('#v2-banner').fadeOut(500);
    }, 5000);

    // ARCADE GLOBAL SYNC (REALTIME DB)
    const arcadeChannel = client.channel('arcade-control');
    arcadeChannel.on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'arcade_config' }, payload => {
        // Ensure we catch the update for row id=1
        if (payload.new.id === 1) {
            const isUnlocked = payload.new.is_unlocked;
            const strState = isUnlocked.toString();

            if (localStorage.getItem('global_arcade_unlock') !== strState) {
                localStorage.setItem('global_arcade_unlock', strState);

                // UI Update Logic
                if (activeTab === 'arcade') {
                    if (isUnlocked) {
                        $('#arcade-locked').addClass('hidden');
                        $('#arcade-menu').removeClass('hidden');
                        showToast("Arcade Unlocked by Admin!");
                    } else {
                        $('#arcade-locked').removeClass('hidden');
                        $('#arcade-menu').addClass('hidden');
                        $('#game-stage').addClass('hidden'); // Also quit active game
                        showToast("Arcade Locked by Admin!");
                    }
                }

                // If Admin, reflect in Toggle Button (optional, but switchTab covers it)
                // This ensures instant feedback even if not focusing on tab switch
                if (userProfile.role === 'admin') {
                    const btn = $('#arcade-toggle-btn');
                    if (isUnlocked) {
                        btn.removeClass('bg-slate-800 text-slate-400 opacity-50').addClass('bg-emerald-500 text-white shadow-lg shadow-emerald-500/30').html('<i data-lucide="gamepad-2" class="w-5 h-5"></i>');
                    } else {
                        btn.removeClass('bg-emerald-500 text-white shadow-lg shadow-emerald-500/30').addClass('bg-slate-800 text-slate-400 opacity-50').html('<i data-lucide="lock" class="w-5 h-5"></i>');
                    }
                    lucide.createIcons();
                }
            }
        }
    }).subscribe();

    // Deprecated: Broadcast is now handled via DB updates
    window.broadcastArcadeState = (isUnlocked) => { /* No-op, managed by DB triggers */ };

    window.notifyAdmin = (sub) => {
        // Play Sound (Subtle)
        const audio = new Audio('https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3');
        audio.volume = 0.5;
        audio.play().catch(e => console.log('Audio play failed', e));

        const toastId = 'notif-' + Date.now();
        const toastHTML = `
            <div id="${toastId}" class="fixed top-20 right-10 z-[6000] cursor-pointer" onclick="switchTab('grading')">
                <div class="bg-white dark:bg-[#1e293b] border-l-4 border-indigo-500 rounded-lg shadow-2xl p-4 flex items-start gap-4 animate-in slide-in-from-right-10 duration-500">
                    <div class="w-10 h-10 rounded-full bg-indigo-50 dark:bg-indigo-900/30 text-indigo-500 flex items-center justify-center shrink-0">
                        <i data-lucide="bell-ring" class="w-5 h-5"></i>
                    </div>
                    <div class="min-w-[200px]">
                        <h4 class="text-xs font-black uppercase text-indigo-500 tracking-wider mb-1">New Submission</h4>
                        <p class="text-[11px] font-bold text-slate-800 dark:text-slate-100 leading-tight mb-1">${sub.student_name}</p>
                        <p class="text-[9px] text-slate-400 uppercase tracking-wide truncate w-40">${sub.task_title}</p>
                    </div>
                </div>
            </div>`;

        $('body').append(toastHTML);
        lucide.createIcons();

        setTimeout(() => {
            $(`#${toastId} `).fadeOut(500, function () { $(this).remove(); });
        }, 6000);
    };
};

window.sendGlobalMessage = async () => {
    const el = $('#global-chat-input');
    const content = el.val().trim();
    if (!content) return;
    el.val('');
    const { error } = await client.from('global_messages').insert([{ user_id: currentUser.id, user_name: userProfile.name, role: userProfile.role, content }]);
    if (error) {
        console.error("Insert Error:", error);
        alert("Message Failed: " + error.message);
        el.val(content); // Restore message
    }
};

$('#comment-input').on('keydown', () => broadcastTyping(currentTask?.id));


window.showOnlineStudentsModal = () => {
    const students = window.onlineUsers ? window.onlineUsers.filter(u => u.role === 'student') : [];
    const list = $('#online-users-list').empty();

    if (students.length === 0) {
        list.html('<div class="text-center py-8 text-slate-400 font-bold uppercase tracking-widest text-xs">No students currently online</div>');
    } else {
        students.forEach(s => {
            const onlineSince = s.online_at ? new Date(s.online_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Just now';
            const isIdle = s.status === 'idle';
            const activity = s.activity || 'Dashboard';

            list.append(`
                        <div class="flex items-center gap-3 p-3 rounded-lg bg-slate-50 dark:bg-slate-800 border border-slate-100 dark:border-slate-700">
                            <div class="relative w-8 h-8 rounded-full ${isIdle ? 'bg-amber-500/10 text-amber-500' : 'bg-emerald-500/10 text-emerald-500'} flex items-center justify-center">
                                <i data-lucide="${isIdle ? 'coffee' : 'wifi'}" class="w-4 h-4"></i>
                                <div class="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 rounded-full border-2 border-white dark:border-slate-800 ${isIdle ? 'bg-amber-500' : 'bg-emerald-500'}"></div>
                            </div>
                            <div class="flex-1 min-w-0">
                                <div class="flex items-center justify-between mb-0.5">
                                    <p class="text-xs font-black text-slate-900 dark:text-slate-200 uppercase tracking-tight truncate">${s.user_name}</p>
                                    <span class="text-[8px] font-bold uppercase tracking-widest ${isIdle ? 'text-amber-500' : 'text-emerald-500'}">${isIdle ? 'IDLE' : 'ACTIVE'}</span>
                                </div>
                                <p class="text-[9px] text-indigo-500 font-bold uppercase tracking-wide truncate mb-0.5"><i data-lucide="eye" class="w-2.5 h-2.5 inline mr-0.5"></i> ${activity}</p>
                                <p class="text-[8px] text-slate-400 font-bold uppercase tracking-widest">Since ${onlineSince}</p>
                            </div>
                            <button onclick="nudgeStudent('${s.user_id}', '${s.user_name}')" class="w-8 h-8 rounded-full bg-indigo-50 dark:bg-indigo-900/30 text-indigo-500 hover:bg-indigo-100 dark:hover:bg-indigo-900/50 flex items-center justify-center transition-colors" title="Nudge Student">
                                <i data-lucide="bell-ring" class="w-4 h-4"></i>
                            </button>
                        </div>
                    `);
        });
    }

    lucide.createIcons();
    // Only show if not already shown (to avoid flicker during re-render)
    if (!$('#onlineUsersModal').hasClass('show')) {
        new bootstrap.Modal(document.getElementById('onlineUsersModal')).show();
    }
};

window.nudgeStudent = async (uid, name) => {
    const client = supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
    const channel = client.channel('online-users');

    // Send Broadcast
    await channel.send({
        type: 'broadcast',
        event: 'nudge',
        payload: { target_id: uid }
    });

    // Feedback
    const btn = $(event.currentTarget);
    const originalIcon = btn.html();
    btn.html('<div class="spinner-border spinner-border-sm text-indigo-500"></div>');
    setTimeout(() => {
        btn.html(originalIcon);
        showToast(`Nudged ${name}!`, 'success');
    }, 800);
};

window.toggleSidebarCollapse = () => {
    const sidebar = $('#main-sidebar');
    const content = $('.content-main');
    const icon = $('#collapse-icon');

    sidebar.toggleClass('collapsed');
    content.toggleClass('expanded');

    // Rotate Icon
    if (sidebar.hasClass('collapsed')) {
        icon.css('transform', 'rotate(180deg)');
        localStorage.setItem('sidebar_collapsed', 'true');
    } else {
        icon.css('transform', 'rotate(0deg)');
        localStorage.setItem('sidebar_collapsed', 'false');
    }
};

// Init State
$(document).ready(() => {
    if (localStorage.getItem('sidebar_collapsed') === 'true') {
        window.toggleSidebarCollapse();
    }
});

window.renderSubmitForm = (taskId) => {
    // Check if this is an UPDATE (Resubmission)
    const isUpdate = window.currentSub && (window.currentSub.task_id == taskId || window.currentSub.task_id === String(taskId));

    // Pre-fill data if updating
    let existingGithub = '';
    let existingLive = '';
    if (isUpdate && window.currentSub.content) {
        try {
            const parsed = JSON.parse(window.currentSub.content);
            existingGithub = parsed.github || '';
            existingLive = parsed.live || '';
        } catch (e) { }
    }

    const heading = isUpdate ? 'Replace / Update Submission' : 'Upload Submission';
    const btnText = isUpdate ? 'Update Task' : 'Submit Task';
    const fileLabel = isUpdate ? 'Upload New File (Replaces Old)' : 'Upload File';

    $('#submission-section').html(`
            <form id="submit-form" class="space-y-6">
                <input type="hidden" id="submit-id" value="${taskId}">
                    
                    <div class="mb-2 text-center">
                         <span class="text-[9px] font-black uppercase tracking-widest ${isUpdate ? 'text-amber-500' : 'text-slate-400'}">${heading}</span>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div class="space-y-4">
                            <div class="group relative bg-slate-50 dark:bg-slate-800/30 border-2 border-dashed border-slate-200 dark:border-slate-700 rounded-3xl p-6 text-center hover:border-indigo-500 transition-all cursor-pointer overflow-hidden h-full flex flex-col items-center justify-center">
                                <div class="absolute inset-0 bg-indigo-500/5 opacity-0 group-hover:opacity-100 transition-opacity"></div>
                                <input type="file" id="submit-file" class="absolute inset-0 opacity-0 cursor-pointer z-10" onchange="$('#file-name').text(this.files[0].name)">
                                    <div class="relative z-0">
                                        <div class="w-12 h-12 bg-white dark:bg-slate-800 shadow-xl rounded-2xl flex items-center justify-center text-indigo-600 mx-auto mb-2 group-hover:scale-110 transition-transform">
                                            <i data-lucide="${isUpdate ? 'refresh-cw' : 'upload-cloud'}" class="w-6 h-6"></i>
                                        </div>
                                        <p class="font-black text-slate-900 dark:text-slate-200 uppercase tracking-tight text-[10px]">${fileLabel}</p>
                                        <p class="text-[8px] text-slate-400 font-bold uppercase tracking-widest mt-1" id="file-name">Optional</p>
                                    </div>
                            </div>
                        </div>
                        <div class="space-y-3">
                            <div>
                                <label class="text-[8px] font-black text-slate-400 uppercase tracking-widest mb-1 block">GitHub Repository URL</label>
                                <input type="url" id="submit-github" value="${existingGithub}" placeholder="https://github.com/username/project" class="w-full p-3 bg-slate-50 dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-xl text-xs font-bold outline-none focus:border-indigo-500 dark:text-slate-200 transition-colors">
                            </div>
                            <div>
                                <label class="text-[8px] font-black text-slate-400 uppercase tracking-widest mb-1 block">Live Demo Link</label>
                                <input type="url" id="submit-live" value="${existingLive}" placeholder="https://my-project.vercel.app" class="w-full p-3 bg-slate-50 dark:bg-slate-800 border border-slate-100 dark:border-slate-700 rounded-xl text-xs font-bold outline-none focus:border-emerald-500 dark:text-slate-200 transition-colors">
                            </div>
                        </div>
                    </div>
                    <button type="submit" class="w-full btn-command">${btnText}</button>
                </form>`).removeClass('hidden');
    lucide.createIcons();
};

window.enableResubmission = () => {
    const taskId = currentTask.id;
    window.renderSubmitForm(taskId);
    if (currentSub) {
        const data = parseSubmission(currentSub.content);
        if (data.github) $('#submit-github').val(data.github);
        if (data.live) $('#submit-live').val(data.live);
        $('#submit-form button').text('Update Submission');
    }
};



// Reset for Create Mode
$('#create-task-btn').on('click', () => {
    editingTaskId = null;
    $('#create-task-form')[0].reset();
    $('#createTaskModal .modal-title').text('Create New Task');
    $('#task-submit-btn').text('Create Task');
});

window.renderStatusCard = (sub) => {
    return `
            <div class="p-10 bg-indigo-50 dark:bg-indigo-900/20 text-indigo-600 dark:text-indigo-400 rounded-3xl text-center font-black uppercase tracking-[0.2em] text-[10px] border border-indigo-100 dark:border-indigo-900/50 flex flex-col items-center gap-4">
                <i data-lucide="check-circle-2" class="w-8 h-8 animate-in zoom-in duration-300"></i> 
                <div>
                    <p class="text-[8px] opacity-70 mb-1">SUBMISSION STATUS</p>
                    <p class="text-xs">RECEIVED: ${(sub.task_title || 'Task Submitted')}</p>
                </div>
                <p class="text-[8px] bg-indigo-100 dark:bg-indigo-500/20 px-4 py-2 rounded-full mt-2">Result Pending</p>
                <div class="flex gap-2 justify-center mt-3">
                    ${(() => {
            const data = parseSubmission(sub.content);
            let html = '';
            if (data.file) html += `<a href="${formatDownloadUrl(data.file)}" target="_blank" class="text-[8px] font-black uppercase text-indigo-500 hover:underline flex items-center gap-1"><i data-lucide="file" class="w-2.5 h-2.5"></i> File</a>`;
            if (data.github) html += `<a href="${data.github}" target="_blank" class="text-[8px] font-black uppercase text-slate-500 hover:text-indigo-500 flex items-center gap-1"><i data-lucide="github" class="w-2.5 h-2.5"></i> Code</a>`;
            if (data.live) html += `<a href="${data.live}" target="_blank" class="text-[8px] font-black uppercase text-emerald-500 hover:underline flex items-center gap-1"><i data-lucide="globe" class="w-2.5 h-2.5"></i> Live</a>`;
            return html;
        })()}
                </div>
                <button onclick="enableResubmission()" class="mt-4 px-6 py-2 bg-white dark:bg-indigo-950 text-indigo-500 border border-indigo-200 dark:border-indigo-800 rounded-xl text-[9px] font-black uppercase tracking-widest hover:bg-indigo-50 dark:hover:bg-indigo-900/40 transition-all shadow-sm">
                    Resubmit / Replace
                </button>
            </div>`;
};

// Global variable to track who Admin is replying to
window.replyTargetStub = null; // { id: 'uuid', name: 'Student Name' }

window.fetchComments = async (taskId) => {
    // Fetch ALL comments for the task (Client-side filtering for context)
    const { data: comments } = await client.from('task_comments').select('*').eq('task_id', taskId).order('created_at', { ascending: true });

    if (!comments) { renderComments([]); return; }

    // Filter Logic
    // Filter Logic
    const filtered = comments.filter(c => {
        let contentObj;
        try {
            contentObj = JSON.parse(c.content);
            // Check if it has our protocol structure - if neither exists, it's legacy
            if (contentObj.sid === undefined && contentObj.txt === undefined) throw new Error("Legacy");
        } catch (e) {
            // Legacy or Plain Text
            // If Admin sent it legacy, assume Broadcast (sid: null)
            // If Student sent it legacy, assume it belongs to them (sid: c.user_id)
            const isAdm = c.role === 'admin';
            contentObj = {
                txt: c.content,
                sid: isAdm ? null : c.user_id
            };
        }

        // Attach parsed obj to comment for render
        c._parsed = contentObj;

        if (userProfile.role === 'admin') return true; // Admin sees all

        // Student: See OWN messages OR Admin messages targeted at them OR General Admin Broadcasts
        if (c.user_id === currentUser.id) return true; // My sent items

        // Targeted at me (Robust check)
        if (contentObj.sid && String(contentObj.sid) === String(currentUser.id)) return true;

        // General Admin Message (Broadcast) - i.e., no specific target
        if (c.role === 'admin' && !contentObj.sid) return true;

        return false;
    });

    renderComments(filtered);
};

function renderComments(comments) {
    const container = $('#comments-container').empty();

    // Clear reply stub if re-rendering (optional, but cleaner)
    // if (window.replyTargetStub) cancelReply(); 

    if (!comments.length) {
        container.html('<div class="text-center py-8 text-slate-400 text-[9px] font-bold uppercase tracking-widest italic opacity-50">No messages found.</div>');
        return;
    }

    comments.forEach(c => {
        const isAdmin = c.role === 'admin';
        const isMe = c.user_id === currentUser.id;

        // Use pre-parsed content or safe parse
        const data = c._parsed || (() => { try { return JSON.parse(c.content) } catch (e) { return { txt: c.content, sid: c.user_id } } })();
        const text = data.txt || c.content; // Fallback

        // For Admin: Show who the message belongs to contextually if likely mixed
        // If I am admin, and this msg is from a student, show "Reply" action
        let actions = '';
        if (userProfile.role === 'admin' && !isMe) {
            actions = `<button onclick="setReplyContext('${c.user_id}', '${c.user_name}')" class="ml-2 text-[8px] text-indigo-400 hover:text-indigo-600 font-bold uppercase tracking-wider opacity-0 group-hover:opacity-100 transition-opacity flex items-center gap-1"><i data-lucide="reply" class="w-2.5 h-2.5"></i> Reply</button>`;
        }

        container.append(`
            <div class="flex flex-col ${isMe ? 'items-end' : 'items-start'} animate-in fade-in slide-in-from-bottom-2 mb-4 group w-full">
                        <div class="flex items-center gap-2 mb-1">
                             <span class="text-[9px] font-black uppercase px-1 ${isAdmin ? 'text-rose-500' : 'text-indigo-500'}">${c.user_name}</span>
                             ${actions}
                        </div>
                        <div class="max-w-[85%] p-3 rounded-2xl text-[10px] font-medium shadow-sm border border-slate-100 dark:border-slate-800 ${isMe ? 'bg-indigo-600 text-white border-transparent rounded-tr-none' : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 rounded-tl-none'} break-words whitespace-pre-wrap">
                            ${text}
                        </div>
                        <span class="text-[6px] text-slate-400 font-bold mt-1 opacity-100 transition-opacity">${new Date(c.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                    </div>
            `);
    });
    container.scrollTop(container[0].scrollHeight);
    lucide.createIcons();
}

window.setReplyContext = (sid, name) => {
    window.replyTargetStub = { id: sid, name: name };
    const input = $('#comment-input');
    input.focus();

    // Show Reply UI Indicator
    if ($('#reply-indicator').length === 0) {
        $('<div id="reply-indicator" class="flex items-center justify-between px-4 py-2 bg-indigo-50 dark:bg-indigo-900/20 border-t border-indigo-100 dark:border-indigo-800 text-[9px] font-bold text-indigo-600 mx-4 mt-2 rounded-t-lg"></div>').insertBefore('#comment-input-area');
    }
    $('#reply-indicator').html(`<span>Replying to: ${name}</span> <button onclick="cancelReply()" class="text-rose-500 hover:underline">Cancel</button>`).removeClass('hidden');
};

window.cancelReply = () => {
    window.replyTargetStub = null;
    $('#reply-indicator').addClass('hidden');
};

window.postComment = async () => {
    const content = $('#comment-input').val().trim();
    if (!content) return;
    const taskId = currentTask.id;

    // Determine Target Thread
    // Student: Always their own thread (sid = currentUser.id)
    // Admin: Thread ID of the student they are replying to. If no reply context, it's a "General" message (sid = null)
    let sid = (userProfile.role === 'student') ? currentUser.id : (window.replyTargetStub ? window.replyTargetStub.id : null);

    // Payload Structure: { txt: "Message", sid: "StudentUUID" }
    const payload = JSON.stringify({
        txt: content,
        sid: sid
    });

    $('#comment-input').val('');
    if (window.cancelReply) window.cancelReply(); // Reset reply state

    const { error } = await client.from('task_comments').insert([{
        task_id: taskId,
        user_id: currentUser.id,
        user_name: userProfile.name,
        role: userProfile.role,
        content: payload
    }]);

    if (!error) fetchComments(taskId);
};

$(document).on('submit', '#submit-form', async (e) => {
    e.preventDefault();
    const btn = $('#submit-form button');
    btn.prop('disabled', true).text('PROCESSING...');

    const file = document.getElementById('submit-file').files[0];
    const github = $('#submit-github').val()?.trim();
    const live = $('#submit-live').val()?.trim();
    const taskId = $('#submit-id').val();

    if (!file && !github && !live) {
        showToast("Please upload a file OR provide a link.");
        btn.prop('disabled', false).text('Submit Task');
        return;
    }

    try {
        let cloudFileUrl = null;
        const CLOUD_NAME = "dwowte8ny";
        const UPLO_PRESET = "navttc-lms";

        if (file) {
            const formData = new FormData();
            formData.append('file', file);
            formData.append('upload_preset', UPLO_PRESET);
            const response = await fetch(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/auto/upload`, { method: 'POST', body: formData });
            const uploadData = await response.json();
            if (uploadData.error) throw new Error(uploadData.error.message);
            cloudFileUrl = uploadData.secure_url;
        }

        // Construct JSON Content
        const submissionData = {
            file: cloudFileUrl,
            github: github || null,
            live: live || null,
            timestamp: new Date().toISOString() // Metadata
        };

        // Resolve Task Title safely
        const activeTask = window.currentTask || (window.allTasks ? window.allTasks.find(t => String(t.id) === String(taskId)) : null);
        const safeTitle = activeTask ? activeTask.title : 'Task Submission';

        let dbOp;
        // If we have a current submission for this task, UPDATE it
        if (window.currentSub && window.currentSub.task_id == taskId) {
            if (window.currentSub.status === 'graded') {
                throw new Error("Cannot resubmit a graded task.");
            }
            console.log("Updating existing submission:", window.currentSub.id);
            dbOp = client.from('submissions').update({
                content: JSON.stringify(submissionData),
                status: 'submitted', // Ensure status is submitted (in case we add other statuses later)
                submitted_at: new Date().toISOString()
            }).eq('id', window.currentSub.id);
        } else {
            // Create NEW submission
            dbOp = client.from('submissions').insert([{
                task_id: taskId,
                task_title: safeTitle,
                student_id: currentUser.id,
                student_name: userProfile.name,
                content: JSON.stringify(submissionData),
                status: 'submitted',
                submitted_at: new Date().toISOString()
            }]);
        }

        const { error: dbErr } = await dbOp;

        if (dbErr) throw dbErr;

        // REFRESH DATA & UI
        // Update global state immediately for the status card to work if re-opened
        const fakeSub = {
            ...submissionData,
            task_title: safeTitle,
            content: JSON.stringify(submissionData),
            status: 'submitted'
        };

        // Force UI update manually to guarantee the form disappears
        $('#submission-section').html(window.renderStatusCard(fakeSub));
        lucide.createIcons();

        await fetchData(); // Refresh background data
        showToast("Work Submitted Successfully!");
        confetti({ particleCount: 150, spread: 70, origin: { y: 0.6 } });

        // openDetail(taskId); // No longer needed, manual update handles it cleaner

    } catch (err) {
        console.error("Submission Error:", err);
        alert("Error: " + err.message);
    } finally {
        btn.prop('disabled', false).text('Submit Task');
    }
});



// Global function to toggle manual resubmission
window.enableResubmission = () => {
    // Simply render the form for the current task
    if (window.currentTask) {
        window.renderSubmitForm(window.currentTask.id);
    }
};

// --- PROFILE AVATAR CROP & UPLOAD ---
let cropper;
const cropImage = document.getElementById('crop-image');
const cropModal = new bootstrap.Modal(document.getElementById('cropModal'));

$('#profile-upload').on('change', function () {
    const file = this.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = function (e) {
        cropImage.src = e.target.result;
        cropModal.show();
    };
    reader.readAsDataURL(file);
    this.value = ''; // Reset input
});

// Initialize Cropper when modal opens
document.getElementById('cropModal').addEventListener('shown.bs.modal', () => {
    if (cropper) cropper.destroy();
    cropper = new Cropper(cropImage, {
        aspectRatio: 1,
        viewMode: 1,
        dragMode: 'move',
        autoCropArea: 1,
        background: false
    });
});

// Handle Crop & Upload
$('#crop-confirm-btn').on('click', async function () {
    if (!cropper) return;

    const btn = $(this);
    const originalText = btn.html();
    btn.prop('disabled', true).html('<i class="w-3 h-3 animate-spin mr-1" data-lucide="loader-2"></i> Processing...');
    lucide.createIcons();

    cropper.getCroppedCanvas({
        width: 300,
        height: 300,
        imageSmoothingQuality: 'high'
    }).toBlob(async (blob) => {
        if (!blob) return;

        const CLOUD_NAME = "dwowte8ny";
        const UPLO_PRESET = "navttc-lms";
        const formData = new FormData();
        formData.append('file', blob, 'avatar.png');
        formData.append('upload_preset', UPLO_PRESET);

        try {
            const response = await fetch(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/image/upload`, {
                method: 'POST',
                body: formData
            });

            const data = await response.json();
            if (data.error) throw new Error(data.error.message);

            const avatarUrl = data.secure_url;

            // Update DB
            const { error } = await client.from('profiles').update({ avatar_url: avatarUrl }).eq('uid', currentUser.id);
            if (error) throw error;

            // Update State
            userProfile.avatar_url = avatarUrl;
            localStorage.setItem('supabase_profile_cache', JSON.stringify(userProfile));

            // Update UI
            $('#header-avatar-container').html(`<img src="${avatarUrl}" class="w-full h-full object-cover">`);
            $('#profile-avatar-display').html(`<img src="${avatarUrl}" class="w-full h-full object-cover">`);

            showToast("Profile updated successfully!");
            cropModal.hide();
        } catch (err) {
            console.error(err);
            alert("Upload failed: " + err.message);
        } finally {
            btn.prop('disabled', false).html(originalText);
        }
    }, 'image/png');
});

$('#profile-form').on('submit', async (e) => {
    e.preventDefault();
    const name = $('#profile-name').val();
    const nPass = $('#profile-new-pass').val();
    const cPass = $('#profile-confirm-pass').val();
    const btn = $('#profile-form button');
    btn.prop('disabled', true).text('COMMITTING UPDATES...');

    try {
        if (nPass && nPass !== cPass) throw new Error("Passwords do not match.");

        // Update Profile Table
        const { error: pErr } = await client.from('profiles').update({ full_name: name }).eq('uid', currentUser.id);
        if (pErr) throw pErr;

        // Update Auth User
        if (nPass) {
            const { error: aErr } = await client.auth.updateUser({ password: nPass });
            if (aErr) throw aErr;
        }

        userProfile.name = name;
        initDashboard(); // Refresh UI headers
        showToast("Profile updated successfully.");
        $('#profile-new-pass, #profile-confirm-pass').val('');
    } catch (err) { alert(err.message); } finally { btn.prop('disabled', false).text('Save Changes'); }
});



$('#create-task-form').on('submit', async (e) => {
    e.preventDefault();
    const btn = $('#task-submit-btn');
    const isEditing = !!editingTaskId;
    btn.prop('disabled', true).text('PROCESSING...');

    const dateVal = $('#new-task-date').val();
    let safeDeadline = null;
    if (dateVal) {
        // dateVal is "YYYY-MM-DDTHH:MM" (Local)
        // new Date(dateVal) creates a Date object representing that local time
        // toISOString() converts it to UTC, which is what we want for Supabase
        const d = new Date(dateVal);
        if (!isNaN(d.getTime())) safeDeadline = d.toISOString();
    }

    const taskData = {
        title: $('#new-task-title').val(),
        description: $('#new-task-desc').val(),
        hints: $('#new-task-hints').val(),
        deadline: safeDeadline
    };

    const refFile = document.getElementById('new-task-ref').files[0];

    const executeSave = async (data) => {
        try {
            console.log("Saving Task:", isEditing ? "UPDATE" : "CREATE", data);
            if (isEditing) {
                const { data: updatedData, error } = await client.from('tasks')
                    .update(data)
                    .eq('id', editingTaskId)
                    .select();

                if (error) throw error;

                // Strict Verification

                if (!updatedData || updatedData.length === 0) {
                    throw new Error("Update failed! No rows modified. Check Admin permissions.");
                }

                const savedDate = new Date(data.deadline);
                showToast(`Saved! Local: ${savedDate.toLocaleTimeString()} (Server: ${savedDate.getUTCHours()}:${savedDate.getUTCMinutes() < 10 ? '0' : ''}${savedDate.getUTCMinutes()})`);

                if (currentTask && currentTask.id === editingTaskId) {
                    currentTask = { ...currentTask, ...data };
                }
            } else {
                const { error } = await client.from('tasks').insert([data]);
                if (error) throw error;
                showToast("New task created.");
            }
            bootstrap.Modal.getOrCreateInstance(document.getElementById('createTaskModal')).hide();
            fetchData(); // Refresh list
            editingTaskId = null; // Clear edit mode
        } catch (err) {
            console.error("Save Error:", err);
            alert("System Error: " + err.message);
        } finally {
            btn.prop('disabled', false).text(isEditing ? 'Update Task' : 'Create Task');
        }
    };

    if (refFile) {
        try {
            const CLOUD_NAME = "dwowte8ny";
            const UPLO_PRESET = "navttc-lms";
            const formData = new FormData();
            formData.append('file', refFile);
            formData.append('upload_preset', UPLO_PRESET);

            const response = await fetch(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/auto/upload`, {
                method: 'POST',
                body: formData
            });

            const uploadData = await response.json();
            if (uploadData.error) throw new Error(uploadData.error.message);

            // WORKAROUND: If editing, try to replace existing reference link if it exists in description
            // otherwise append.
            const refHtml = `<br><strong>Reference Asset:</strong> <a href="${uploadData.secure_url}" target="_blank" class="text-indigo-500 hover:underline">View Attachment</a>`;

            if (taskData.description.includes('Reference Asset:</strong>')) {
                // Regex to replace the existing link block?
                // Simple approach: Split and keep top part, add new link
                // This assumes the link is at the end.
                const splitMarker = '<br><strong>Reference Asset:</strong>';
                const parts = taskData.description.split(splitMarker);
                taskData.description = parts[0] + refHtml;
            } else {
                taskData.description = (taskData.description || '') + "\n\n" + refHtml;
            }

            await executeSave(taskData);
        } catch (err) {
            alert("Reference File Error: " + err.message);
            btn.prop('disabled', false).text(isEditing ? 'Update Task' : 'Create Task');
        }
    } else {
        await executeSave(taskData);
    }
});

// AJAX Admin Actions
window.approveUser = async (uid) => {
    const { data: { session } } = await client.auth.getSession();
    $.ajax({
        url: `${SUPABASE_URL}/rest/v1/profiles?uid=eq.${uid}`,
        type: 'PATCH',
        headers: { 'apikey': SUPABASE_KEY, 'Authorization': `Bearer ${session.access_token}`, 'Content-Type': 'application/json' },
        data: JSON.stringify({ status: 'approved' }),
        success: () => fetchUsers()
    });
};

window.deleteUser = async (uid) => {
    if (!confirm("Are you sure you want to PERMANENTLY delete this student?")) return;
    if (!client) { showToast("Offline: Cannot delete."); return; }

    try {
        // 1. Attempt RPC call to delete Auth User + Profile
        // (Requires 'delete_user_via_admin' function in Supabase)
        const { error: rpcError } = await client.rpc('delete_user_via_admin', { target_uid: uid });

        if (!rpcError) {
            showToast("User and Login permanently deleted.");
        } else {
            // 2. Fallback: Delete Profile Only (Client Side)
            console.warn("RPC missing, performing soft delete:", rpcError.message);

            const { error: dbError } = await client.from('profiles').delete().eq('uid', uid);
            if (dbError) throw dbError;

            if (rpcError.code === 'PGRST202' || rpcError.message.includes('function not found')) {
                alert("Profile deleted from Dashboard.\n\nIMPORTANT: To allow this email to register again, you MUST run the 'delete_user_script.sql' in your Supabase SQL Editor.");
            } else {
                showToast("Student profile deleted.");
            }
        }
        fetchUsers();
    } catch (err) {
        console.error("Delete failed:", err);
        showToast("Error deleting user: " + err.message);
    }
};

window.approveAllUsers = async () => {
    if (!client) { showToast("Offline: Cannot approve users."); return; }
    const { data: { session } } = await client.auth.getSession();
    // Check if there are any pending users (using cache from fetchUsers)
    const pendingCount = (window.allUsersCache || []).filter(u => u.status === 'pending').length;

    if (pendingCount === 0) {
        showToast("No pending students to approve.");
        return;
    }

    if (!confirm(`Are you sure you want to approve all ${pendingCount} pending students?`)) return;

    const toastId = 'approve-toast-' + Date.now();
    const toast = $(`<div id="${toastId}" class="fixed bottom-10 right-10 bg-indigo-900 text-white px-8 py-4 rounded-2xl shadow-2xl z-[5000] font-black uppercase text-[10px] tracking-widest animate-in slide-in-from-bottom-5 border border-white/10 flex items-center gap-3"><i data-lucide="loader-2" class="w-4 h-4 animate-spin"></i> Approving ${pendingCount} students...</div>`);
    $('body').append(toast);
    window.safeCreateIcons();

    try {
        // Update all pending users to approved
        const { error } = await client.from('profiles')
            .update({ status: 'approved' })
            .eq('status', 'pending');

        if (error) throw error;

        $(`#${toastId}`).remove();
        showToast(`Success! ${pendingCount} students approved.`);
        confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
        fetchUsers();
    } catch (err) {
        console.error(err);
        $(`#${toastId}`).remove();
        showToast("Error: " + err.message);
    }
};

window.submitGrade = async (sid) => {
    const g = $(`#grade-${sid}`).val();
    const f = $(`#feedback-${sid}`).val();

    if (!g) {
        showToast("Please enter a grade (0-100).");
        return;
    }

    if (!client) {
        showToast("Offline: Cannot submit grade.");
        return;
    }

    try {
        // 1. Get the submission details first to identify Student & Task
        const { data: currentSub, error: fetchError } = await client
            .from('submissions')
            .select('student_id, task_id')
            .eq('id', sid)
            .single();

        if (fetchError) throw new Error("Could not find submission details.");

        // 2. Submit the Grade for THIS submission
        const { error: updateError } = await client
            .from('submissions')
            .update({
                grade: parseInt(g),
                feedback: f,
                status: 'graded'
            })
            .eq('id', sid);

        if (updateError) throw updateError;

        // 3. NUCLEAR CLEANUP: Delete ALL other submissions for this task & student
        const { error: deleteError } = await client
            .from('submissions')
            .delete()
            .eq('student_id', currentSub.student_id)
            .eq('task_id', currentSub.task_id)
            .neq('id', sid);

        if (deleteError) console.warn("Cleanup warning:", deleteError);

        // 4. INSTANT LOCAL UPDATE
        // We manually prune the pending/duplicate items from the local cache immediately.
        if (window.allSubmissions) {
            window.allSubmissions = window.allSubmissions.filter(s => {
                // Keep if ID matches current (graded)
                if (String(s.id) === String(sid)) {
                    s.status = 'graded';
                    s.grade = parseInt(g);
                    s.feedback = f;
                    return true;
                }
                // Discard if same user+task but different ID
                if (s.student_id === currentSub.student_id && String(s.task_id) === String(currentSub.task_id)) {
                    return false;
                }
                // Keep everything else
                return true;
            });
            // Refresh view immediately with clean data
            window.renderGrading(window.allSubmissions);
        }

        showToast("Grade saved. Previous versions discarded.");
        fetchData(); // Background sync

    } catch (err) {
        console.error("Grading Error:", err);
        showToast("Error: " + err.message);
    }
};



function initChart() {
    const canvas = document.getElementById('performanceChart');
    if (!canvas) return;

    // Fix: Destroy existing chart instance to prevent "Canvas already in use" error
    if (performanceChart) {
        performanceChart.destroy();
        performanceChart = null;
    }

    const ctx = canvas.getContext('2d');
    performanceChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Completed', 'Pending', 'To Do'],
            datasets: [{
                data: [0, 0, 1],
                backgroundColor: ['#10b981', '#f59e0b', '#e2e8f0'],
                borderWeight: 0,
                hoverOffset: 4
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            cutout: '80%',
            plugins: { legend: { display: false } },
            animation: { animateScale: true, animateRotate: true }
        }
    });
}

function updateChart() {
    if (!currentUser) return;

    // Ensure chart exists
    if (!performanceChart) initChart();

    if (userProfile.role === 'admin') {
        // --- ADMIN VIEW ---
        // Visualize: Global Graded vs Global Pending (DEDUPLICATED)
        const uniqueSubsMap = new Map();
        (window.allSubmissions || []).forEach(s => {
            const key = `${s.student_id}_${s.task_id}`;
            const existing = uniqueSubsMap.get(key);
            // Keep the NEWER one
            if (!existing || new Date(s.submitted_at) > new Date(existing.submitted_at)) {
                uniqueSubsMap.set(key, s);
            }
        });

        const uniqueSubs = Array.from(uniqueSubsMap.values());
        const graded = uniqueSubs.filter(s => s.status === 'graded').length;
        const pending = uniqueSubs.filter(s => s.status === 'submitted').length;

        if (performanceChart) {
            performanceChart.data.labels = ['Graded', 'Pending Review', ''];
            performanceChart.data.datasets[0].data = [graded, pending, 0];
            // Green for Graded, Amber for Pending, Gray hidden
            performanceChart.data.datasets[0].backgroundColor = ['#10b981', '#f59e0b', 'transparent'];
            performanceChart.update();
        }
    } else {
        // --- STUDENT VIEW ---
        const totalTasks = window.allTasks.length || 1;
        const mySubs = window.allSubmissions.filter(s => s.student_id === currentUser.id);

        const completed = mySubs.filter(s => s.status === 'graded').length;
        const submitted = mySubs.filter(s => s.status === 'submitted').length;
        const remaining = window.allTasks.filter(t => !mySubs.some(s => s.task_id === t.id) && (!t.deadline || new Date().getTime() <= new Date(t.deadline).getTime())).length;

        if (performanceChart) {
            performanceChart.data.labels = ['Completed', 'Pending Review', 'To Do'];
            performanceChart.data.datasets[0].data = [completed, submitted, remaining > 0 ? remaining : 0];
            performanceChart.data.datasets[0].backgroundColor = ['#10b981', '#f59e0b', '#e2e8f0'];
            performanceChart.update();
        }
    }
}




window.downloadAllReports = () => { showToast("Initiating batch export..."); /* Implement batch if needed */ };
$('#user-search').on('input', () => { renderSkeleton('user-table-body', 8, 'list'); fetchUsers(); });

// --- STUDENT PROGRESS ENCOURAGEMENT SYSTEM ---
window.checkAndShowEncouragement = async () => {
    // Only for students, not admins
    if (!currentUser || !userProfile || userProfile.role !== 'student') return;

    // Check if already shown today
    const today = new Date().toDateString();
    const lastShown = localStorage.getItem('encouragement_shown_date');
    if (lastShown === today) return; // Already shown today

    // Calculate student progress
    const submissions = (window.allSubmissions || []).filter(s => s.student_id === currentUser.id);
    const gradedSubmissions = submissions.filter(s => s.status === 'graded');
    const totalTasks = window.allTasks ? window.allTasks.length : 0;
    const completionRate = totalTasks > 0 ? (gradedSubmissions.length / totalTasks) * 100 : 0;

    // Calculate average grade
    const avgGrade = gradedSubmissions.length > 0
        ? (gradedSubmissions.reduce((sum, s) => sum + (s.grade || 0), 0) / gradedSubmissions.length)
        : 0;

    // Store progress for dashboard display
    window.studentProgress = {
        completionRate: Math.round(completionRate),
        avgGrade: Math.round(avgGrade * 10) / 10,
        submissionsCount: gradedSubmissions.length,
        totalTasks: totalTasks
    };

    // Determine encouragement level and message
    let message = '';
    let icon = '🎉';
    let level = 'good';

    // Determine encouragement based on metrics
    if (avgGrade >= 85 && completionRate >= 80) {
        message = `🌟 Excellent Progress! You're crushing it! Average Grade: ${avgGrade.toFixed(1)}% | Completed: ${gradedSubmissions.length}/${totalTasks}`;
        level = 'excellent';
    } else if (avgGrade >= 75 && completionRate >= 60) {
        message = `🚀 Great Work! You're doing amazing! Keep it up! Average Grade: ${avgGrade.toFixed(1)}% | ${gradedSubmissions.length} tasks completed`;
        level = 'great';
    } else if (avgGrade >= 60 || completionRate >= 40) {
        message = `💪 Good Progress! You're on the right track. Keep pushing! ${Math.round(completionRate)}% tasks completed`;
        level = 'good';
    } else if (gradedSubmissions.length > 0) {
        message = `📚 Get Started! Complete more tasks to see your progress grow!`;
        level = 'start';
    } else {
        return; // No progress yet, no encouragement needed
    }

    // Mark as shown today
    localStorage.setItem('encouragement_shown_date', today);

    // Show encouragement notification
    setTimeout(() => {
        showEncouragementNotification(message, level);
    }, 1000);
};

window.showEncouragementNotification = (message, level = 'good') => {
    // Create notification element
    const notifId = 'encouragement-' + Date.now();
    const bgColor = level === 'excellent' ? 'bg-gradient-to-r from-amber-400 to-orange-400' :
        level === 'great' ? 'bg-gradient-to-r from-green-400 to-emerald-400' :
            level === 'start' ? 'bg-gradient-to-r from-blue-400 to-cyan-400' :
                'bg-gradient-to-r from-indigo-400 to-purple-400';

    const textColor = level === 'excellent' || level === 'great' ? 'text-white' : 'text-white';

    // Notification container
    let container = $('#encouragement-container');
    if (container.length === 0) {
        container = $('<div id="encouragement-container" class="fixed top-6 right-6 z-[8000] space-y-3"></div>');
        $('body').append(container);
    }

    const $notif = $(`
                <div id="${notifId}" class="${bgColor} ${textColor} rounded-lg shadow-xl px-6 py-4 animate-in slide-in-from-right-5 fade-in duration-300 flex items-center gap-3 max-w-md">
                    <div class="flex-1 font-semibold text-sm md:text-base">${message}</div>
                    <button onclick="$('#${notifId}').fadeOut(300, function() { $(this).remove(); })" class="text-white hover:opacity-80">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <line x1="18" y1="6" x2="6" y2="18"></line>
                            <line x1="6" y1="6" x2="18" y2="18"></line>
                        </svg>
                    </button>
                </div>
            `);

    container.append($notif);

    // Auto-remove after 6 seconds
    setTimeout(() => {
        $notif.fadeOut(300, function () { $(this).remove(); });
    }, 6000);
};

// --- ADVANCED FEATURES: LEARNING LIBRARY ---
window.learningResources = []; // Removed dummy data

window.openCreateResourceModal = () => {
    new bootstrap.Modal(document.getElementById('createResourceModal')).show();
    lucide.createIcons();
};

window.fetchResources = async () => {
    try {
        // Ensure table exists or handle error gracefully
        const { data, error } = await client.from('resources').select('*').order('created_at', { ascending: false });

        if (error) {
            console.error("Resource fetch error:", error);
            showToast("Error loading resources: " + error.message); // Optional: for debugging
            window.learningResources = [];
        } else {
            window.learningResources = data || [];
            // showToast(`Loaded ${window.learningResources.length} resources`); // Debug
        }

        if (window.renderResources) renderResources();
    } catch (err) {
        console.error("Resource fetch fatal error:", err);
        showToast("Fatal Error loading resources: " + err.message);
        window.learningResources = [];
        if (window.renderResources) renderResources();
    }
};

$('#resource-upload-form').on('submit', async (e) => {
    e.preventDefault();
    const btn = $('#upload-res-btn');
    btn.prop('disabled', true).text('UPLOADING...');

    const title = $('#res-title').val();
    const subtitle = $('#res-desc').val();
    const category = $('#res-category').val();
    const file = document.getElementById('res-file').files[0];
    const link = $('#res-link').val();

    try {
        let resourceUrl = link;

        // Upload to Cloudinary if file present
        if (file) {
            const CLOUD_NAME = "dwowte8ny";
            const UPLO_PRESET = "navttc-lms";
            const formData = new FormData();
            formData.append('file', file);
            formData.append('upload_preset', UPLO_PRESET);

            const res = await fetch(`https://api.cloudinary.com/v1_1/${CLOUD_NAME}/auto/upload`, {
                method: 'POST',
                body: formData
            });
            const data = await res.json();
            if (data.error) throw new Error(data.error.message);
            resourceUrl = data.secure_url;
        }

        if (!resourceUrl) throw new Error("Please provide a file or a link.");

        const iconMap = { 'video': 'video', 'doc': 'file-text', 'link': 'link' };
        const colorMap = { 'video': 'rose', 'doc': 'indigo', 'link': 'emerald' };

        let finalIcon = iconMap[category] || 'file';
        let finalColor = colorMap[category] || 'slate';

        // Auto-detect PDF
        if ((file && file.name.toLowerCase().endsWith('.pdf')) || (resourceUrl && resourceUrl.toLowerCase().endsWith('.pdf'))) {
            finalIcon = 'file-text';
            finalColor = 'rose';
        }

        const { error } = await client.from('resources').insert([{
            title,
            subtitle,
            category,
            link: resourceUrl,
            icon: finalIcon,
            color: finalColor,
            created_by: currentUser.id
        }]);

        if (error) throw error;

        showToast("Resource uploaded successfully!");
        bootstrap.Modal.getInstance(document.getElementById('createResourceModal')).hide();
        $('#resource-upload-form')[0].reset();
        fetchResources();

    } catch (err) {
        alert("Upload Error: " + err.message);
    } finally {
        btn.prop('disabled', false).text('Upload Resource');
    }
});

window.renderResources = (filter = 'all') => {
    const grid = $('#resource-grid').empty();
    const search = $('#resource-search').val().toLowerCase();

    const filtered = window.learningResources.filter(r => {
        const matchesCat = filter === 'all' || r.category === filter;
        const matchesSearch = r.title.toLowerCase().includes(search) || (r.subtitle && r.subtitle.toLowerCase().includes(search));
        return matchesCat && matchesSearch;
    });

    if (!filtered.length) {
        grid.html(`
                        <div class="col-span-full py-16 text-center animate-in fade-in zoom-in duration-500">
                            <div class="w-20 h-20 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center mx-auto mb-6">
                                <i data-lucide="rocket" class="w-10 h-10 text-slate-400"></i>
                            </div>
                            <h3 class="text-xl font-black uppercase tracking-tighter text-slate-900 dark:text-slate-200 mb-2">Coming Soon</h3>
                            <p class="text-xs font-bold uppercase tracking-widest text-slate-400 max-w-xs mx-auto">
                                The learning library is currently being curated. Check back later for premium materials.
                            </p>
                        </div>
                    `);
        lucide.createIcons();
        return;
    }

    filtered.forEach((r, index) => {
        let iconDisplay = `<i data-lucide="${r.icon}" class="w-5 h-5"></i>`;

        // Dynamic PDF Fix for display
        if (r.link && r.link.toLowerCase().endsWith('.pdf')) {
            r.color = 'rose';
            iconDisplay = `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" class="bi bi-file-pdf" viewBox="0 0 16 16">
  <path d="M4 0a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V2a2 2 0 0 0-2-2zm0 1h8a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1"/>
  <path d="M4.603 12.087a.8.8 0 0 1-.438-.42c-.195-.388-.13-.776.08-1.102.198-.307.526-.568.897-.787a7.7 7.7 0 0 1 1.482-.645 20 20 0 0 0 1.062-2.227 7.3 7.3 0 0 1-.43-1.295c-.086-.4-.119-.796-.046-1.136.075-.354.274-.672.65-.823.192-.077.4-.12.602-.077a.7.7 0 0 1 .477.365c.088.164.12.356.127.538.007.187-.012.395-.047.614-.084.51-.27 1.134-.52 1.794a11 11 0 0 0 .98 1.686 5.8 5.8 0 0 1 1.334.05c.364.065.734.195.96.465.12.144.193.32.2.518.007.192-.047.382-.138.563a1.04 1.04 0 0 1-.354.416.86.86 0 0 1-.51.138c-.331-.014-.654-.196-.933-.417a5.7 5.7 0 0 1-.911-.95 11.6 11.6 0 0 0-1.997.406 11.3 11.3 0 0 1-1.021 1.51c-.29.35-.608.655-.926.787a.8.8 0 0 1-.58.029m1.379-1.901q-.25.115-.459.238c-.328.194-.541.383-.647.547-.094.145-.096.25-.04.361q.016.032.026.044l.035-.012c.137-.056.355-.235.635-.572a8 8 0 0 0 .45-.606m1.64-1.33a13 13 0 0 1 1.01-.193 12 12 0 0 1-.51-.858 21 21 0 0 1-.5 1.05zm2.446.45q.226.244.435.41c.24.19.407.253.498.256a.1.1 0 0 0 .07-.015.3.3 0 0 0 .094-.125.44.44 0 0 0 .059-.2.1.1 0 0 0-.026-.063c-.052-.062-.2-.152-.518-.209a4 4 0 0 0-.612-.053zM8.078 5.8a7 7 0 0 0 .2-.828q.046-.282.038-.465a.6.6 0 0 0-.032-.198.5.5 0 0 0-.145.04c-.087.035-.158.106-.196.283-.04.192-.03.469.046.822q.036.167.09.346z"/>
</svg>`;
        }

        grid.append(`
                    <div class="v-card p-5 group hover:scale-[1.02] transition-transform cursor-pointer" onclick="previewFile('${r.link}', '${r.title.replace(/'/g, "\\'")}', 'Learning Material', '${r.link.split('.').pop()}', window.learningResources, ${index})">
                        <div class="flex justify-between items-start mb-4">
                            <div class="w-10 h-10 bg-${r.color}-50 dark:bg-${r.color}-900/20 text-${r.color}-600 dark:text-${r.color}-400 rounded-xl flex items-center justify-center shadow-sm">
                                ${iconDisplay}
                            </div>
                            <span class="text-[9px] font-black uppercase tracking-widest px-2 py-1 rounded bg-slate-100 dark:bg-slate-800 text-slate-500">${r.category}</span>
                        </div>
                        <h4 class="font-extrabold text-slate-900 dark:text-slate-200 text-sm mb-1 line-clamp-1">${r.title}</h4>
                        <p class="text-[10px] font-bold text-slate-400 uppercase tracking-wide mb-4">${r.subtitle || ''}</p>
                        
                        <button class="w-full flex items-center justify-center gap-2 py-2 rounded-lg bg-slate-50 dark:bg-slate-800 text-[10px] font-black uppercase tracking-wider text-slate-600 dark:text-slate-300 group-hover:bg-indigo-600 group-hover:text-white transition-colors">
                            Access Material <i data-lucide="arrow-right" class="w-3 h-3"></i>
                        </button>
                    </div>
                `);
    });
    lucide.createIcons();
};



window.currentResourceFilter = 'all';

window.filterResources = (cat) => {
    // Radio UI handles visual state automatically
    window.currentResourceFilter = cat;
    renderResources(cat);
};

$('#resource-search').on('input', () => renderResources(window.currentResourceFilter));

// --- NOTIFICATION SYSTEM ---
// --- NOTIFICATION SYSTEM (FIXED) ---
window.toggleNotifications = (e) => {
    if (e) e.stopPropagation(); // Prevent immediate close
    const dropdown = $('#notification-dropdown');

    if (dropdown.hasClass('hidden')) {
        dropdown.removeClass('hidden');
        renderNotifications();

        // One-time click handler to close when clicking outside
        $(document).off('click.notif').on('click.notif', function (ev) {
            if (!$(ev.target).closest('#admin-notif-btn, #notification-dropdown').length) {
                dropdown.addClass('hidden');
                $(document).off('click.notif');
            }
        });
    } else {
        dropdown.addClass('hidden');
        $(document).off('click.notif');
    }
};

window.renderNotifications = () => {
    const list = $('#notification-list');
    if (!list.length) return;
    list.empty();

    // CHECK CLEARED STATE
    if (localStorage.getItem('notifications_cleared') === 'true') {
        list.html(`
                    <div class="h-32 flex flex-col items-center justify-center text-slate-400">
                         <div class="w-8 h-8 rounded-full bg-slate-50 dark:bg-slate-800 flex items-center justify-center mb-2">
                            <i data-lucide="bell-off" class="w-4 h-4 opacity-50"></i>
                         </div>
                         <p class="text-[9px] font-black uppercase tracking-widest opacity-50">No new notifications</p>
                    </div>
                `);
        if (window.lucide) lucide.createIcons();
        return;
    }

    // Filter pending submissions
    const uniquePendingMap = new Map();
    const submissions = window.allSubmissions || [];

    submissions.forEach(s => {
        if (!s || !s.student_id || !s.task_id) return;
        // Use concatenation to avoid potential template literal parsing issues with weird characters
        const key = String(s.student_id) + '_' + String(s.task_id);
        const existing = uniquePendingMap.get(key);
        // Keep the NEWER one
        if (!existing || new Date(s.submitted_at) > new Date(existing.submitted_at)) {
            uniquePendingMap.set(key, s);
        }
    });

    // Only keeping those whose LATEST status is 'submitted' (not graded)
    const pending = Array.from(uniquePendingMap.values())
        .filter(s => s.status === 'submitted');

    // Sort by date desc
    pending.sort((a, b) => new Date(b.submitted_at) - new Date(a.submitted_at));

    if (!pending.length) {
        list.html(`
                    <div class="h-32 flex flex-col items-center justify-center text-slate-400">
                         <div class="w-8 h-8 rounded-full bg-slate-50 dark:bg-slate-800 flex items-center justify-center mb-2">
                            <i data-lucide="bell-off" class="w-4 h-4 opacity-50"></i>
                         </div>
                         <p class="text-[9px] font-black uppercase tracking-widest opacity-50">No new notifications</p>
                    </div>
                `);
        if (window.lucide) lucide.createIcons();
        return;
    }

    const escapeHtml = (unsafe) => {
        return String(unsafe || '')
            .replace(/&/g, "&amp;")
            .replace(/</g, "&lt;")
            .replace(/>/g, "&gt;")
            .replace(new RegExp('"', 'g'), "&quot;")
            .replace(new RegExp("'", 'g'), "&#039;");
    };

    pending.forEach(s => {
        const timeAgo = (() => {
            const diff = new Date() - new Date(s.submitted_at);
            const mins = Math.floor(diff / 60000);
            if (mins < 60) return mins + 'm ago';
            const hours = Math.floor(mins / 60);
            if (hours < 24) return hours + 'h ago';
            return Math.floor(hours / 24) + 'd ago';
        })();

        const safeName = escapeHtml(s.student_name || 'Student');
        const safeTitle = escapeHtml(s.task_title || 'Task');

        const notifHtml = `
                    <div onclick="switchTab('grading'); window.toggleNotifications()" class="p-3 rounded-xl hover:bg-slate-50 dark:hover:bg-slate-800/50 cursor-pointer group transition-colors border border-transparent hover:border-slate-100 dark:hover:border-slate-800">
                        <div class="flex items-start gap-3">
                            <div class="w-8 h-8 rounded-full bg-indigo-50 dark:bg-indigo-900/30 text-indigo-500 flex items-center justify-center shrink-0 border border-indigo-100 dark:border-indigo-900/50">
                                <i data-lucide="file-text" class="w-4 h-4"></i>
                            </div>
                            <div class="min-w-0 flex-1">
                                <h5 class="text-[10px] font-black uppercase text-slate-900 dark:text-slate-200 leading-none mb-1 truncate">${safeName}</h5>
                                <p class="text-[9px] text-slate-500 font-medium leading-tight line-clamp-2">Submitted: <span class="text-indigo-500">${safeTitle}</span></p>
                                <p class="text-[8px] text-slate-400 font-bold uppercase tracking-widest mt-1.5">${timeAgo}</p>
                            </div>
                            <div class="w-1.5 h-1.5 rounded-full bg-indigo-500 mt-1.5"></div>
                        </div>
                    </div>
                `;
        list.append(notifHtml);
    });
    if (window.lucide) lucide.createIcons();
};

window.markAllRead = () => {
    // User requested: "jitne mb hn woh empty hojayen"
    // Visual clear only since we don't have a read_status column yet
    $('#notification-list').empty().html('<div class="text-center py-4 text-[10px] text-slate-400 font-bold uppercase tracking-widest italic">All caught up!</div>');
    $('#notif-badge').addClass('hidden').removeClass('flex').text('');

    // Persist the cleared state so it doesn't come back on refresh
    localStorage.setItem('notifications_cleared', 'true');

    // Update Watermark to suppress current items
    const currentCount = window.lastPendingCountVal || 0;
    localStorage.setItem('notification_watermark', currentCount);

    // Close dropdown after short delay
    setTimeout(() => {
        $('#notification-dropdown').addClass('hidden');
    }, 500);

    showToast("Notifications cleared.");
};

// --- ARCADE GAME ENGINE ---
window.activeGameTimer = null;

window.startArcadeGame = (gameId) => {
    window.scrollTo({ top: 0, behavior: 'smooth' });
    if (window.activeGameTimer) clearInterval(window.activeGameTimer);

    $('#arcade-menu').addClass('hidden');
    $('#game-stage').removeClass('hidden');
    $('#back-to-menu-btn').removeClass('hidden');
    const container = $('#game-container').empty();

    if (gameId === 'html_master') {
        runHtmlMaster(container);
    } else if (gameId === 'css_speed') {
        runCssSpeed(container);
    } else if (gameId === 'drag_master') {
        runDragMaster(container);
    } else if (gameId === 'js_logic') {
        runJsLogic(container);
    } else if (gameId === 'syntax_balloons') {
        runSyntaxBalloons(container);
    }
};

window.showGameFeedback = (text, success, subtext = '') => {
    const theme = success ?
        { bg: 'bg-emerald-500', icon: 'check-circle', text: 'text-emerald-500', bgLight: 'bg-emerald-50 dark:bg-emerald-500/10' } :
        { bg: 'bg-rose-500', icon: 'x-circle', text: 'text-rose-500', bgLight: 'bg-rose-50 dark:bg-rose-500/10' };

    let container = $('#game-feedback-side');
    if (container.length === 0) {
        $('#game-container').append('<div id="game-feedback-side" class="absolute top-4 right-4 z-[100] pointer-events-none flex flex-col gap-3"></div>');
        container = $('#game-feedback-side');
    }

    // Clear previous feedback to keep it clean and professional
    container.empty();

    const id = 'feedback-' + Date.now();
    const $feedback = $(`
                <div id="${id}" class="v-card overflow-hidden w-72 animate-in slide-in-from-right duration-500 shadow-2xl bg-white dark:bg-[#1e293b] border-l-4 ${theme.bg}">
                    <div class="p-4 flex items-center gap-4">
                        <div class="w-10 h-10 rounded-full border-2 ${success ? 'border-emerald-500' : 'border-rose-500'} ${theme.bgLight} ${theme.text} flex items-center justify-center shrink-0 shadow-sm transform transition-transform duration-300">
                            <i data-lucide="${theme.icon}" class="w-6 h-6"></i>
                        </div>
                        <div class="flex-1 min-w-0">
                            <div class="font-black uppercase tracking-tighter text-sm ${success ? 'text-emerald-600' : 'text-rose-600'}">${text}</div>
                            ${subtext ? `
                                <div class="mt-1.5 pt-1.5 border-t border-slate-100 dark:border-slate-800">
                                    <div class="text-[8px] font-black text-slate-400 uppercase tracking-[0.1em] mb-0.5">Correct Answer:</div>
                                    <div class="text-[11px] font-mono font-bold text-indigo-500 break-all">${subtext.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</div>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                </div>
            `);

    container.append($feedback);
    lucide.createIcons();

    setTimeout(() => {
        $feedback.addClass('animate-out fade-out slide-out-to-right duration-500');
        setTimeout(() => $feedback.remove(), 500);
    }, 2000);
};

window.clearGameFeedback = () => {
    // No longer needed as they self-destruct, but kept for compatibility
};

window.exitArcadeGame = () => {
    if (window.activeGameTimer) clearInterval(window.activeGameTimer);
    $('#game-stage').addClass('hidden');
    $('#arcade-menu').removeClass('hidden');
    $('#back-to-menu-btn').addClass('hidden');
};



// --- PROFESSIONAL ARCADE GAME ENGINE ---

// Mock AJAX Save Function
async function saveGameScore(gameId, score, maxScore) {
    console.log(`[AJAX] Saving score for ${gameId}: ${score}/${maxScore}`);
    try {
        // Simulate AJAX delay
        await new Promise(r => setTimeout(r, 600));

        // Actual Supabase Insert (Commented to prevent DB errors if table missing)
        /*
        await client.from('game_scores').insert({
            user_id: currentUser.id,
            game: gameId,
            score: score,
            max_score: maxScore,
            played_at: new Date()
        });
        */
        showToast("Score Saved via AJAX!");
    } catch (e) {
        console.error("Score save failed", e);
    }
}

// ADAPTIVE LEVEL MANAGER (Global)
function getLevel(gameType) {
    const map = { 'html': 'html_master_level', 'css': 'css_master_level', 'drag': 'drag_master_level', 'js': 'js_logic_level' };
    return localStorage.getItem(map[gameType]) || 'easy';
}

async function saveLevel(gameType, score, total) {
    const percentage = (score / total) * 100;
    const current = getLevel(gameType);


    if (percentage >= 80) {
        let newLevel = current;
        if (current === 'easy') newLevel = 'moderate';
        else if (current === 'moderate') newLevel = 'hard';

        if (newLevel !== current) {
            const map = { 'html': 'html_master_level', 'css': 'css_master_level', 'drag': 'drag_master_level', 'js': 'js_logic_level' };
            localStorage.setItem(map[gameType], newLevel);
        }

        // ALWAYS DB Update to ensure record exists
        try {
            const payload = { user_id: currentUser.id };
            // We use newLevel (if upgraded) or current (if not)
            // But we must be careful not to overwrite other fields with null 
            // Upsert with only ONE field might wipe others if we don't select first?
            // Supabase upsert merges if we don't specify otherwise, but let's be safe.
            // Actually upsert on a specific ID updates columns provided.

            if (gameType === 'html') payload.html_level = newLevel;
            if (gameType === 'css') payload.css_level = newLevel;
            if (gameType === 'drag') payload.drag_level = newLevel;
            if (gameType === 'js') payload.js_level = newLevel;

            await client.from('user_arcade_progress').upsert(payload, { onConflict: 'user_id' });
        } catch (e) { console.error(e); }

        return newLevel !== current;
    } else {
        // Even if they failed, ensure the record exists as "Easy" (or current) 
        // so Admin sees they are active.
        try {
            const payload = { user_id: currentUser.id };
            if (gameType === 'html') payload.html_level = current;
            if (gameType === 'css') payload.css_level = current;
            if (gameType === 'drag') payload.drag_level = current;
            if (gameType === 'js') payload.js_level = current; // Fix missing JS map

            await client.from('user_arcade_progress').upsert(payload, { onConflict: 'user_id' });
        } catch (e) { console.error(e); }
    }
    return false;
}

async function syncArcadeProgress() {
    try {
        const { data } = await client.from('user_arcade_progress').select('*').eq('user_id', currentUser.id).maybeSingle();
        if (data) {
            if (data.html_level) localStorage.setItem('html_master_level', data.html_level);
            if (data.css_level) localStorage.setItem('css_master_level', data.css_level);
            if (data.drag_level) localStorage.setItem('drag_master_level', data.drag_level);
            if (data.js_level) localStorage.setItem('js_logic_level', data.js_level);
            console.log("[Arcade] Synced Progress: ", data);
        }
    } catch (e) {
        console.warn("[Arcade] Progress sync failed.", e);
    }
}

// ADAPTIVE DIFFICULTY CONTENT BANKS
const htmlQB = {
    easy: [
        { q: "Which tag makes text <b>bold</b>?", a: ["<b>", "<bold>", "<heavy>", "<em>"], r: ["<b>"] },
        { q: "What is the correct tag for a hyperlink?", a: ["<link>", "<a>", "<href>", "<url>"], r: ["<a>"] },
        { q: "Which is the largest heading tag?", a: ["<h6>", "<head>", "<h1>", "<header>"], r: ["<h1>"] },
        { q: "How do you insert an image?", a: ["<img>", "<pic>", "<src>", "<image>"], r: ["<img>"] },
        { q: "Which tag defines an unordered list?", a: ["<ul>", "<ol>", "<list>", "<li>"], r: ["<ul>"] },
        { q: "Line break tag?", a: ["<br>", "<break>", "<lb>", "<newline>"], r: ["<br>"] },
        { q: "Paragraph tag?", a: ["<p>", "<para>", "<text>", "<pg>"], r: ["<p>"] },
        { q: "Smallest heading tag?", a: ["<h1>", "<h6>", "<small>", "<head>"], r: ["<h6>"] },
        { q: "Horizontal rule tag?", a: ["<hr>", "<line>", "<br>", "<tr>"], r: ["<hr>"] },
        { q: "Which tag defines the document title?", a: ["<title>", "<meta>", "<name>", "<head>"], r: ["<title>"] },
        { q: "Correct tag for ordered list?", a: ["<ol>", "<ul>", "<list>", "<dl>"], r: ["<ol>"] },
        { q: "Tag to define a container?", a: ["<div>", "<span>", "<container>", "<block>"], r: ["<div>"] },
        { q: "Which tag is used for input fields?", a: ["<input>", "<text>", "<field>", "<enter>"], r: ["<input>"] },
        { q: "Tag for main content area?", a: ["<main>", "<body>", "<content>", "<root>"], r: ["<main>"] }
    ],
    moderate: [
        { q: "Choose the correct HTML5 element for the main content?", a: ["<article>", "<main>", "<content>", "<body>"], r: ["<main>"] },
        { q: "How do you define an internal style sheet?", a: ["<style>", "<css>", "", "<design>"], r: ["<style>"] },
        { q: "Which attribute is used to specify a unique ID?", a: ["class", "id", "name", "tag"], r: ["id"] },
        { q: "Correct input type for email?", a: ["type='text'", "type='email'", "type='mail'", "format='email'"], r: ["type='email'"] },
        { q: "Which tag is used to define a table row?", a: ["<th>", "<td>", "<tr>", "<table>"], r: ["<tr>"] },
        { q: "Tag for navigation links?", a: ["<nav>", "<links>", "<menu>", "<ul>"], r: ["<nav>"] },
        { q: "Tag for a dropdown list?", a: ["<select>", "<list>", "<dropdown>", "<option>"], r: ["<select>"] },
        { q: "Attribute for external CSS URL?", a: ["href", "src", "link", "rel"], r: ["href"] },
        { q: "Alternative text for image?", a: ["title", "alt", "desc", "src"], r: ["alt"] },
        { q: "Which tag defines a table header?", a: ["<thead>", "<th>", "<head>", "<header>"], r: ["<th>"] },
        { q: "HTML5 tag for sidebar content?", a: ["<aside>", "<sidebar>", "<section>", "<nav>"], r: ["<aside>"] },
        { q: "Attribute to open link in new tab?", a: ["target='_blank'", "new='tab'", "target='new'", "open='window'"], r: ["target='_blank'"] },
        { q: "Which tag defines a form?", a: ["<form>", "<input>", "<submit>", "<field>"], r: ["<form>"] },
        { q: "Valid attribute for  src?", a: ["src", "href", "link", "url"], r: ["src"] }
    ],
    hard: [
        { q: "Which input type defines a slider control?", a: ["slider", "range", "controls", "search"], r: ["range"] },
        { q: "Which HTML5 tag is used to specify a footer?", a: ["<footer>", "<bottom>", "<section>", "<end>"], r: ["<footer>"] },
        { q: "What is the correct tag for playing video files?", a: ["<movie>", "<media>", "<video>", "<play>"], r: ["<video>"] },
        { q: "Which attribute specifies that an input field must be filled out?", a: ["validate", "required", "placeholder", "mandatory"], r: ["required"] },
        { q: "Which element describes the structure of a document?", a: ["<meta>", "<head>", "<body>", "<html>"], r: ["<html>"] },
        { q: "Which element is used to draw graphics?", a: ["<svg>", "<canvas>", "<paint>", "<graphic>"], r: ["<canvas>"] },
        { q: "Pattern attribute is used for?", a: ["Validation", "Styling", "Images", "Links"], r: ["Validation"] },
        { q: "Which tag defines an embedded object?", a: ["<embed>", "<object>", "<iframe>", "<all>"], r: ["<embed>", "<object>"] },
        { q: "Tag for result of calculation?", a: ["<output>", "<result>", "<calc>", "<sum>"], r: ["<output>"] },
        { q: "Which meta tag is used for viewport?", a: ["viewport", "responsive", "scale", "dim"], r: ["viewport"] },
        { q: "Tag for independent self-contained content?", a: ["<article>", "<section>", "<div class='post'>", "<aside>"], r: ["<article>"] },
        { q: "Which input attribute specifies a regex?", a: ["pattern", "regex", "validate", "match"], r: ["pattern"] },
        { q: "Tag for grouping options in a select?", a: ["<optgroup>", "<group>", "<category>", "<list>"], r: ["<optgroup>"] },
        { q: "Which tag defines a caption for a <figure>?", a: ["<figcaption>", "<caption>", "<label>", "<title>"], r: ["<figcaption>"] }
    ]
};

const cssQB = {
    easy: [
        { task: "Make text red", correct: "color: red;", wrong: ["background: red;", "font-size: red;", "text-color: red;", "font-style: red"], desc: "Change text color" },
        { task: "Center text", correct: "text-align: center;", wrong: ["align: center;", "font-align: center;", "center: true;", "align-self: center;"], desc: "Center alignment" },
        { task: "Bold font", correct: "font-weight: bold;", wrong: ["font-style: bold;", "text-decoration: bold;", "font: bold;", "weight: bold;"], desc: "Thicker text" },
        { task: "Italic text", correct: "font-style: italic;", wrong: ["font-weight: italic;", "text-style: italic;", "italic: true;", "style: italic"], desc: "Slanted text" },
        { task: "Underline text", correct: "text-decoration: underline;", wrong: ["font-style: underline;", "text-style: underline;", "decoration: underline;", "line: bottom;"], desc: "Line below text" },
        { task: "Blue Background", correct: "background-color: blue;", wrong: ["color: blue;", "bg: blue;", "back: blue;", "area: blue;"], desc: "Change background" },
        { task: "Set font size", correct: "font-size: 16px;", wrong: ["text-size: 16px;", "size: 16px;", "font: 16px;", "height: 16px;"], desc: "Text size" },
        { task: "Add border", correct: "border: 1px solid;", wrong: ["outline: 1px;", "stroke: 1px;", "line: 1px;", "box: 1px;"], desc: "Box outline" },
        { task: "Upper case", correct: "text-transform: uppercase;", wrong: ["text-style: uppercase;", "transform: upper;", "font: uppercase;", "caps: true;"], desc: "All caps" },
        { task: "Remove bullet points", correct: "list-style: none;", wrong: ["list: none;", "ul: none;", "bullet: none;", "marker: none;"], desc: "No list markers" },
        { task: "Set width", correct: "width: 100px;", wrong: ["broad: 100px;", "size: 100px;", "inline: 100px;", "w: 100px;"], desc: "Element width" },
        { task: "Set height", correct: "height: 50vh;", wrong: ["tall: 50vh;", "h: 50vh;", "size: 50vh;", "vertical: 50vh;"], desc: "Element height" },
        { task: "Make input required", correct: "required", wrong: ["validate", "mandatory", "need", "check"], desc: "HTML Attribute" }
    ],
    moderate: [
        { task: "Remove underline", correct: "text-decoration: none;", wrong: ["font-style: none;", "text-align: none;", "decoration: none;", "no-underline: true;"], desc: "No decoration" },
        { task: "Add padding", correct: "padding: 10px;", wrong: ["margin: 10px;", "spacing: 10px;", "inner: 10px;", "gap: 10px;"], desc: "Inner spacing" },
        { task: "Circle shape", correct: "border-radius: 50%;", wrong: ["border: circle;", "shape: circle;", "radius: circle;", "round: true;"], desc: "Round corners" },
        { task: "Flex container", correct: "display: flex;", wrong: ["position: flex;", "float: flex;", "layout: flex;", "view: flex;"], desc: "Flexible layout" },
        { task: "Z-Index", correct: "z-index: 10;", wrong: ["index: 10;", "layer: 10;", "level: 10;", "stack: 10;"], desc: "Stack order" },
        { task: "Overflow Hidden", correct: "overflow: hidden;", wrong: ["scroll: hidden;", "clip: hidden;", "view: hidden;", "hide: true;"], desc: "Hide content" },
        { task: "Opacity", correct: "opacity: 0.5;", wrong: ["transparent: 0.5;", "alpha: 0.5;", "visible: 0.5;", "color: 0.5;"], desc: "Transparency" },
        { task: "Box Shadow", correct: "box-shadow: 5px 5px;", wrong: ["shadow: 5px;", "drop-shadow: 5px;", "border-shadow: 5px;", "shade: 5px;"], desc: "Drop shadow" },
        { task: "Gap in Grid", correct: "gap: 1rem;", wrong: ["space: 1rem;", "margin: 1rem;", "gutter: 1rem;", "padding: 1rem;"], desc: "Spacing between items" },
        { task: "Max Width", correct: "max-width: 100%;", wrong: ["width: max;", "limit: 100%;", "bound: 100%;", "clip: 100%;"], desc: "Responsive limit" },
        { task: "Cursor Pointer", correct: "cursor: pointer;", wrong: ["mouse: hand;", "pointer: click;", "click: yes;", "hand: true;"], desc: "Change mouse icon" },
        { task: "Sticky Position", correct: "position: sticky;", wrong: ["display: sticky;", "float: sticky;", "place: sticky;", "attach: sticky;"], desc: "Sticks on scroll" }
    ],
    hard: [
        { task: "Grid layout", correct: "display: grid;", wrong: ["layout: grid;", "position: grid;", "grid: true;", "view: grid;"], desc: "Grid system" },
        { task: "Absolute positioning", correct: "position: absolute;", wrong: ["display: absolute;", "location: absolute;", "place: absolute;", "fixed: absolute;"], desc: "Exact placement" },
        { task: "Hide element", correct: "display: none;", wrong: ["visibility: gone;", "opacity: 0;", "hide: input;", "remove: true;"], desc: "Remove from flow" },
        { task: "Pointer cursor", correct: "cursor: pointer;", wrong: ["mouse: pointer;", "pointer: hand;", "click: true;", "hand: true;"], desc: "Clickable icon" },
        { task: "Transition", correct: "transition: all 0.3s;", wrong: ["animate: 0.3s;", "move: 0.3s;", "change: 0.3s;", "morph: 0.3s;"], desc: "Smooth change" },
        { task: "Keyframes", correct: "@keyframes move {}", wrong: ["@animate move {}", "@motion move {}", "@frame move {}"], desc: "Animation definition" },
        { task: "Media Query", correct: "@media (max-width: 600px)", wrong: ["@screen (width: 600px)", "@view (max: 600px)", "@responsive 600px"], desc: "Responsive rule" },
        { task: "Filter Blur", correct: "filter: blur(5px);", wrong: ["effect: blur(5px);", "style: blur(5px);", "mask: blur(5px);", "fog: 5px;"], desc: "Blur effect" },
        { task: "Flex Center", correct: "justify-content: center;", wrong: ["align: center;", "flex: center;", "place: center;", "content: center;"], desc: "Horizontal center" },
        { task: "Variable Definition", correct: "--main-color: red;", wrong: ["$main-color: red;", "var-main: red;", "@main: red;", "def-color: red;"], desc: "CSS Variable" },
        { task: "Grid Columns", correct: "grid-template-columns: 1fr 1fr;", wrong: ["grid-cols: 2;", "columns: 2;", "layout: 50% 50%;", "division: 1fr;"], desc: "Two equal cols" },
        { task: "Transform Rotate", correct: "transform: rotate(45deg);", wrong: ["rotate: 45deg;", "spin: 45deg;", "turn: 45deg;", "move: rotate(45);"], desc: "Rotate element" },
        { task: "Calculate width", correct: "width: calc(100% - 20px);", wrong: ["width: 100% - 20px;", "calc: 100% - 20px;", "math: 100% - 20px;", "size: calc(100, 20);"], desc: "Dynamic calc" },
        { task: "Style Invalid Input", correct: "border-color: red;", wrong: ["validate: false;", "input: error;", "check: false;", "status: invalid;"], desc: "Error feedback" },
        { task: "Style Valid Input", correct: "border-color: green;", wrong: ["validate: true;", "input: correct;", "check: valid;", "status: valid;"], desc: "Success feedback" },
        { task: "Make input required", correct: "required", wrong: ["validate", "mandatory", "need", "check"], desc: "HTML Attribute" }
    ]
};

const dragQB = {
    easy: [
        { code: "&lt;img&gt;", desc: "Embeds an image" },
        { code: "&lt;h1&gt;", desc: "Largest Heading" },
        { code: "&lt;p&gt;", desc: "Paragraph" },
        { code: "&lt;a&gt;", desc: "Hyperlink" },
        { code: "&lt;ul&gt;", desc: "Bulleted List" },
        { code: "&lt;br&gt;", desc: "Line Break" },
        { code: "&lt;div&gt;", desc: "Container" },
        { code: "&lt;span&gt;", desc: "Inline Container" },
        { code: "&lt;button&gt;", desc: "Clickable Button" },
        { code: "&lt;input&gt;", desc: "Input Field" },
        { code: "&lt;table&gt;", desc: "Data Table" },
        { code: "&lt;form&gt;", desc: "User Input & Submit" },
        { code: "&lt;nav&gt;", desc: "Navigation Links" },
        { code: "&lt;footer&gt;", desc: "Bottom Section" }
    ],
    moderate: [
        { code: "color:red;", desc: "Red Text" },
        { code: "margin:0;", desc: "Remove Spacing" },
        { code: ".class", desc: "Class Selector" },
        { code: "#id", desc: "ID Selector" },
        { code: "display:flex;", desc: "Flexbox Layout" },
        { code: "border:1px;", desc: "Standard Border" },
        { code: "padding:10px;", desc: "Inner Spacing" },
        { code: "width:100%;", desc: "Full Width" },
        { code: "text-align:center;", desc: "Center Text" },
        { code: "font-weight:bold;", desc: "Bold Text" },
        { code: "float:left;", desc: "Align Left" },
        { code: "opacity:0;", desc: "Invisible" },
        { code: "cursor:pointer;", desc: "Hand Cursor" },
        { code: "display:none;", desc: "Hide Element" }
    ],
    hard: [
        { code: "z-index:10;", desc: "Stacking Order" },
        { code: "opacity:0.5;", desc: "Semi-transparent" },
        { code: "@media", desc: "Responsive Rule" },
        { code: "transform", desc: "Move/Scale Element" },
        { code: "grid-gap", desc: "Grid Spacing" },
        { code: ":hover", desc: "Mouse Over State" },
        { code: "position:absolute;", desc: "Absolute Pos" },
        { code: "justify-content:center;", desc: "Flex Center" },
        { code: "align-items:center;", desc: "Flex Align" },
        { code: "flex-direction:column;", desc: "Vertical Layout" },
        { code: "box-shadow", desc: "Drop Shadow" },
        { code: "transition", desc: "Smooth Change" },
        { code: "keyframes", desc: "Animation Steps" },
        { code: "filter:blur", desc: "Blur Effect" }
    ]
};

const jsQB = {
    easy: [
        { q: "typeof 'Hello'", a: ["string", "text", "str", "object"], r: "string" },
        { q: "2 + '2' = ?", a: ["'22'", "4", "NaN", "Error"], r: "'22'" },
        { q: "Boolean(0)", a: ["false", "true", "null", "undefined"], r: "false" },
        { q: "Which symbol is for comments?", a: ["//", "#", "<!--", "**"], r: "//" },
        { q: "Which declares a constant?", a: ["const", "let", "var", "fixed"], r: "const" },
        { q: "Output of: console.log(5 == '5')", a: ["true", "false", "error", "undefined"], r: "true" },
        { q: "What is NaN?", a: ["Not a Number", "Null", "New Array", "No Action"], r: "Not a Number" },
        { q: "Correct array syntax?", a: ["[]", "{}", "()", "<>"], r: "[]" },
        { q: "Operator for increment?", a: ["++", "+=", "+", "add"], r: "++" },
        { q: "Method to convert to string?", a: ["toString()", "string()", "text()", "toText()"], r: "toString()" }
    ],
    moderate: [
        { q: "[1, 2, 3].length", a: ["3", "2", "4", "undefined"], r: "3" },
        { q: "Which method adds to array end?", a: ["push()", "pop()", "shift()", "add()"], r: "push()" },
        { q: "Output: !true", a: ["false", "true", "undefined", "null"], r: "false" },
        { q: "Correct way to write a function?", a: ["function myFunc() {}", "func myFunc() {}", "def myFunc() {}", "function:myFunc()"], r: "function myFunc() {}" },
        { q: "5 === '5'", a: ["false", "true", "error", "null"], r: "false" },
        { q: "Logical AND operator", a: ["&&", "||", "&", "and"], r: "&&" },
        { q: "Result of 10 % 3?", a: ["1", "3", "0", "10"], r: "1" },
        { q: "Method to remove last array item?", a: ["pop()", "push()", "delete()", "remove()"], r: "pop()" },
        { q: "Which is a valid object?", a: ["{x:1}", "[x:1]", "(x:1)", "<x:1>"], r: "{x:1}" },
        { q: "Keyword for current object?", a: ["this", "self", "me", "obj"], r: "this" }
    ],
    hard: [
        { q: "typeof null", a: ["object", "null", "undefined", "number"], r: "object" },
        { q: "Output: 0.1 + 0.2 === 0.3", a: ["false", "true", "undefined", "NaN"], r: "false" },
        { q: "Which is NOT a loop?", a: ["foreach", "for", "while", "do...while"], r: "foreach" },
        { q: "[...'Hello']", a: ["['H','e','l','l','o']", "'Hello'", "Error", "undefined"], r: "['H','e','l','l','o']" },
        { q: "JSON.parse('{\"a\":1}')", a: ["{a: 1}", "Error", "'{\"a\":1}'", "undefined"], r: "{a: 1}" },
        { q: "What is a Promise?", a: ["Async Operation", "Sync Operation", "Loop", "Array"], r: "Async Operation" },
        { q: "What does 'use strict' do?", a: ["Enforces strict mode", "Fixes bugs", "Runs faster", "Includes library"], r: "Enforces strict mode" },
        { q: "Output: [] == ![]", a: ["true", "false", "error", "undefined"], r: "true" },
        { q: "Event loop manages?", a: ["Async callbacks", "Memory", "Variables", "DOM"], r: "Async callbacks" },
        { q: "Closure involves?", a: ["A function within a function", "Closing window", "Ending loop", "DOM events"], r: "A function within a function" }
    ]
};

function runDragMaster(container) {
    const level = getLevel('drag');
    const pool = dragQB[level] || dragQB['easy'];
    // Pick 4 random pairs
    const selected = pool.sort(() => 0.5 - Math.random()).slice(0, 4);

    // Separate Shuffled Arrays
    const draggables = [...selected].sort(() => 0.5 - Math.random());
    const dropzones = [...selected].sort(() => 0.5 - Math.random()); // Actually we keep dropzones sorted or random? Random is harder. Let's keep desc random too.

    let score = 0;

    container.html(`
                <div class="max-w-4xl mx-auto relative">
                     <!-- Floating Feedback Msg -->
                     <div id="drag-msg" class="absolute inset-0 z-50 flex items-center justify-center pointer-events-none hidden"></div>

                    <div class="text-center mb-8">
                         <span class="text-xs font-black text-purple-500 uppercase tracking-widest mb-2 block">Level: ${level.toUpperCase()}</span>
                        <h2 class="text-3xl font-black text-slate-900 dark:text-slate-200 mb-2">Code Drag Master</h2>
                        <p class="text-slate-400">Match the code snippets to their definitions.</p>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 md:gap-12">
                        <!-- Draggables -->
                        <div class="space-y-4">
                            <h3 class="text-xs font-black text-slate-400 uppercase tracking-widest mb-4">Code Blocks</h3>
                            ${draggables.map((item, i) => `
                                <div id="drag-${i}" class="p-4 bg-white dark:bg-slate-800 border-2 border-slate-200 dark:border-slate-700 rounded-xl shadow-sm cursor-grab active:cursor-grabbing hover:border-purple-500 transition-all font-mono font-bold text-center text-slate-700 dark:text-slate-200" draggable="true" ondragstart="drag(event)" data-match="${item.code}">
                                    ${item.code}
                                </div>
                            `).join('')}
                        </div>

                        <!-- Drop Zones -->
                        <div class="space-y-4">
                            <h3 class="text-xs font-black text-slate-400 uppercase tracking-widest mb-4">Definitions</h3>
                            ${dropzones.map((item, i) => {
        const colors = ['border-blue-500/30 bg-blue-50/10', 'border-purple-500/30 bg-purple-50/10', 'border-rose-500/30 bg-rose-50/10', 'border-amber-500/30 bg-amber-50/10'];
        return `
                                <div id="drop-${i}" class="p-4 border-2 border-dashed ${colors[i % colors.length]} rounded-xl flex items-center justify-center text-slate-500 dark:text-slate-400 text-sm font-bold min-h-[72px] transition-all relative group" ondrop="drop(event)" ondragover="allowDrop(event)" data-match="${item.code}">
                                    <div class="absolute top-2 left-2 text-[8px] opacity-30 font-black uppercase">Slot 0${i + 1}</div>
                                    <span class="relative z-10 px-4 text-center">${item.desc}</span>
                                </div>
                            `}).join('')}
                        </div>
                    </div>
                </div>
            `);

    showToast(`Adaptivity Active: Difficulty set to ${level.toUpperCase()}`);

    // Drag Functions Global scope (attached to window for HTML attributes)
    window.allowDrop = (ev) => {
        ev.preventDefault();
    };

    window.drag = (ev) => {
        ev.dataTransfer.setData("text", ev.target.id);
        ev.dataTransfer.setData("match", ev.target.getAttribute('data-match'));
    };

    window.drop = (ev) => {
        ev.preventDefault();
        const data = ev.dataTransfer.getData("text");
        const matchCode = ev.dataTransfer.getData("match");
        const dropZone = ev.target.closest('[ondrop]'); // Ensure we hit the zone

        if (!dropZone) return;

        // If zone already has content, ignore
        if (dropZone.classList.contains('bg-emerald-50')) return;

        const targetMatch = dropZone.getAttribute('data-match');
        const draggedEl = document.getElementById(data);

        if (matchCode === targetMatch) {
            // MATCH!
            score++;

            // Style Update
            dropZone.innerHTML = ``;
            dropZone.appendChild(draggedEl);
            $(dropZone).removeClass('border-dashed border-slate-300 text-slate-400').addClass('border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 shadow-inner');
            $(draggedEl).removeClass('bg-white border-slate-200 cursor-grab').addClass('bg-transparent border-0 cursor-default text-emerald-700 w-full text-lg shadow-none').attr('draggable', 'false');

            showGameFeedback("Correct!", true);
            confetti({ particleCount: 20, spread: 50, origin: { y: 0.6 } });

            if (score === selected.length) {
                // Background Save
                saveLevel('drag', score, selected.length).then(leveledUp => {
                    if (window.awardBadge) window.awardBadge('arcade_win');

                    // Delay slightly for feedback to be seen, then show Finalize screen
                    setTimeout(() => {
                        container.html(`
                                    <div class="text-center animate-in zoom-in max-w-md mx-auto bg-white dark:bg-slate-800 p-8 rounded-3xl shadow-xl border border-slate-200 dark:border-slate-700 relative z-10">
                                        ${leveledUp ? `<div class="mb-6 p-4 bg-yellow-50 dark:bg-yellow-900/20 border-2 border-yellow-400 rounded-xl text-yellow-600 font-black uppercase animate-pulse w-full text-center">🎉 LEVEL UP TO ${getLevel('drag').toUpperCase()}!</div>` : ''}
                                        <div class="w-24 h-24 bg-gradient-to-br from-emerald-100 to-emerald-50 dark:from-emerald-900/40 dark:to-emerald-800/20 rounded-full flex items-center justify-center mx-auto mb-6 shadow-sm border border-emerald-200 dark:border-emerald-700/50">
                                            <span class="text-5xl">✅</span>
                                        </div>
                                        <h2 class="text-4xl font-black text-slate-900 dark:text-white uppercase tracking-tight mb-2">All Matched!</h2>
                                        <p class="text-slate-500 dark:text-slate-400 mb-8 font-medium">Excellent work organizing the elements.</p>
                                        <div class="flex gap-4 justify-center mt-8">
                                            <button onclick="startArcadeGame('drag_master')" class="px-8 py-3.5 bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 hover:bg-slate-200 dark:hover:bg-slate-600 rounded-xl font-bold transition-colors flex items-center gap-2">
                                                <span>▶</span> Play Next
                                            </button>
                                            <button onclick="exitArcadeGame()" class="px-8 py-3.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl font-bold uppercase tracking-wider transition-all shadow-lg shadow-indigo-500/30">
                                                Menu
                                            </button>
                                        </div>
                                    </div>
                                `);
                        lucide.createIcons();
                        saveGameScore('drag_master', score, selected.length);
                    }, 1200);
                }).catch(e => {
                    console.warn("Save failed but continuing...", e);
                    // Fallback if saveLevel throws for some reason
                    setTimeout(() => {
                        container.html(`<div class="text-center">Error in mission completion. Please retry.</div>`);
                    }, 1000);
                });
            }
        } else {
            // WRONG
            showGameFeedback("Incorrect!", false, targetMatch);
            $(dropZone).addClass('bg-rose-50 border-rose-500').delay(500).queue(function (next) {
                $(this).removeClass('bg-rose-50 border-rose-500');
                next();
            });
        }
    };

    // No more showDragFeedback locally
}

function runHtmlMaster(container) {
    let score = 0;
    // Global timer used
    const timeLeftInit = 15;

    // 1. Determine Difficulty
    const currentLevel = getLevel('html');
    let pool = htmlQB[currentLevel];

    // 2. Randomize & Pick Questions
    const questions = pool.sort(() => 0.5 - Math.random()).slice(0, 6);

    // Visual Level Indicator
    showToast(`Adaptivity Active: ${currentLevel.toUpperCase()}`);

    let qIdx = 0;

    function renderQ() {
        clearInterval(window.activeGameTimer);

        if (qIdx >= questions.length) {
            // --- GAME OVER SCREEN ---
            const accuracy = Math.round((score / questions.length) * 100);

            // SAVE PROGRESSION
            saveLevel('html', score, questions.length).then(leveledUp => {
                const nextLevelMsg = leveledUp ? `<div class="mb-6 p-4 bg-yellow-50 dark:bg-yellow-900/20 border-2 border-yellow-400 rounded-xl text-yellow-600 font-black uppercase animate-pulse">?? LEVEL UP TO ${getLevel('html').toUpperCase()}!</div>` : '';

                container.html(`
                            <div class="max-w-md mx-auto bg-white dark:bg-slate-800 rounded-3xl p-8 shadow-2xl border border-slate-200 dark:border-slate-700 text-center animate-in zoom-in duration-300 relative z-10">
                                 ${leveledUp ? `<div class="mb-6 p-4 bg-yellow-50 dark:bg-yellow-900/20 border-2 border-yellow-400 rounded-xl text-yellow-600 font-black uppercase animate-pulse w-full text-center">🎉 LEVEL UP TO ${getLevel('html').toUpperCase()}!</div>` : ''}
                                <div class="w-28 h-28 mx-auto bg-gradient-to-br from-indigo-50 to-indigo-100/50 dark:from-indigo-900/40 dark:to-indigo-800/20 rounded-full flex items-center justify-center mb-6 shadow-inner border border-indigo-100 dark:border-indigo-700/50">
                                    <span class="text-6xl drop-shadow-md">🏆</span>
                                </div>
                                <h3 class="text-4xl font-black text-slate-900 dark:text-white mb-2 uppercase tracking-tighter">Mission Complete</h3>
                                
                                <div class="flex justify-center gap-10 my-8">
                                    <div class="bg-slate-50 dark:bg-slate-900/50 p-4 rounded-2xl w-32 border border-slate-100 dark:border-slate-700">
                                        <p class="text-[10px] font-black uppercase text-slate-400 dark:text-slate-500 tracking-widest mb-1">Score</p>
                                        <p class="text-4xl font-black text-indigo-600 dark:text-indigo-400">${score}</p>
                                    </div>
                                    <div class="bg-slate-50 dark:bg-slate-900/50 p-4 rounded-2xl w-32 border border-slate-100 dark:border-slate-700">
                                        <p class="text-[10px] font-black uppercase text-slate-400 dark:text-slate-500 tracking-widest mb-1">Accuracy</p>
                                        <p class="text-4xl font-black text-emerald-500 dark:text-emerald-400 drop-shadow-sm">${accuracy}%</p>
                                    </div>
                                </div>
                                
                                <div id="save-status" class="mb-8 text-xs font-bold text-slate-400 italic">Saving Result...</div>
                                
                                <div class="flex gap-4 justify-center">
                                    <button onclick="startArcadeGame('html_master')" class="flex-1 py-4 bg-slate-100 dark:bg-slate-700 text-slate-700 dark:text-slate-200 hover:bg-slate-200 dark:hover:bg-slate-600 rounded-xl font-bold transition-colors flex items-center justify-center gap-2">
                                        <span>▶</span> Next Level
                                    </button>
                                    <button onclick="exitArcadeGame()" class="flex-1 py-4 bg-indigo-600 text-white hover:bg-indigo-700 rounded-xl font-bold shadow-lg shadow-indigo-500/30 transition-all uppercase tracking-wider">Menu</button>
                                </div>
                            </div>
                        `);
                lucide.createIcons();
                // Save Score to DB (Mock)
                saveGameScore('html_master', score, questions.length);
            });

            return;
        }

        const curr = questions[qIdx];
        let timeLeft = timeLeftInit;

        // Render Question UI
        container.html(`
                    <div class="max-w-2xl mx-auto">
                        <!-- Header / Stats -->
                        <div class="flex justify-between items-center mb-8">
                            <div class="flex items-center gap-3">
                                <span class="px-3 py-1 bg-indigo-100 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400 rounded-lg text-xs font-black uppercase tracking-wider">Q${qIdx + 1} / ${questions.length}</span>
                                <span class="text-slate-400 text-xs font-bold">Score: ${score}</span>
                            </div>
                            <div class="flex items-center gap-2 text-rose-500 font-mono font-black text-xl">
                                <i data-lucide="timer" class="w-5 h-5"></i> <span id="game-timer">${timeLeft}s</span>
                            </div>
                        </div>

                        <!-- Progress Bar -->
                        <div class="w-full h-1.5 bg-slate-100 dark:bg-slate-800 rounded-full mb-8 overflow-hidden">
                            <div class="h-full bg-indigo-500 transition-all duration-1000 ease-linear" style="width: 100%" id="timer-bar"></div>
                        </div>

                        <!-- Question Card -->
                        <div class="mb-10 text-center">
                            <h2 class="text-3xl font-black text-slate-900 dark:text-slate-200 mb-6 leading-tight">${curr.q}</h2>
                        </div>

                        <!-- Options Grid -->
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 w-full">
                            ${curr.a.map((opt, i) => {
            const themes = [
                { color: 'text-indigo-500', bg: 'bg-indigo-50', border: 'hover:border-indigo-500', icon: 'zap' },
                { color: 'text-cyan-500', bg: 'bg-cyan-50', border: 'hover:border-cyan-500', icon: 'code' },
                { color: 'text-purple-500', bg: 'bg-purple-50', border: 'hover:border-purple-500', icon: 'terminal' },
                { color: 'text-blue-500', bg: 'bg-blue-50', border: 'hover:border-blue-500', icon: 'layers' }
            ];
            const t = themes[i % themes.length];
            return `
                                <button id="opt-${i}" class="group relative p-6 bg-white dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 rounded-2xl ${t.border} hover:shadow-xl transition-all duration-300 text-left flex items-start gap-4" onclick="checkProAns(this, '${opt.replace(new RegExp("'", 'g'), "\\'").replace(/\n/g, " ")}')">
                                    <div class="w-10 h-10 rounded-xl ${t.bg} dark:${t.bg}/10 ${t.color} flex items-center justify-center shrink-0 font-black text-sm group-hover:scale-110 transition-transform">
                                        <i data-lucide="${t.icon}" class="w-5 h-5"></i>
                                    </div>
                                    <div class="flex-1 min-w-0">
                                        <span class="block text-[10px] font-black uppercase tracking-widest text-slate-400 mb-1">Option ${String.fromCharCode(65 + i)}</span>
                                        <span class="font-mono text-lg font-bold text-slate-700 dark:text-slate-200 block truncate">${opt.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</span>
                                    </div>
                                </button>
                            `}).join('')}
                        </div>
                    </div>
                `);

        lucide.createIcons();

        // Start Timer
        window.activeGameTimer = setInterval(() => {
            timeLeft--;
            $('#game-timer').text(timeLeft + 's');
            $('#timer-bar').css('width', `${(timeLeft / timeLeftInit) * 100}%`);

            if (timeLeft <= 0) {
                clearInterval(window.activeGameTimer);
                handleTimeout();
            }
        }, 1000);

        window.checkProAns = (btn, ans) => {
            clearInterval(window.activeGameTimer);
            const isCorrect = curr.r.includes(ans);
            const $btn = $(btn);

            // Disable all buttons
            $('button[id^="opt-"]').prop('disabled', true).addClass('opacity-50 cursor-not-allowed');
            $btn.removeClass('opacity-50 cursor-not-allowed'); // Keep selected opacity full

            if (isCorrect) {
                score++;
                $btn.removeClass('border-slate-100 dark:border-slate-700 hover:border-indigo-500').addClass('bg-emerald-50 dark:bg-emerald-900/20 border-emerald-500 ring-4 ring-emerald-500/20');
                $btn.find('span:first-child').addClass('bg-emerald-100 text-emerald-600');
                // Confetti for correct answer
                confetti({ particleCount: 30, spread: 40, origin: { y: 0.6 } });
                showGameFeedback("CORRECT!", true);
            } else {
                // Mark Wrong
                $btn.removeClass('border-slate-100 dark:border-slate-700 hover:border-indigo-500').addClass('bg-rose-50 dark:bg-rose-900/20 border-rose-500 ring-4 ring-rose-500/20');
                $btn.find('span:first-child').addClass('bg-rose-100 text-rose-600');
                showGameFeedback("WRONG!", false, curr.r.join(', '));

                // Highlight Correct One
                curr.a.forEach((opt, i) => {
                    if (curr.r.includes(opt)) {
                        $(`#opt-${i}`).removeClass('opacity-50').addClass('border-emerald-500 border-dashed');
                    }
                });
            }

            setTimeout(() => {
                qIdx++;
                renderQ();
            }, 1500); // Slower transition to allow reading feedback
        };

        function handleTimeout() {
            $('button[id^="opt-"]').prop('disabled', true).addClass('opacity-50 cursor-not-allowed');
            showGameFeedback("TIME'S UP!", false, curr.r.join(', '));

            // Highlight Correct One
            curr.a.forEach((opt, i) => {
                if (curr.r.includes(opt)) {
                    $(`#opt-${i}`).removeClass('opacity-50').addClass('border-emerald-500 border-dashed');
                }
            });

            setTimeout(() => {
                qIdx++;
                renderQ();
            }, 2000);
        }

    }
    // Clear overlay on new render just in case
    clearGameFeedback();
    renderQ();
}


// --- NAVIGATION & LAYOUT LOGIC ---


// --- LIVE CODE EDITOR ENGINE ---
// Debounce Utility
let debounceTimer;
let pyodide = null; // Defined for compatibility if needed elsewhere, though unused

window.runCodeDebounced = () => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
        window.runCode();
    }, 800);
};

window.openLiveEditor = () => {
    switchTab('playground');

    // FORCE VISIBILITY: Direct CSS override
    $('#view-playground').removeClass('hidden').css('display', 'flex');

    // Initialize preview if empty
    const preview = $('#code-preview');
    if (preview.length && (preview.attr('srcdoc') === undefined || preview.attr('srcdoc') === '')) {
        window.runCode();
    }
};

window.runCode = async () => {
    if (window.awardBadge) window.awardBadge('code_runner');

    const preview = document.getElementById('code-preview');
    if (!preview) return;
    const previewDoc = preview.contentDocument || preview.contentWindow.document;

    // WEB MODE (HTML/CSS/JS)
    const htmlVal = $('#code-html').val() || '';
    const cssVal = $('#code-css').val() || '';
    const jsVal = $('#code-js').val() || '';

    const css = '<style>' + cssVal + '</style>';
    const js = '\n\ntry {\n' + jsVal + '\n} catch(err) { console.error(err); }\n' + '<' + '/script>';

    if (previewDoc.documentElement) {
        previewDoc.documentElement.innerHTML = htmlVal + css + js;
    } else {
        previewDoc.open();
        previewDoc.write(htmlVal + css + js);
        previewDoc.close();
    }
};

window.clearCode = () => {
    $('#code-html').val('');
    $('#code-css').val('');
    $('#code-js').val('');
    window.runCode(); // Clear preview in Web mode
};


window.toggleEditorPanel = (type) => {
    const panel = $(`#panel-${type}`);
    const btn = $(`#btn-toggle-${type}`);

    if (panel.hasClass('hidden')) {
        panel.removeClass('hidden');
        btn.removeClass('opacity-50 grayscale');

        // Auto-open HTML if CSS or JS is opened
        if (type === 'css' || type === 'js') {
            $('#panel-html').removeClass('hidden');
            $('#btn-toggle-html').removeClass('opacity-50 grayscale');
        }
    } else {
        panel.addClass('hidden');
        btn.addClass('opacity-50 grayscale');
    }
};

// Shift+Enter Shortcut
$(document).ready(() => {
    $('#code-html, #code-css, #code-js').on('keydown', function (e) {
        if (e.shiftKey && e.key === 'Enter') {
            e.preventDefault();
            window.runCode();
        }
    });
});



// --- BADGE SYSTEM LOGIC ---
window.renderBadges = async () => {
    const container = $('#badges-grid');
    container.empty();

    if (!userProfile || userProfile.role !== 'student') {
        container.html(`<div class="col-span-full text-center py-4 text-slate-400 text-xs italic">Badges are only for students.</div>`);
        return;
    }
};
