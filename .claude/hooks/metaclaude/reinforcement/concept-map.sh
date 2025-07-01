#!/bin/bash
# MetaClaude Concept Map Generator
# Creates visual concept maps showing where principles are defined and referenced

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PATTERNS_FILE="$SCRIPT_DIR/concept-patterns.json"
OUTPUT_DIR="$SCRIPT_DIR/../../../data/concept-maps"

# Initialize output directory
mkdir -p "$OUTPUT_DIR"

# Function to find concept definitions and references
map_concept_locations() {
    local target="$1"
    local concept="$2"
    local keywords="$3"
    
    # Find all occurrences with context
    local locations=()
    
    # Search for each keyword separately
    IFS=',' read -ra keyword_array <<< "$keywords"
    for keyword in "${keyword_array[@]}"; do
        # Search for definitions (stronger indicators)
        while IFS=: read -r file line content; do
            local type="reference"
            local strength="weak"
            
            # Check if it's a definition
            if echo "$content" | grep -i -E "(is |means |refers to |defined as |describes )" >/dev/null 2>&1; then
                type="definition"
                strength="strong"
            elif echo "$content" | grep -i -E "(following |based on |according to |see )" >/dev/null 2>&1; then
                type="reference"
                strength="medium"
            fi
            
            locations+=("{\"file\":\"${file#./}\",\"line\":$line,\"type\":\"$type\",\"strength\":\"$strength\",\"snippet\":\"${content:0:100}...\"}")
        done < <(grep -r -n -i -w "$keyword" "$target" 2>/dev/null | grep -v node_modules | grep -v .git | head -20)
    done
    
    echo "${locations[@]}"
}

