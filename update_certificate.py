import os

file_path = r"c:\Users\Hon3y Chauhan\Desktop\BBSYDP-LMS\index.html"

new_template = """        <div id="certificate-template" class="w-[1123px] h-[794px] bg-white relative text-slate-900 mx-auto overflow-hidden shadow-2xl" style="transform: scale(0.8); transform-origin: top left;">
            
            <!-- Professional Watermark Background -->
            <div class="absolute inset-0 bg-[radial-gradient(circle_at_center,_var(--tw-gradient-stops))] from-slate-50 via-white to-slate-50"></div>
            <div class="absolute inset-0 opacity-[0.03] pointer-events-none flex items-center justify-center">
                 <!-- Large Guilloche Pattern / Logo Watermark -->
                 <svg width="600" height="600" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2L1 21h22L12 2zm0 3.99L19.53 19H4.47L12 5.99zM11 16h2v2h-2zm0-6h2v4h-2z"/></svg>
            </div>
            
            <!-- Premium Border System -->
            <div class="absolute inset-3 border-[3px] border-slate-800 z-10">
                <!-- Gold Inner Border -->
                <div class="absolute inset-1 border-[2px] border-amber-500/40"></div>
                <!-- Corner Flourishes -->
                <div class="absolute -top-1 -left-1 w-16 h-16 border-t-[4px] border-l-[4px] border-amber-600"></div>
                <div class="absolute -top-1 -right-1 w-16 h-16 border-t-[4px] border-r-[4px] border-amber-600"></div>
                <div class="absolute -bottom-1 -left-1 w-16 h-16 border-b-[4px] border-l-[4px] border-amber-600"></div>
                <div class="absolute -bottom-1 -right-1 w-16 h-16 border-b-[4px] border-r-[4px] border-amber-600"></div>
            </div>

            <!-- Content Area -->
            <div class="relative z-20 h-full flex flex-col px-16 py-12">
                
                <!-- Header: Logos & Institute Name -->
                <div class="flex justify-between items-start border-b border-slate-200 pb-6 mb-8">
                    <div class="flex items-center gap-6">
                        <!-- BBS Logo -->
                        <img src="assets/bbsydp_logo.png" class="h-20 w-auto object-contain drop-shadow-md grayscale hover:grayscale-0 transition-all" alt="BBSHRRDB">
                        <div>
                            <h1 class="text-xl font-bold text-slate-900 font-['Cinzel'] tracking-widest leading-none mb-1">BBSHRRDB</h1>
                            <p class="text-[10px] font-bold text-slate-500 uppercase tracking-[0.2em]">Government of Sindh</p>
                        </div>
                    </div>

                    <!-- Institute Details -->
                    <div class="text-right">
                        <div class="flex flex-col items-end">
                            <h2 class="text-2xl font-black text-slate-800 font-['Cinzel'] uppercase tracking-widest leading-none mb-1">Super Systech</h2>
                            <p class="text-xs font-bold text-amber-600 uppercase tracking-[0.3em] mb-3">Computers Umerkot</p>
                            
                            <!-- Certificate ID Badge -->
                            <div class="inline-flex items-center gap-3 px-4 py-1.5 bg-slate-900 text-amber-500 rounded-sm shadow-sm">
                                <span class="text-[9px] font-bold uppercase tracking-widest font-['Cinzel']">Certificate ID</span>
                                <span id="cert-id" class="text-xs font-mono font-bold text-white tracking-wider">BBS-HTML-2026-0000</span>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- Main Body -->
                <div class="flex-1 flex flex-col items-center justify-center text-center -mt-4">
                    
                    <!-- Certificate Title -->
                    <h1 class="text-5xl font-black text-slate-900 font-['Cinzel'] uppercase tracking-[0.2em] mb-2 drop-shadow-sm">
                        Certificate
                    </h1>
                    <div class="flex items-center gap-4 mb-8">
                        <div class="h-px w-12 bg-amber-500"></div>
                        <span class="text-sm font-bold text-slate-500 uppercase tracking-[0.4em] font-['Cinzel']">Of Completion</span>
                        <div class="h-px w-12 bg-amber-500"></div>
                    </div>

                    <p class="text-lg text-slate-500 font-['Playfair_Display'] italic mb-6">This is to certify that</p>

                    <!-- Student Name -->
                    <div class="relative inline-block mb-8">
                        <h2 id="cert-student-name" class="text-6xl font-bold text-slate-900 font-['Playfair_Display'] italic px-12 py-2 relative z-10 min-w-[500px]">
                            Student Name
                        </h2>
                        <!-- Decorative underline -->
                        <div class="absolute bottom-0 left-0 w-full h-px bg-gradient-to-r from-transparent via-amber-500 to-transparent opacity-50"></div>
                        <div class="absolute bottom-1 left-1/4 w-2/4 h-px bg-gradient-to-r from-transparent via-slate-400 to-transparent opacity-30"></div>
                    </div>

                    <p class="text-lg text-slate-500 font-['Playfair_Display'] italic max-w-2xl mx-auto leading-relaxed mb-8">
                        Has successfully completed the prescribed course of study and demonstrated proficiency in
                    </p>

                    <!-- Course Name -->
                    <div class="relative inline-block px-10 py-3 border border-double border-slate-200 rounded-lg bg-slate-50/50 mb-8">
                        <h3 class="text-3xl font-bold text-slate-800 font-['Cinzel'] uppercase tracking-wider">
                            HTML5 Web Development
                        </h3>
                    </div>

                    <!-- Stats Row -->
                    <div class="flex gap-12 text-center opacity-80 items-center">
                        <div>
                            <p class="text-[10px] font-bold uppercase text-slate-400 tracking-widest mb-1">Score</p>
                            <p id="cert-score" class="text-2xl font-black text-slate-700 font-['Cinzel']">98%</p>
                        </div>
                        <div class="w-px h-10 bg-slate-200"></div>
                        <div>
                            <p class="text-[10px] font-bold uppercase text-slate-400 tracking-widest mb-1">Date</p>
                            <p id="cert-date" class="text-2xl font-bold text-slate-700 font-['Cinzel']">Jan 01, 2026</p>
                        </div>
                         <div class="w-px h-10 bg-slate-200"></div>
                        <div class="flex flex-col items-center">
                             <!-- QR Code Container -->
                             <div id="cert-qr-code" class="w-16 h-16 bg-white flex items-center justify-center overflow-hidden"></div>
                             <p class="text-[7px] font-bold text-slate-400 uppercase tracking-widest mt-0.5">Verify</p>
                        </div>
                    </div>
                </div>
                    </div>
                </div>

                <!-- Footer / Signatures -->
                <div class="flex justify-between items-end pt-8 mt-4 border-t border-slate-200 relative">
                    
                    <!-- Director Signature -->
                    <div class="text-center w-56">
                        <div class="h-16 flex items-end justify-center mb-2">
                             <img src="https://upload.wikimedia.org/wikipedia/commons/e/e4/Signature_sample.svg" class="h-12 opacity-70" alt="Sig">
                        </div>
                        <div class="h-px w-full bg-slate-800 mb-2"></div>
                        <p class="text-xs font-bold text-slate-900 uppercase tracking-widest font-['Cinzel']">Director</p>
                        <p class="text-[9px] text-slate-500 uppercase tracking-wider">Academic Affairs</p>
                    </div>

                    <!-- Gold Seal (Center) -->
                    <div class="absolute left-1/2 -bottom-4 -translate-x-1/2 z-20">
                        <div class="w-32 h-32 relative flex items-center justify-center drop-shadow-xl">
                            <svg viewBox="0 0 100 100" class="w-full h-full text-amber-500">
                                <!-- Starburst -->
                                <path fill="currentColor" d="M50 0 L63 25 L90 20 L75 45 L95 65 L70 75 L65 100 L45 80 L20 95 L25 65 L5 50 L30 35 L15 10 L40 20 Z" />
                                <!-- Inner Circle -->
                                <circle cx="50" cy="50" r="38" fill="#FFF" />
                                <circle cx="50" cy="50" r="34" fill="none" stroke="#B45309" stroke-width="1" />
                                <!-- Text Path -->
                                <path id="seal-curve" d="M 24 50 A 26 26 0 1 1 76 50" fill="none" />
                                <text font-size="7" font-family="Cinzel" font-weight="bold" fill="#B45309" letter-spacing="1" text-anchor="middle">
                                    <textPath href="#seal-curve" startOffset="50%">OFFICIAL SEAL</textPath>
                                </text>
                                <!-- Icon -->
                                <path d="M50 35 L60 60 L40 60 Z" fill="#B45309" />
                            </svg>
                        </div>
                    </div>

                    <!-- Admin Signature -->
                    <div class="text-center w-56">
                        <div class="h-16 flex items-end justify-center mb-2">
                            <img id="admin-sig-img" class="h-16 object-contain opacity-90 -rotate-2" alt="Admin Sig">
                        </div>
                        <div class="h-px w-full bg-slate-800 mb-2"></div>
                        <p class="text-xs font-bold text-slate-900 uppercase tracking-widest font-['Cinzel']">Administrator</p>
                        <p class="text-[9px] text-slate-500 uppercase tracking-wider">System Verified</p>
                    </div>
                </div>
            </div>
        </div>"""

