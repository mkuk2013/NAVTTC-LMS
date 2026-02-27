const fs = require('fs');

const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

// We need to replace the logo and text block in the sidebar (around line 2143):
/*
                <div class="px-2 mb-8 flex items-center justify-between">
                <!-- Left: Logo & Text -->
                <!-- Left: Logo & Text -->
                <div class="flex items-center gap-3">
                    <div class="logo-container w-14 h-14 flex-shrink-0 flex items-center justify-center">
                        <img src="assets/logo.png" alt="BBSHRRDB Logo" class="w-full h-full object-contain">
                    </div>
                    <div
                        class="hide-on-collapse flex flex-col justify-center overflow-hidden transition-all duration-300">
                        <h1
                            class="font-black text-lg tracking-tighter uppercase leading-none flex items-center gap-1 text-slate-800 dark:text-white">
                            NAVTTC <span
                                class="text-[8px] bg-indigo-600 text-white px-1 py-0.5 rounded ml-1 align-top">v2.0</span>
                        </h1>
                        <p
                            class="text-[8px] font-bold tracking-[0.15em] text-indigo-500 uppercase mt-0.5 leading-tight">
                            Enterprise Portal
                        </p>
                    </div>
                </div>
*/

const searchStr = `<div class="px-2 mb-8 flex items-center justify-between">
                <!-- Left: Logo & Text -->
                <!-- Left: Logo & Text -->
                <div class="flex items-center gap-3">
                    <div class="logo-container w-14 h-14 flex-shrink-0 flex items-center justify-center">
                        <img src="assets/logo.png" alt="BBSHRRDB Logo" class="w-full h-full object-contain">
                    </div>
                    <div
                        class="hide-on-collapse flex flex-col justify-center overflow-hidden transition-all duration-300">
                        <h1
                            class="font-black text-lg tracking-tighter uppercase leading-none flex items-center gap-1 text-slate-800 dark:text-white">
                            NAVTTC <span
                                class="text-[8px] bg-indigo-600 text-white px-1 py-0.5 rounded ml-1 align-top">v2.0</span>
                        </h1>
                        <p
                            class="text-[8px] font-bold tracking-[0.15em] text-indigo-500 uppercase mt-0.5 leading-tight">
                            Enterprise Portal
                        </p>
                    </div>
                </div>`;

const replaceStr = `<div class="px-2 mb-8 flex items-center justify-between">
                <!-- Left: Logo & Text -->
                <div class="flex items-center gap-2">
                    <!-- Adjusted width and height for proper alignment -->
                    <div class="logo-container w-10 h-10 flex-shrink-0 flex items-center justify-center">
                        <img src="assets/logo.png" alt="NAVTTC Logo" class="w-full h-full object-contain drop-shadow-sm">
                    </div>
                    <div class="hide-on-collapse flex flex-col justify-center overflow-hidden transition-all duration-300">
                        <!-- Added flex-wrap and adjusted sizing to fit 'NAVTTC LMS V2.0' correctly -->
                        <h1 class="font-black text-[15px] tracking-tight uppercase leading-tight flex items-center flex-wrap gap-1 text-slate-800 dark:text-white">
                            NAVTTC LMS 
                            <span class="text-[9px] bg-indigo-600 text-white px-1.5 py-0.5 rounded-md font-bold shadow-sm whitespace-nowrap">V2.0</span>
                        </h1>
                        <p class="text-[9px] font-bold tracking-[0.1em] text-slate-500 uppercase mt-0.5 leading-tight">
                            Enterprise Portal
                        </p>
                    </div>
                </div>`;

if (c.includes(searchStr)) {
    c = c.replace(searchStr, replaceStr);
    fs.writeFileSync(f, c);
    console.log('Fixed Sidebar Alignments and Text');
} else {
    console.log('Could not find the exact string. Trying Regex.');
    // Let's try an alternative safe regex replacement for just the H1
    c = c.replace(
        /NAVTTC\s*<span\s*class="text-\[8px\] bg-indigo-600 text-white px-1 py-0\.5 rounded ml-1 align-top">v2\.0<\/span>/g,
        'NAVTTC LMS <span class="text-[9px] bg-indigo-600 text-white px-1.5 py-0.5 rounded-md font-bold shadow-sm whitespace-nowrap align-middle">V2.0</span>'
    );
    // Also fix the logo container w-14 h-14 to w-10 h-10 to prevent squishing text next to it
    c = c.replace(
        /<div class="logo-container w-14 h-14 flex-shrink-0 flex items-center justify-center">/g,
        '<div class="logo-container w-10 h-10 flex-shrink-0 flex items-center justify-center">'
    );
    c = c.replace(
        /<div class="px-2 mb-8 flex items-center justify-between">\s*<!-- Left: Logo & Text -->\s*<!-- Left: Logo & Text -->\s*<div class="flex items-center gap-3">/g,
        '<div class="px-2 mb-8 flex items-center justify-between">\n                <!-- Left: Logo & Text -->\n                <div class="flex items-center gap-2">'
    );
    fs.writeFileSync(f, c);
    console.log('Regex fix applied.');
}