# Function to generate DOT graph
generate_dot_graph() {
    local concept_data="$1"
    local output_file="$2"
    
    cat > "$output_file" << 'EOF'
digraph ConceptMap {
    rankdir=LR;
    node [shape=box, style=rounded];
    
    // Styling
    graph [fontname="Arial", fontsize=12, bgcolor="white"];
    node [fontname="Arial", fontsize=10];
    edge [fontname="Arial", fontsize=9];
    
    // Legend
    subgraph cluster_legend {
        label="Legend";
        style=dotted;
        
        legend_def [label="Definition", shape=box, style="rounded,filled", fillcolor="lightblue"];
        legend_ref [label="Reference", shape=box, style="rounded,filled", fillcolor="lightgray"];
        legend_strong [label="Strong Link", style=invis];
        legend_weak [label="Weak Link", style=invis];
        
        legend_strong -> legend_weak [label="Relationship Strength", style=bold];
    }
    
EOF
    
    # Parse concept data and add nodes/edges
    echo "$concept_data" | python3 -c "
import json
import sys
import os

def sanitize_label(text):
    return text.replace('\"', '\\\"').replace('\\n', ' ')[:50]

def get_node_id(file):
    return file.replace('/', '_').replace('.', '_').replace('-', '_')

try:
    # Read all input
    input_data = sys.stdin.read()
    
    # Process each concept
    concepts = json.loads(input_data)
    
    # Track files and their roles
    file_nodes = {}
    definitions = {}
    references = {}
    
    for concept_name, locations in concepts.items():
        for loc in locations:
            file = loc['file']
            node_id = get_node_id(file)
            
            if file not in file_nodes:
                file_nodes[file] = {
                    'id': node_id,
                    'definitions': [],
                    'references': []
                }
            
            if loc['type'] == 'definition':
                file_nodes[file]['definitions'].append(concept_name)
                if concept_name not in definitions:
                    definitions[concept_name] = []
                definitions[concept_name].append(file)
            else:
                file_nodes[file]['references'].append(concept_name)
                if concept_name not in references:
                    references[concept_name] = []
                references[concept_name].append(file)
    
    # Generate nodes
    for file, info in file_nodes.items():
        label = os.path.basename(file)
        color = 'lightblue' if info['definitions'] else 'lightgray'
        tooltip = f\"{len(info['definitions'])} definitions, {len(info['references'])} references\"
        
        print(f'    {info[\"id\"]} [label=\"{label}\", fillcolor=\"{color}\", style=\"filled,rounded\", tooltip=\"{tooltip}\"];')
    
    # Generate edges
    for concept, def_files in definitions.items():
        for def_file in def_files:
            def_node = get_node_id(def_file)
            
            # Connect definitions to references
            if concept in references:
                for ref_file in references[concept]:
                    if ref_file != def_file:
                        ref_node = get_node_id(ref_file)
                        print(f'    {def_node} -> {ref_node} [label=\"{concept}\", color=\"blue\", style=\"dashed\"];')
    
except Exception as e:
    print(f'    error [label=\"Error: {str(e)}\", color=\"red\"];', file=sys.stderr)
" >> "$output_file"
    
    echo "}" >> "$output_file"
}

# Function to generate HTML visualization
generate_html_visualization() {
    local concept_data="$1"
    local output_file="$2"
    
    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>MetaClaude Concept Map</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        .concept-section {
            margin: 20px 0;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 5px;
            border-left: 4px solid #007bff;
        }
        .concept-name {
            font-weight: bold;
            color: #007bff;
            font-size: 18px;
            margin-bottom: 10px;
        }
        .file-list {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin: 10px 0;
        }
        .file-item {
            padding: 5px 10px;
            border-radius: 3px;
            font-size: 14px;
        }
        .definition {
            background: #cfe2ff;
            border: 1px solid #6ea8fe;
        }
        .reference {
            background: #e2e3e5;
            border: 1px solid #adb5bd;
        }
        .stats {
            margin: 20px 0;
            padding: 15px;
            background: #e9ecef;
            border-radius: 5px;
        }
        .redundancy-warning {
            background: #f8d7da;
            color: #721c24;
            padding: 10px;
            border-radius: 5px;
            margin: 10px 0;
        }
        .legend {
            display: flex;
            gap: 20px;
            margin: 20px 0;
            font-size: 14px;
        }
        .legend-item {
            display: flex;
            align-items: center;
            gap: 5px;
        }
        .legend-box {
            width: 20px;
            height: 20px;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>MetaClaude Concept Map</h1>
        <p>Generated: <span id="timestamp"></span></p>
        
        <div class="legend">
            <div class="legend-item">
                <div class="legend-box definition"></div>
                <span>Definition</span>
            </div>
            <div class="legend-item">
                <div class="legend-box reference"></div>
                <span>Reference</span>
            </div>
        </div>
        
        <div id="stats" class="stats"></div>
        <div id="warnings"></div>
        <div id="concepts"></div>
    </div>
    
    <script>
        const conceptData = 
EOF
    
    echo "$concept_data" >> "$output_file"
    
    cat >> "$output_file" << 'EOF'
        ;
        
        // Set timestamp
        document.getElementById('timestamp').textContent = new Date().toLocaleString();
        
        // Process data
        const stats = {
            totalConcepts: Object.keys(conceptData).length,
            totalDefinitions: 0,
            totalReferences: 0,
            redundantDefinitions: []
        };
        
        // Build concept sections
        const conceptsDiv = document.getElementById('concepts');
        const warningsDiv = document.getElementById('warnings');
        
        for (const [concept, locations] of Object.entries(conceptData)) {
            const section = document.createElement('div');
            section.className = 'concept-section';
            
            const title = document.createElement('div');
            title.className = 'concept-name';
            title.textContent = concept.replace(/_/g, ' ').toUpperCase();
            section.appendChild(title);
            
            const definitions = locations.filter(l => l.type === 'definition');
            const references = locations.filter(l => l.type === 'reference');
            
            stats.totalDefinitions += definitions.length;
            stats.totalReferences += references.length;
            
            // Check for redundant definitions
            if (definitions.length > 1) {
                stats.redundantDefinitions.push({
                    concept: concept,
                    count: definitions.length,
                    files: definitions.map(d => d.file)
                });
            }
            
            // Add definitions
            if (definitions.length > 0) {
                const defLabel = document.createElement('div');
                defLabel.innerHTML = '<strong>Defined in:</strong>';
                section.appendChild(defLabel);
                
                const defList = document.createElement('div');
                defList.className = 'file-list';
                
                definitions.forEach(def => {
                    const item = document.createElement('div');
                    item.className = 'file-item definition';
                    item.textContent = def.file + ':' + def.line;
                    item.title = def.snippet;
                    defList.appendChild(item);
                });
                
                section.appendChild(defList);
            }
            
            // Add references
            if (references.length > 0) {
                const refLabel = document.createElement('div');
                refLabel.innerHTML = '<strong>Referenced in:</strong>';
                section.appendChild(refLabel);
                
                const refList = document.createElement('div');
                refList.className = 'file-list';
                
                references.forEach(ref => {
                    const item = document.createElement('div');
                    item.className = 'file-item reference';
                    item.textContent = ref.file + ':' + ref.line;
                    item.title = ref.snippet;
                    refList.appendChild(item);
                });
                
                section.appendChild(refList);
            }
            
            conceptsDiv.appendChild(section);
        }
        
        // Add stats
        document.getElementById('stats').innerHTML = `
            <h3>Summary Statistics</h3>
            <p>Total Concepts: ${stats.totalConcepts}</p>
            <p>Total Definitions: ${stats.totalDefinitions}</p>
            <p>Total References: ${stats.totalReferences}</p>
            <p>Average References per Concept: ${(stats.totalReferences / stats.totalConcepts).toFixed(1)}</p>
        `;
        
        // Add warnings
        if (stats.redundantDefinitions.length > 0) {
            const warning = document.createElement('div');
            warning.className = 'redundancy-warning';
            warning.innerHTML = '<h3>⚠️ Redundant Definitions Detected</h3>';
            
            stats.redundantDefinitions.forEach(rd => {
                warning.innerHTML += `<p><strong>${rd.concept}:</strong> Defined ${rd.count} times in: ${rd.files.join(', ')}</p>`;
            });
            
            warningsDiv.appendChild(warning);
        }
    </script>
</body>
</html>
EOF
}

# Main execution
main() {
    local target="${1:-.}"
    local format="${2:-html}"  # html or dot
    
    # Get all concepts from patterns file
    local concepts=$(python3 -c "
import json
with open('$PATTERNS_FILE') as f:
    data = json.load(f)
    for concept in data['core_concepts']:
        print(concept)
" 2>/dev/null || echo "")
    
    if [ -z "$concepts" ]; then
        echo "{\"error\":\"No concepts defined in patterns file\"}"
        return
    fi
    
    # Collect all concept locations
    local all_locations="{"
    local first=true
    
    while IFS= read -r concept; do
        # Get keywords for this concept
        local keywords=$(python3 -c "
import json
with open('$PATTERNS_FILE') as f:
    data = json.load(f)
    if '$concept' in data['core_concepts']:
        print(','.join(data['core_concepts']['$concept']['keywords']))
" 2>/dev/null || echo "")
        
        if [ -n "$keywords" ]; then
            if [ "$first" = false ]; then
                all_locations="$all_locations,"
            fi
            
            local locations=$(map_concept_locations "$target" "$concept" "$keywords")
            all_locations="$all_locations\"$concept\":[$locations]"
            first=false
        fi
    done <<< "$concepts"
    
    all_locations="$all_locations}"
    
    # Generate output based on format
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    
    if [ "$format" = "dot" ]; then
        local output_file="$OUTPUT_DIR/concept_map_${timestamp}.dot"
        generate_dot_graph "$all_locations" "$output_file"
        echo "{\"format\":\"dot\",\"file\":\"$output_file\",\"message\":\"Run 'dot -Tpng $output_file -o concept_map.png' to generate image\"}"
    else
        local output_file="$OUTPUT_DIR/concept_map_${timestamp}.html"
        generate_html_visualization "$all_locations" "$output_file"
        echo "{\"format\":\"html\",\"file\":\"$output_file\",\"message\":\"Open $output_file in a web browser to view the concept map\"}"
    fi
}

# Execute main function
main "$@"