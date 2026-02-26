
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

// GLOBAL YEAR UPDATE
function updateYear() {
    const yearElements = document.querySelectorAll('.dynamic-year');
    const currentYear = new Date().getFullYear();
    yearElements.forEach(el => {
        el.textContent = currentYear;
    });
}

document.addEventListener('DOMContentLoaded', () => {
    updateYear();
});
