#!/bin/bash
# scripts/prepare_arxiv.sh
# Automates the creation of an arXiv-ready submission package for HydraR JOSS paper.
# This version handles de-branding and directory organization.

set -e

# Configuration
REPO_ROOT=$(git rev-parse --show-toplevel)
PAPER_DIR="$REPO_ROOT/paper"
MANUSCRIPT_DIR="$PAPER_DIR/manuscript_md"
JOSS_DIR="$PAPER_DIR/joss_submission"
ARXIV_DIR="$PAPER_DIR/arxiv_submission"

echo "--- Step 1: Checking Environment ---"
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed or not in PATH."
    exit 1
fi

# Ensure directories exist
mkdir -p "$MANUSCRIPT_DIR" "$JOSS_DIR" "$ARXIV_DIR/figures"

echo "--- Step 2: Generating JOSS Branded Outputs ---"
# We run inara on the manuscript folder
docker run --rm --platform linux/amd64 \
  --volume "$MANUSCRIPT_DIR":/data \
  --user "$(id -u):$(id -g)" \
  --workdir /data \
  --env JOURNAL=joss \
  openjournals/inara paper.md -o pdf,preprint

# Move branded outputs to joss_submission
mv "$MANUSCRIPT_DIR/paper.pdf" "$JOSS_DIR/paper.pdf"
TEX_SOURCE=$(find "$MANUSCRIPT_DIR" -name "*.preprint.tex")

echo "--- Step 3: De-branding and Figure Consolidation for arXiv ---"
# Create clean version in arxiv_submission
CLEAN_TEX="$ARXIV_DIR/paper.tex"
cp "$TEX_SOURCE" "$CLEAN_TEX"

# 1. Provide subcaption package
sed -i '' 's/\\usepackage{graphicx}/\\usepackage{graphicx}\n\\usepackage{subcaption}/g' "$CLEAN_TEX"

# 2. De-branding replacements
sed -i '' 's/Journal of Open Source Software/Journal of XXXX/g' "$CLEAN_TEX"
sed -i '' 's/JOSS/XXXX/g' "$CLEAN_TEX"

# 3. Remove rorlogo/branding TikZ (multiline removal)
# We find the \newcommand{\rorlogo} and everything until the end of that block
sed -i '' '/\\newcommand{\\rorlogo}/,/}/d' "$CLEAN_TEX"

# 4. Figure Consolidation Logic (Generic markers for travel_workflow)
# This is specific to the HydraR paper structure
# We replace the two figure environments with subfigures
# NOTE: This assumes the JOSS output format remains consistent with version 1.5.x
perl -0777 -i -pe 's/\\begin\{figure\}.*?fig:travel_workflow_a\}.*?\\end\{figure\}\s*\\begin\{figure\}.*?fig:travel_workflow_b\}.*?\\end\{figure\}/\\begin{figure}\n\\centering\n\\begin{subfigure}[b]{0.48\\textwidth}\n\\centering\n\\pandocbounded{\\includegraphics[width=\\textwidth]{figures\/Itinerary Page 1.png}}\n\\caption{Travel pamphlet visualization.}\n\\label{fig:travel_workflow_a}\n\\end{subfigure}\n\\hfill\n\\begin{subfigure}[b]{0.48\\textwidth}\n\\centering\n\\pandocbounded{\\includegraphics[width=\\textwidth]{figures\/Itinerary Page 2.png}}\n\\caption{Final CSS-styled itinerary.}\n\\label{fig:travel_workflow_b}\n\\end{subfigure}\n\\caption{Multi-modal travel itinerary planner results: (a) generated visual content; (b) final formatted itinerary.}\n\\label{fig:travel_workflow}\n\\end{figure}/sg' "$CLEAN_TEX"

# Copy figures to arxiv folder
cp -r "$MANUSCRIPT_DIR/figures/"* "$ARXIV_DIR/figures/"

echo "--- Step 4: Creating Archive ---"
cd "$ARXIV_DIR"
tar -czf "$PAPER_DIR/arxiv_submission.tar.gz" .

echo "--- SUCCESS ---"
echo "Package ready: $PAPER_DIR/arxiv_submission.tar.gz"
