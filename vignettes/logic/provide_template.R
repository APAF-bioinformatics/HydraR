# ==============================================================
# APAF Bioinformatics | Macquarie University
# File:        provide_template.R
# Author:      APAF Agentic Workflow
# Purpose:     HTML template logic
# License:     LGPL (>= 3) (see LICENSE)
# ==============================================================

function(state) {
  template <- "
    <style>
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;700&family=Outfit:wght@600&display=swap');
      .pamphlet-page {
        width: 297mm;
        height: 210mm;
        padding: 15mm;
        display: flex;
        gap: 10mm;
        background: #fdfdfd;
        page-break-after: always;
        margin-bottom: 20px;
        box-shadow: 0 0 10px rgba(0,0,0,0.1);
      }
      .pamphlet-column {
        flex: 1;
        display: flex;
        flex-direction: column;
        overflow: hidden;
        font-family: 'Inter', sans-serif;
        font-size: 10pt;
        line-height: 1.4;
        color: #333;
      }
      .cover-column {
        background: linear-gradient(135deg, #1a2a6c, #b21f1f, #fdbb2d);
        color: white;
        padding: 10mm;
        border-radius: 8px;
        justify-content: center;
        align-items: center;
        text-align: center;
      }
      .cover-title {
        font-family: 'Outfit', sans-serif;
        font-size: 28pt;
        margin-bottom: 10mm;
        text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
      }
      .pamphlet-img {
        width: 100%;
        height: 40mm;
        object-fit: cover;
        border-radius: 4px;
        margin-bottom: 5mm;
      }
      .content-text {
        text-align: justify;
      }
    </style>
    <div class='pamphlet-page'>
      <div class='pamphlet-column cover-column'>
        <div class='cover-title'>{{TITLE}}</div>
        <p>Your Bespoke Adventure Awaits</p>
      </div>
      <div class='pamphlet-column'>
        <img src='images/victoria_peak.jpg' class='pamphlet-img' />
        <div class='content-text'>{{COL2}}</div>
      </div>
      <div class='pamphlet-column'>
        <img src='images/man_mo_temple.jpg' class='pamphlet-img' />
        <div class='content-text'>{{COL3}}</div>
      </div>
    </div>
    <div class='pamphlet-page'>
      <div class='pamphlet-column'>
        <img src='images/tsim_sha_tsui.jpg' class='pamphlet-img' />
        <div class='content-text'>{{COL4}}</div>
      </div>
      <div class='pamphlet-column'>
        <img src='images/temple_street.jpg' class='pamphlet-img' />
        <div class='content-text'>{{COL5}}</div>
      </div>
      <div class='pamphlet-column'>
        <img src='images/star_ferry.jpg' class='pamphlet-img' />
        <div class='content-text'>{{COL6}}</div>
      </div>
    </div>
  "
  list(status = "SUCCESS", output = template)
}

# <!-- APAF Bioinformatics | provide_template.R | Approved | 2026-04-03 -->