try:
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    start_index = -1
    end_index = -1

    # Find start
    for i, line in enumerate(lines):
        if '<div id="certificate-template"' in line:
            start_index = i
            break
    
    if start_index == -1:
        print("Error: Could not find certificate-template start")
        exit(1)

    # Find end anchor (feedback-modal)
    feedback_modal_index = -1
    for i in range(start_index, len(lines)):
        if '<div id="feedback-modal"' in lines[i]:
            feedback_modal_index = i
            break
            
    if feedback_modal_index == -1:
        print("Error: Could not find feedback-modal to anchor end")
        exit(1)

    # Scan backwards to find the template closing div
    # Expected structure:
    # </div> (template end)
    # </div> (container end)
    # <div id="feedback-modal" ...
    
    curr = feedback_modal_index - 1
    
    # First, find the container end (skip comments/empty lines)
    while curr > start_index:
        line_content = lines[curr].strip()
        if line_content.startswith('</div>'):
            break
        curr -= 1
        
    container_end = curr
    
    # Now find the template end (next </div> going upwards)
    curr -= 1
    while curr > start_index:
        line_content = lines[curr].strip()
        if line_content.startswith('</div>'):
            break
        curr -= 1
        
    end_index = curr
    
    if end_index <= start_index:
        print("Error: Could not correctly identify end index")
        exit(1)

    print(f"Replacing lines {start_index} to {end_index}")
    
    # Construct new content
    new_lines = lines[:start_index] + [new_template + "\n"] + lines[end_index+1:]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
        
    print("Successfully updated certificate template")

except Exception as e:
    print(f"Error: {e}")
