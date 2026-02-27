const fs = require('fs');

const f = 'c:/Users/Hon3y Chauhan/Desktop/NAVTTC-LMS/index.html';
let c = fs.readFileSync(f, 'utf8');

// The current HTML for the logo container looks like this due to the previous regex replacement:
/*
<div class="px-2 mb-8 flex items-center justify-between">
                <!-- Left: Logo & Text -->
                <div class="flex items-center gap-2">
                    <div class="logo-container w-10 h-10 flex-shrink-0 flex items-center justify-center">
                        <img src="assets/logo.png" alt="BBSHRRDB Logo" class="w-full h-full object-contain">
                    </div>
                    <div
                        class="hide-on-collapse flex flex-col justify-center overflow-hidden transition-all duration-300">
                        <h1
                            class="font-black text-lg tracking-tighter uppercase leading-none flex items-center gap-1 text-slate-800 dark:text-white">
                            NAVTTC LMS <span class="text-[9px] bg-indigo-600 text-white px-1.5 py-0.5 rounded-md font-bold shadow-sm whitespace-nowrap align-middle">V2.0</span>
                        </h1>
                        <p
                            class="text-[8px] font-bold tracking-[0.15em] text-indigo-500 uppercase mt-0.5 leading-tight">
                            Enterprise Portal
                        </p>
                    </div>
                </div>
*/

// Let's replace the whole header inner structure for the sidebar and force flex alignment to be visually centered.
// We'll align the items to `items-center` in the main wrapper, but the text group should be tightly packed.
const targetRegex = /<div class="px-2 mb-8 flex items-center justify-between">[\s\S]*?<!-- Right: Mobile Close Button \(X\) -->/;

const replacement = `<div class="px-2 mb-8 flex items-center justify-between">
                <!-- Left: Logo & Text -->
                <div class="flex items-center gap-3 w-full">
                    <div class="logo-container w-10 h-10 flex-shrink-0 flex items-center justify-center pt-1">
                        <img src="assets/logo.png" alt="NAVTTC Logo" class="w-full h-full object-contain drop-shadow-sm">
                    </div>
                    <div class="hide-on-collapse flex flex-col justify-center translate-y-[2px] overflow-hidden transition-all duration-300">
                        <h1 class="font-black text-[15px] tracking-tight uppercase leading-none flex items-center flex-wrap gap-1 text-slate-800 dark:text-white m-0 p-0">
                            NAVTTC LMS 
                            <span class="text-[9px] bg-indigo-600 text-white px-1.5 py-0.5 rounded-md font-bold shadow-sm whitespace-nowrap leading-none inline-block">V2.0</span>
                        </h1>
                        <p class="text-[9px] font-bold tracking-[0.1em] text-slate-500 uppercase mt-1 leading-none m-0 p-0">
                            Enterprise Portal
                        </p>
                    </div>
                </div>

                <!-- Right: Mobile Close Button (X) -->`;

if (targetRegex.test(c)) {
    c = c.replace(targetRegex, replacement);
    fs.writeFileSync(f, c);
    console.log("Successfully fixed vertical alignment of sidebar logo.");
} else {
    console.log("Regex not matched to replace sidebar header exactly.");
}
