#!/bin/bash
# Ralph Wiggum: Autonomous Development Loop
# Single-file implementation - no interactive mode, just CLI args
#
# Usage:
#   ./ralph.sh [OPTIONS]
#
# Options:
#   -w, --workspace PATH     Workspace directory (default: current dir)
#   -m, --model MODEL        Model to use (default: opus-4.5-thinking)
#   -i, --iterations N       Max iterations (default: 20)
#   -b, --branch NAME        Create/use this branch
#   --pr                     Open PR when complete
#   --init                   Initialize .ralph directory only
#   -h, --help               Show this help
#
# Requirements:
#   - .ralph/tasks.json (task definitions)
#   - cursor-agent CLI
#   - jq

set -euo pipefail

# Script directory (for finding prompt.md)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# CONFIGURATION
# =============================================================================

MODEL="${RALPH_MODEL:-sonnet-4.5-thinking}"
MAX_ITERATIONS="${RALPH_MAX_ITERATIONS:-20}"
WORKSPACE="."
BRANCH=""
OPEN_PR=false
INIT_ONLY=false
VERBOSE=false
DEBUG=false

# Thresholds
WARN_THRESHOLD=150000
ROTATE_THRESHOLD=170000

# Task paths
TASKS_JSON=".ralph/tasks.json"
PRD_FILE=".ralph/PRD.md"

# =============================================================================
# VALIDATION ENVIRONMENT VARIABLES
# These are used in tasks.json validation commands
# =============================================================================
export BASE_URL="${BASE_URL:-http://localhost:3000}"
export SCREENSHOT_DIR="${SCREENSHOT_DIR:-.ralph/screenshots}"
export LOG_DIR="${LOG_DIR:-.ralph/logs}"

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

show_help() {
  cat << 'EOF'
Ralph Wiggum: Autonomous Development Loop

Usage: ./ralph.sh [OPTIONS]

Options:
  -w, --workspace PATH     Workspace directory (default: current dir)
  -m, --model MODEL        Model to use (default: opus-4.5-thinking)
  -i, --iterations N       Max iterations (default: 20)
  -b, --branch NAME        Create/use this branch
  --pr                     Open PR when complete
  --init                   Initialize .ralph directory only
  -v, --verbose            Show full tool outputs (file contents, diffs, etc.)
  --debug                  Show raw JSON events (implies --verbose)
  -h, --help               Show this help

Examples:
  ./ralph.sh                              # Run in current directory
  ./ralph.sh -v                           # Verbose mode - see all tool outputs
  ./ralph.sh -w /path/to/project          # Run in specific project
  ./ralph.sh -m sonnet-4.5-thinking -i 10 # Use different model, 10 iterations
  ./ralph.sh -b feature/my-feature --pr   # Work on branch, open PR when done

Requirements:
  - .ralph/tasks.json with task definitions
  - cursor-agent CLI installed
  - jq installed
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -w|--workspace)
        WORKSPACE="$2"
        shift 2
        ;;
      -m|--model)
        MODEL="$2"
        shift 2
        ;;
      -i|--iterations)
        MAX_ITERATIONS="$2"
        shift 2
        ;;
      -b|--branch)
        BRANCH="$2"
        shift 2
        ;;
      --pr)
        OPEN_PR=true
        shift
        ;;
      --init)
        INIT_ONLY=true
        shift
        ;;
      -v|--verbose)
        VERBOSE=true
        shift
        ;;
      --debug)
        DEBUG=true
        VERBOSE=true
        shift
        ;;
      -h|--help)
        show_help
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        show_help >&2
        exit 1
        ;;
    esac
  done
}

# =============================================================================
# PREREQUISITES
# =============================================================================

check_prerequisites() {
  local errors=0

  # Check jq
  if ! command -v jq &> /dev/null; then
    echo "❌ jq not installed (brew install jq)" >&2
    errors=1
  fi

  # Check cursor-agent
  if ! command -v cursor-agent &> /dev/null; then
    echo "❌ cursor-agent not installed" >&2
    errors=1
  fi

  # Check git repo
  if ! git -C "$WORKSPACE" rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not a git repository: $WORKSPACE" >&2
    errors=1
  fi

  # Check tasks.json
  if [[ ! -f "$WORKSPACE/$TASKS_JSON" ]]; then
    echo "❌ No tasks file: $WORKSPACE/$TASKS_JSON" >&2
    errors=1
  elif ! jq empty "$WORKSPACE/$TASKS_JSON" 2>/dev/null; then
    echo "❌ Invalid JSON: $WORKSPACE/$TASKS_JSON" >&2
    errors=1
  fi

  return $errors
}

# =============================================================================
# INITIALIZATION
# =============================================================================

init_ralph() {
  local ralph_dir="$WORKSPACE/.ralph"
  mkdir -p "$ralph_dir"
  
  # Create validation output directories (used by tasks.json commands)
  mkdir -p "$WORKSPACE/$SCREENSHOT_DIR"
  mkdir -p "$WORKSPACE/$LOG_DIR"

  # Initialize files if they don't exist
  [[ -f "$ralph_dir/progress.md" ]] || cat > "$ralph_dir/progress.md" << 'EOF'
# Progress Log

> Updated by the agent after significant work.

## Session History

EOF

  # Knowledge base - the agent's learning file (simple append format)
  [[ -f "$ralph_dir/knowledge.md" ]] || cat > "$ralph_dir/knowledge.md" << 'EOF'
# Ralph Knowledge Base

> Read this FIRST at the start of each iteration.
> Append learnings at the END after each task.

---

## ⚠️ Guardrails (Pitfalls to Avoid)

### Sign: Read Before Writing
- **Trigger**: Before modifying any file
- **Do**: Always read the existing file first

### Sign: Test Before Marking Complete
- **Trigger**: Before setting `"passes": true`
- **Do**: Run tests, check browser, verify it actually works

### Sign: Commit Early and Often
- **Trigger**: After any significant change
- **Do**: Commit immediately - your commits ARE your memory across rotations

### Sign: Fix Services Before Proceeding
- **Trigger**: Database/server not running
- **Do**: Fix it first, don't skip or defer

### Sign: Don't Create Nested Git Repos
- **Trigger**: When scaffolding projects
- **Do**: Never run `git init` - repo already exists. Use `--no-git` flags.

---

## 🔧 Working Commands

```bash
# Add verified working commands here
```

---

## 🧠 Codebase Patterns

<!-- Add permanent patterns about this codebase here -->

---

## 🔴 Error → Fix Map

| Error | Fix |
|-------|-----|

---

## 📝 Iteration Log

<!-- Append your learnings below this line -->

EOF

  [[ -f "$ralph_dir/errors.log" ]] || echo "# Error Log" > "$ralph_dir/errors.log"
  [[ -f "$ralph_dir/activity.log" ]] || echo "# Activity Log" > "$ralph_dir/activity.log"
  [[ -f "$ralph_dir/.iteration" ]] || echo "0" > "$ralph_dir/.iteration"

  echo "✓ Initialized $ralph_dir"
}

# =============================================================================
# TASK MANAGEMENT
# =============================================================================

# Get count of remaining tasks
count_remaining() {
  jq '[.[] | select(.passes == false)] | length' "$WORKSPACE/$TASKS_JSON" 2>/dev/null || echo "0"
}

# Get count of completed tasks
count_completed() {
  jq '[.[] | select(.passes == true)] | length' "$WORKSPACE/$TASKS_JSON" 2>/dev/null || echo "0"
}

# Get total task count
count_total() {
  jq 'length' "$WORKSPACE/$TASKS_JSON" 2>/dev/null || echo "0"
}

# Get next task (respecting dependencies)
get_next_task() {
  jq -r '
    [.[] | select(.passes == true) | .id] as $completed |
    [.[] | select(
      .passes == false and
      (.depends_on | all(. as $dep | $completed | contains([$dep])))
    )] | first |
    if . then "\(.id)|\(.description)" else "" end
  ' "$WORKSPACE/$TASKS_JSON" 2>/dev/null
}

# Check if all tasks complete
is_complete() {
  [[ $(count_remaining) -eq 0 ]]
}

# =============================================================================
# LOGGING
# =============================================================================

log_activity() {
  local timestamp=$(date '+%H:%M:%S')
  echo "[$timestamp] $1" >> "$WORKSPACE/.ralph/activity.log"
}

log_progress() {
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo -e "\n### $timestamp\n$1" >> "$WORKSPACE/.ralph/progress.md"
}

# =============================================================================
# PROMPT BUILDING
# =============================================================================

build_prompt() {
  local iteration="$1"
  
  # Get next task info
  local next_task_info=$(get_next_task)
  local next_task_id=""
  local next_task_desc=""
  if [[ -n "$next_task_info" ]]; then
    next_task_id=$(echo "$next_task_info" | cut -d'|' -f1)
    next_task_desc=$(echo "$next_task_info" | cut -d'|' -f2-)
  fi
  
  # Build current task section with EXPECTED CRITERIA injected
  local current_task_section
  if [[ -n "$next_task_id" ]]; then
    # Extract expected criteria and steps from the task
    local task_details=$(jq -r --arg id "$next_task_id" '
      .[] | select(.id == $id) | 
      {
        steps: .steps,
        validation_note: .validation._note,
        validation_expected: .validation.expected,
        validation_commands: .validation.commands
      }
    ' "$WORKSPACE/$TASKS_JSON" 2>/dev/null)
    
    local expected_criteria=$(echo "$task_details" | jq -r '.validation_expected // "No criteria defined"')
    local validation_note=$(echo "$task_details" | jq -r '.validation_note // ""')
    local steps=$(echo "$task_details" | jq -r '.steps | join("\n- ")' 2>/dev/null)
    
    current_task_section="**Next task:** \`$next_task_id\` - $next_task_desc

**Steps to complete:**
- $steps

**Validation Intent:** $validation_note

**Expected Criteria (Success Looks Like):**
$expected_criteria

Get full task details with: \`jq '.[] | select(.id == \"$next_task_id\")' .ralph/tasks.json\`"
  else
    current_task_section="**No pending tasks with satisfied dependencies.**

Check if all tasks are complete or if there are dependency issues."
  fi
  
  # Read knowledge base (the agent's learning file)
  local knowledge_content=""
  local knowledge_file="$WORKSPACE/.ralph/knowledge.md"
  if [[ -f "$knowledge_file" ]]; then
    knowledge_content=$(cat "$knowledge_file")
  fi
  
  # Read recent progress for context
  local recent_progress=""
  local progress_file="$WORKSPACE/.ralph/progress.md"
  if [[ -f "$progress_file" ]]; then
    # Get last 50 lines of progress for recent context
    recent_progress=$(tail -50 "$progress_file" 2>/dev/null || cat "$progress_file")
  fi
  
  # Read prompt template from prompt.md
  local prompt_file="$SCRIPT_DIR/prompt.md"
  if [[ ! -f "$prompt_file" ]]; then
    echo "ERROR: prompt.md not found at $prompt_file" >&2
    exit 1
  fi
  
  # Read and substitute placeholders
  local prompt
  prompt=$(cat "$prompt_file")
  prompt="${prompt//\{\{ITERATION\}\}/$iteration}"
  prompt="${prompt//\{\{TASK_ID\}\}/$next_task_id}"
  prompt="${prompt//\{\{CURRENT_TASK\}\}/$current_task_section}"
  prompt="${prompt//\{\{KNOWLEDGE\}\}/$knowledge_content}"
  prompt="${prompt//\{\{RECENT_PROGRESS\}\}/$recent_progress}"
  
  echo "$prompt"
}

# =============================================================================
# STREAM PARSER (with beautiful live output)
# =============================================================================

# Extended color palette
C_RESET="\033[0m"
C_BOLD="\033[1m"
C_DIM="\033[2m"
C_ITALIC="\033[3m"
C_UNDERLINE="\033[4m"

# Foreground colors
C_BLACK="\033[30m"
C_RED="\033[31m"
C_GREEN="\033[32m"
C_YELLOW="\033[33m"
C_BLUE="\033[34m"
C_MAGENTA="\033[35m"
C_CYAN="\033[36m"
C_WHITE="\033[37m"

# Bright foreground colors
C_BRIGHT_BLACK="\033[90m"
C_BRIGHT_RED="\033[91m"
C_BRIGHT_GREEN="\033[92m"
C_BRIGHT_YELLOW="\033[93m"
C_BRIGHT_BLUE="\033[94m"
C_BRIGHT_MAGENTA="\033[95m"
C_BRIGHT_CYAN="\033[96m"
C_BRIGHT_WHITE="\033[97m"

# Background colors
C_BG_BLACK="\033[40m"
C_BG_RED="\033[41m"
C_BG_GREEN="\033[42m"
C_BG_YELLOW="\033[43m"
C_BG_BLUE="\033[44m"

# Unicode box drawing characters
BOX_TL="╭"  # Top left
BOX_TR="╮"  # Top right
BOX_BL="╰"  # Bottom left
BOX_BR="╯"  # Bottom right
BOX_H="─"   # Horizontal
BOX_V="│"   # Vertical
BOX_VR="├"  # Vertical and right
BOX_VL="┤"  # Vertical and left

# Icons (using Unicode)
ICON_READ="📄"
ICON_WRITE="✏️ "
ICON_EDIT="🔧"
ICON_SHELL="⚡"
ICON_SEARCH="🔍"
ICON_FOLDER="📁"
ICON_SUCCESS="✓"
ICON_ERROR="✗"
ICON_THINK="💭"
ICON_CHAT="💬"
ICON_WARN="⚠️ "
ICON_INFO="ℹ️ "
ICON_MCP="🔌"

# Get terminal width (default to 80 if not available)
get_term_width() {
  local width
  width=$(tput cols 2>/dev/null) || width=80
  echo "$width"
}

# Draw a horizontal line
draw_line() {
  local char="${1:-$BOX_H}"
  local width="${2:-$(get_term_width)}"
  local color="${3:-$C_DIM}"
  printf "${color}"
  printf '%*s' "$width" '' | tr ' ' "$char"
  printf "${C_RESET}\n"
}

# Draw a box header
draw_box_header() {
  local title="$1"
  local icon="$2"
  local color="${3:-$C_CYAN}"
  local width=$(($(get_term_width) - 2))
  
  printf "\n${color}${BOX_TL}"
  printf '%*s' "$width" '' | tr ' ' "$BOX_H"
  printf "${BOX_TR}${C_RESET}\n"
  printf "${color}${BOX_V}${C_RESET} ${icon} ${C_BOLD}${title}${C_RESET}\n"
}

# Draw a box footer
draw_box_footer() {
  local color="${1:-$C_CYAN}"
  local width=$(($(get_term_width) - 2))
  
  printf "${color}${BOX_BL}"
  printf '%*s' "$width" '' | tr ' ' "$BOX_H"
  printf "${BOX_BR}${C_RESET}\n"
}

# Format file path nicely
format_path() {
  local path="$1"
  local dir=$(dirname "$path")
  local file=$(basename "$path")
  
  if [[ "$dir" == "." ]]; then
    printf "${C_BRIGHT_WHITE}${C_BOLD}${file}${C_RESET}"
  else
    printf "${C_DIM}${dir}/${C_RESET}${C_BRIGHT_WHITE}${C_BOLD}${file}${C_RESET}"
  fi
}

# Format file size
format_size() {
  local bytes="$1"
  if [[ $bytes -lt 1024 ]]; then
    echo "${bytes}B"
  elif [[ $bytes -lt 1048576 ]]; then
    echo "$((bytes / 1024))KB"
  else
    echo "$((bytes / 1048576))MB"
  fi
}

# Print code with optional line numbers
print_code() {
  local content="$1"
  local show_line_numbers="${2:-false}"
  local max_lines="${3:-0}"
  local line_num=1
  local total_lines=$(echo "$content" | wc -l)
  
  while IFS= read -r code_line; do
    if [[ "$max_lines" -gt 0 ]] && [[ $line_num -gt $max_lines ]]; then
      printf "${C_DIM}   ... +%d more lines${C_RESET}\n" $((total_lines - max_lines))
      break
    fi
    
    if [[ "$show_line_numbers" == "true" ]]; then
      printf "${C_DIM}%4d │${C_RESET} %s\n" "$line_num" "$code_line"
    else
      printf "${C_DIM}  │${C_RESET} %s\n" "$code_line"
    fi
    ((line_num++))
  done <<< "$content"
}

# Print a diff (old vs new)
print_diff() {
  local old="$1"
  local new="$2"
  
  if [[ -n "$old" ]]; then
    printf "${C_RED}${C_DIM}  ┌─ removed${C_RESET}\n"
    while IFS= read -r line; do
      printf "${C_RED}  │ ${C_DIM}- %s${C_RESET}\n" "$line"
    done <<< "$old"
    printf "${C_RED}${C_DIM}  └─${C_RESET}\n"
  fi
  
  if [[ -n "$new" ]]; then
    printf "${C_GREEN}${C_DIM}  ┌─ added${C_RESET}\n"
    while IFS= read -r line; do
      printf "${C_GREEN}  │ + %s${C_RESET}\n" "$line"
    done <<< "$new"
    printf "${C_GREEN}${C_DIM}  └─${C_RESET}\n"
  fi
}

# Print status badge
print_status() {
  local status="$1"
  local message="$2"
  
  case "$status" in
    "success")
      printf "${C_GREEN}${ICON_SUCCESS} ${message}${C_RESET}"
      ;;
    "error")
      printf "${C_RED}${ICON_ERROR} ${message}${C_RESET}"
      ;;
    "warning")
      printf "${C_YELLOW}${ICON_WARN}${message}${C_RESET}"
      ;;
    "info")
      printf "${C_CYAN}${ICON_INFO}${message}${C_RESET}"
      ;;
  esac
}

# Parse cursor-agent stream-json output
# Streams content to stderr (visible), signals to stdout (for FIFO)
parse_stream() {
  local bytes_read=0
  local bytes_written=0
  local assistant_chars=0
  local shell_chars=0
  local warn_sent=0
  local current_text=""
  local in_thinking=0
  local tool_start_time=""

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    # Debug mode: show raw JSON
    if [[ "$DEBUG" == "true" ]]; then
      printf "${C_BRIGHT_BLACK}[RAW] %s${C_RESET}\n" "$line" >&2
    fi

    local type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null) || continue
    local subtype=$(echo "$line" | jq -r '.subtype // empty' 2>/dev/null) || subtype=""

    case "$type" in
      "system")
        if [[ "$subtype" == "init" ]]; then
          local model=$(echo "$line" | jq -r '.model // "unknown"' 2>/dev/null) || model="unknown"
          printf "\n${C_DIM}${BOX_VR}${BOX_H}${BOX_H} ${C_CYAN}Session${C_RESET}${C_DIM} │ Model: ${C_BRIGHT_CYAN}%s${C_RESET}\n" "$model" >&2
          log_activity "SESSION START: model=$model"
        fi
        ;;

      "thinking")
        if [[ "$subtype" == "delta" ]]; then
          local thought=$(echo "$line" | jq -r '.thinking.content // empty' 2>/dev/null) || thought=""
          if [[ -n "$thought" ]] && [[ $in_thinking -eq 0 ]]; then
            printf "\n${C_MAGENTA}${ICON_THINK} ${C_ITALIC}Thinking...${C_RESET}" >&2
            in_thinking=1
          fi
        elif [[ "$subtype" == "completed" ]]; then
          if [[ $in_thinking -eq 1 ]]; then
            printf " ${C_DIM}done${C_RESET}\n" >&2
            in_thinking=0
          fi
        fi
        ;;

      "assistant")
        in_thinking=0
        local text=$(echo "$line" | jq -r '.message.content[0].text // empty' 2>/dev/null) || text=""
        if [[ -n "$text" ]]; then
          assistant_chars=$((assistant_chars + ${#text}))

          # Beautiful assistant message box
          printf "\n" >&2
          printf "${C_BRIGHT_BLUE}${BOX_TL}${BOX_H}${BOX_H} ${ICON_CHAT} ${C_BOLD}Assistant${C_RESET}${C_BRIGHT_BLUE} ${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_TR}${C_RESET}\n" >&2
          printf "${C_BRIGHT_BLUE}${BOX_V}${C_RESET}\n" >&2
          # Print each line with box border
          while IFS= read -r msg_line; do
            printf "${C_BRIGHT_BLUE}${BOX_V}${C_RESET}  %s\n" "$msg_line" >&2
          done <<< "$text"
          printf "${C_BRIGHT_BLUE}${BOX_V}${C_RESET}\n" >&2
          printf "${C_BRIGHT_BLUE}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_BR}${C_RESET}\n" >&2
          log_activity "💬 ASSISTANT: ${text:0:200}..."

          # Check for completion signals
          if [[ "$text" == *"<ralph>COMPLETE</ralph>"* ]]; then
            printf "\n${C_BG_GREEN}${C_BLACK}${C_BOLD} ✓ COMPLETE ${C_RESET} ${C_GREEN}Agent signaled all tasks done${C_RESET}\n" >&2
            log_activity "✅ Agent signaled COMPLETE"
            echo "COMPLETE"
          elif [[ "$text" == *"<ralph>NEXT</ralph>"* ]]; then
            printf "\n${C_CYAN}${C_BOLD}→ NEXT${C_RESET} ${C_DIM}Task done, starting fresh iteration${C_RESET}\n" >&2
            log_activity "→ Agent signaled NEXT (task complete)"
            echo "NEXT"
          elif [[ "$text" == *"<ralph>GUTTER</ralph>"* ]]; then
            printf "\n${C_BG_RED}${C_WHITE}${C_BOLD} ✗ GUTTER ${C_RESET} ${C_RED}Agent is stuck - check errors.log${C_RESET}\n" >&2
            log_activity "🚨 Agent signaled GUTTER"
            echo "GUTTER"
          fi
        fi
        ;;

      "text")
        # Streaming text delta - print inline
        local delta=$(echo "$line" | jq -r '.content // empty' 2>/dev/null) || delta=""
        if [[ -n "$delta" ]]; then
          printf "${C_WHITE}%s${C_RESET}" "$delta" >&2
          current_text+="$delta"
        fi
        ;;

      "tool_call")
        # Clear any streaming text
        if [[ -n "$current_text" ]]; then
          echo "" >&2
          current_text=""
        fi

        if [[ "$subtype" == "started" ]]; then
          # macOS doesn't support %N, so we use seconds only
          tool_start_time=$(date +%s)
          
          # Detect tool type
          local tool_name=$(echo "$line" | jq -r '
            if .tool_call.readToolCall then "read"
            elif .tool_call.writeToolCall then "write"
            elif .tool_call.editToolCall then "edit"
            elif .tool_call.shellToolCall then "shell"
            elif .tool_call.searchToolCall then "search"
            elif .tool_call.globToolCall then "glob"
            elif .tool_call.grepToolCall then "grep"
            elif .tool_call.listFilesToolCall then "listFiles"
            elif .tool_call.mcpToolCall then "mcp"
            elif .tool_call.codeSearchToolCall then "codeSearch"
            else (.tool_call | keys[0] // "unknown")
            end
          ' 2>/dev/null) || tool_name="unknown"

          printf "\n" >&2
          
          case "$tool_name" in
            "read")
              local path=$(echo "$line" | jq -r '.tool_call.readToolCall.args.path // "?"' 2>/dev/null)
              printf "${C_CYAN}${BOX_TL}${BOX_H}${BOX_H} ${ICON_READ} Read${C_RESET}\n" >&2
              printf "${C_CYAN}${BOX_V}${C_RESET}  " >&2
              format_path "$path" >&2
              printf "\n" >&2
              ;;
            "write")
              local path=$(echo "$line" | jq -r '.tool_call.writeToolCall.args.path // "?"' 2>/dev/null)
              printf "${C_GREEN}${BOX_TL}${BOX_H}${BOX_H} ${ICON_WRITE}Write${C_RESET}\n" >&2
              printf "${C_GREEN}${BOX_V}${C_RESET}  " >&2
              format_path "$path" >&2
              printf "\n" >&2
              ;;
            "edit")
              local path=$(echo "$line" | jq -r '.tool_call.editToolCall.args.path // "?"' 2>/dev/null)
              printf "${C_YELLOW}${BOX_TL}${BOX_H}${BOX_H} ${ICON_EDIT} Edit${C_RESET}\n" >&2
              printf "${C_YELLOW}${BOX_V}${C_RESET}  " >&2
              format_path "$path" >&2
              printf "\n" >&2
              ;;
            "shell")
              local cmd=$(echo "$line" | jq -r '.tool_call.shellToolCall.args.command // "?"' 2>/dev/null)
              printf "${C_BRIGHT_MAGENTA}${BOX_TL}${BOX_H}${BOX_H} ${ICON_SHELL} Shell${C_RESET}\n" >&2
              printf "${C_BRIGHT_MAGENTA}${BOX_V}${C_RESET}  ${C_BRIGHT_WHITE}$ %s${C_RESET}\n" "$cmd" >&2
              ;;
            "search"|"glob"|"grep"|"codeSearch")
              local pattern=""
              if [[ "$tool_name" == "grep" ]]; then
                pattern=$(echo "$line" | jq -r '.tool_call.grepToolCall.args.pattern // "?"' 2>/dev/null)
              elif [[ "$tool_name" == "glob" ]]; then
                pattern=$(echo "$line" | jq -r '.tool_call.globToolCall.args.pattern // "?"' 2>/dev/null)
              fi
              printf "${C_BRIGHT_CYAN}${BOX_TL}${BOX_H}${BOX_H} ${ICON_SEARCH} Search${C_RESET}\n" >&2
              [[ -n "$pattern" ]] && printf "${C_BRIGHT_CYAN}${BOX_V}${C_RESET}  ${C_DIM}Pattern:${C_RESET} %s\n" "$pattern" >&2
              ;;
            "listFiles")
              local path=$(echo "$line" | jq -r '.tool_call.listFilesToolCall.args.path // "?"' 2>/dev/null)
              printf "${C_DIM}${BOX_TL}${BOX_H}${BOX_H} ${ICON_FOLDER} List${C_RESET}\n" >&2
              printf "${C_DIM}${BOX_V}${C_RESET}  " >&2
              format_path "$path" >&2
              printf "\n" >&2
              ;;
            "mcp")
              local server=$(echo "$line" | jq -r '.tool_call.mcpToolCall.args.server // "?"' 2>/dev/null)
              local tool=$(echo "$line" | jq -r '.tool_call.mcpToolCall.args.tool // "?"' 2>/dev/null)
              printf "${C_BRIGHT_YELLOW}${BOX_TL}${BOX_H}${BOX_H} ${ICON_MCP} MCP${C_RESET}\n" >&2
              printf "${C_BRIGHT_YELLOW}${BOX_V}${C_RESET}  ${C_DIM}%s${C_RESET} → ${C_BRIGHT_WHITE}%s${C_RESET}\n" "$server" "$tool" >&2
              ;;
            *)
              printf "${C_DIM}${BOX_TL}${BOX_H}${BOX_H} 🔧 %s${C_RESET}\n" "$tool_name" >&2
              if [[ "$VERBOSE" == "true" ]]; then
                local args=$(echo "$line" | jq -c '.tool_call | to_entries[0].value.args // {}' 2>/dev/null)
                printf "${C_DIM}${BOX_V}  Args: %s${C_RESET}\n" "$args" >&2
              fi
              ;;
          esac

        elif [[ "$subtype" == "completed" ]]; then
          # Calculate duration (in seconds, macOS doesn't support ms precision)
          local duration_sec=""
          if [[ -n "$tool_start_time" ]]; then
            local end_time=$(date +%s)
            duration_sec=$((end_time - tool_start_time))
          fi

          # Read tool
          if echo "$line" | jq -e '.tool_call.readToolCall.result.success' > /dev/null 2>&1; then
            local path=$(echo "$line" | jq -r '.tool_call.readToolCall.args.path // "?"' 2>/dev/null)
            local lines=$(echo "$line" | jq -r '.tool_call.readToolCall.result.success.totalLines // 0' 2>/dev/null)
            local size=$(echo "$line" | jq -r '.tool_call.readToolCall.result.success.contentSize // 0' 2>/dev/null)
            local content=$(echo "$line" | jq -r '.tool_call.readToolCall.result.success.content // ""' 2>/dev/null)
            bytes_read=$((bytes_read + size))
            
            printf "${C_CYAN}${BOX_V}${C_RESET}  ${C_GREEN}${ICON_SUCCESS}${C_RESET} ${C_DIM}%d lines${C_RESET} ${C_BRIGHT_BLACK}(%s)${C_RESET}" "$lines" "$(format_size $size)" >&2
            [[ -n "$duration_sec" ]] && [[ "$duration_sec" -gt 0 ]] && printf " ${C_BRIGHT_BLACK}%ds${C_RESET}" "$duration_sec" >&2
            printf "\n" >&2
            printf "${C_CYAN}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${C_RESET}\n" >&2
            log_activity "READ $path ($lines lines, $(format_size $size))"

            # Show content in verbose mode with line numbers
            if [[ "$VERBOSE" == "true" ]] && [[ -n "$content" ]]; then
              printf "${C_DIM}  ┌─ content ─────────────────────────────────${C_RESET}\n" >&2
              print_code "$content" "true" >&2
              printf "${C_DIM}  └────────────────────────────────────────────${C_RESET}\n" >&2
            fi

          # Write tool
          elif echo "$line" | jq -e '.tool_call.writeToolCall.result.success' > /dev/null 2>&1; then
            local path=$(echo "$line" | jq -r '.tool_call.writeToolCall.args.path // "?"' 2>/dev/null)
            local lines=$(echo "$line" | jq -r '.tool_call.writeToolCall.result.success.linesCreated // 0' 2>/dev/null)
            local size=$(echo "$line" | jq -r '.tool_call.writeToolCall.result.success.fileSize // 0' 2>/dev/null)
            local content=$(echo "$line" | jq -r '.tool_call.writeToolCall.args.content // ""' 2>/dev/null)
            bytes_written=$((bytes_written + size))
            
            printf "${C_GREEN}${BOX_V}${C_RESET}  ${C_GREEN}${ICON_SUCCESS}${C_RESET} ${C_DIM}Created %d lines${C_RESET} ${C_BRIGHT_BLACK}(%s)${C_RESET}" "$lines" "$(format_size $size)" >&2
            [[ -n "$duration_sec" ]] && [[ "$duration_sec" -gt 0 ]] && printf " ${C_BRIGHT_BLACK}%ds${C_RESET}" "$duration_sec" >&2
            printf "\n" >&2
            printf "${C_GREEN}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${C_RESET}\n" >&2
            log_activity "WRITE $path ($lines lines, $(format_size $size))"

            # Show content in verbose mode with line numbers
            if [[ "$VERBOSE" == "true" ]] && [[ -n "$content" ]]; then
              printf "${C_GREEN}  ┌─ content ─────────────────────────────────${C_RESET}\n" >&2
              print_code "$content" "true" >&2
              printf "${C_GREEN}  └────────────────────────────────────────────${C_RESET}\n" >&2
            fi

          # Edit tool
          elif echo "$line" | jq -e '.tool_call.editToolCall.result.success' > /dev/null 2>&1; then
            local path=$(echo "$line" | jq -r '.tool_call.editToolCall.args.path // "?"' 2>/dev/null)
            local old_str=$(echo "$line" | jq -r '.tool_call.editToolCall.args.oldString // ""' 2>/dev/null)
            local new_str=$(echo "$line" | jq -r '.tool_call.editToolCall.args.newString // ""' 2>/dev/null)
            
            printf "${C_YELLOW}${BOX_V}${C_RESET}  ${C_GREEN}${ICON_SUCCESS}${C_RESET} ${C_DIM}Edit applied${C_RESET}" >&2
            [[ -n "$duration_sec" ]] && [[ "$duration_sec" -gt 0 ]] && printf " ${C_BRIGHT_BLACK}%ds${C_RESET}" "$duration_sec" >&2
            printf "\n" >&2
            printf "${C_YELLOW}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${C_RESET}\n" >&2
            log_activity "EDIT $path"

            # Show diff in verbose mode with beautiful formatting
            if [[ "$VERBOSE" == "true" ]]; then
              print_diff "$old_str" "$new_str" >&2
            fi

          # Shell tool
          elif echo "$line" | jq -e '.tool_call.shellToolCall.result' > /dev/null 2>&1; then
            local cmd=$(echo "$line" | jq -r '.tool_call.shellToolCall.args.command // "?"' 2>/dev/null)
            local exit_code=$(echo "$line" | jq -r '.tool_call.shellToolCall.result.exitCode // 0' 2>/dev/null)
            local stdout=$(echo "$line" | jq -r '.tool_call.shellToolCall.result.stdout // ""' 2>/dev/null)
            local stderr=$(echo "$line" | jq -r '.tool_call.shellToolCall.result.stderr // ""' 2>/dev/null)

            shell_chars=$((shell_chars + ${#stdout} + ${#stderr}))

            if [[ $exit_code -eq 0 ]]; then
              printf "${C_BRIGHT_MAGENTA}${BOX_V}${C_RESET}  ${C_GREEN}${ICON_SUCCESS} Exit 0${C_RESET}" >&2
            else
              printf "${C_BRIGHT_MAGENTA}${BOX_V}${C_RESET}  ${C_RED}${ICON_ERROR} Exit %d${C_RESET}" "$exit_code" >&2
            fi
            [[ -n "$duration_sec" ]] && [[ "$duration_sec" -gt 0 ]] && printf " ${C_BRIGHT_BLACK}%ds${C_RESET}" "$duration_sec" >&2
            printf "\n" >&2

            # Show output with beautiful formatting
            if [[ -n "$stdout" ]]; then
              if [[ "$VERBOSE" == "true" ]] || [[ ${#stdout} -le 500 ]]; then
                printf "${C_BRIGHT_MAGENTA}${BOX_V}${C_RESET}  ${C_DIM}┌─ stdout ────────────────────────────────${C_RESET}\n" >&2
                while IFS= read -r out_line; do
                  printf "${C_BRIGHT_MAGENTA}${BOX_V}${C_RESET}  ${C_DIM}│${C_RESET} %s\n" "$out_line" >&2
                done <<< "$stdout"
                printf "${C_BRIGHT_MAGENTA}${BOX_V}${C_RESET}  ${C_DIM}└──────────────────────────────────────────${C_RESET}\n" >&2
              else
                printf "${C_BRIGHT_MAGENTA}${BOX_V}${C_RESET}  ${C_DIM}stdout: %d chars (use -v to see full)${C_RESET}\n" "${#stdout}" >&2
              fi
            fi
            
            if [[ -n "$stderr" ]]; then
              if [[ $exit_code -ne 0 ]] || [[ "$VERBOSE" == "true" ]]; then
                printf "${C_BRIGHT_MAGENTA}${BOX_V}${C_RESET}  ${C_RED}┌─ stderr ────────────────────────────────${C_RESET}\n" >&2
                while IFS= read -r err_line; do
                  printf "${C_BRIGHT_MAGENTA}${BOX_V}${C_RESET}  ${C_RED}│ %s${C_RESET}\n" "$err_line" >&2
                done <<< "$stderr"
                printf "${C_BRIGHT_MAGENTA}${BOX_V}${C_RESET}  ${C_RED}└──────────────────────────────────────────${C_RESET}\n" >&2
              fi
            fi
            
            printf "${C_BRIGHT_MAGENTA}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${C_RESET}\n" >&2
            log_activity "SHELL $cmd → exit $exit_code"

          # Search/Glob/Grep results
          elif echo "$line" | jq -e '.tool_call.searchToolCall.result // .tool_call.globToolCall.result // .tool_call.grepToolCall.result' > /dev/null 2>&1; then
            local results=$(echo "$line" | jq -r '
              .tool_call.searchToolCall.result.files // 
              .tool_call.globToolCall.result.files // 
              .tool_call.grepToolCall.result.matches // 
              [] | length
            ' 2>/dev/null) || results=0
            
            printf "${C_BRIGHT_CYAN}${BOX_V}${C_RESET}  ${C_GREEN}${ICON_SUCCESS}${C_RESET} ${C_DIM}Found ${C_BRIGHT_WHITE}%d${C_DIM} results${C_RESET}" "$results" >&2
            [[ -n "$duration_sec" ]] && [[ "$duration_sec" -gt 0 ]] && printf " ${C_BRIGHT_BLACK}%ds${C_RESET}" "$duration_sec" >&2
            printf "\n" >&2

            # Show results in verbose mode with beautiful formatting
            if [[ "$VERBOSE" == "true" ]]; then
              local result_list=$(echo "$line" | jq -r '
                (.tool_call.searchToolCall.result.files // 
                 .tool_call.globToolCall.result.files // 
                 []) | .[]
              ' 2>/dev/null)
              if [[ -n "$result_list" ]]; then
                printf "${C_BRIGHT_CYAN}${BOX_V}${C_RESET}  ${C_DIM}┌─ files ─────────────────────────────────${C_RESET}\n" >&2
                while IFS= read -r file; do
                  printf "${C_BRIGHT_CYAN}${BOX_V}${C_RESET}  ${C_DIM}│${C_RESET} ${ICON_READ} %s\n" "$file" >&2
                done <<< "$result_list"
                printf "${C_BRIGHT_CYAN}${BOX_V}${C_RESET}  ${C_DIM}└──────────────────────────────────────────${C_RESET}\n" >&2
              fi
              
              # Also show grep match content if available
              local grep_matches=$(echo "$line" | jq -r '
                .tool_call.grepToolCall.result.matches // [] | .[] | 
                "\(.file):\(.line): \(.content)"
              ' 2>/dev/null)
              if [[ -n "$grep_matches" ]]; then
                printf "${C_BRIGHT_CYAN}${BOX_V}${C_RESET}  ${C_DIM}┌─ matches ───────────────────────────────${C_RESET}\n" >&2
                while IFS= read -r match; do
                  printf "${C_BRIGHT_CYAN}${BOX_V}${C_RESET}  ${C_DIM}│${C_RESET} %s\n" "$match" >&2
                done <<< "$grep_matches"
                printf "${C_BRIGHT_CYAN}${BOX_V}${C_RESET}  ${C_DIM}└──────────────────────────────────────────${C_RESET}\n" >&2
              fi
            fi
            
            printf "${C_BRIGHT_CYAN}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${C_RESET}\n" >&2

          # Read tool error
          elif echo "$line" | jq -e '.tool_call.readToolCall.result.error' > /dev/null 2>&1; then
            local err=$(echo "$line" | jq -r '.tool_call.readToolCall.result.error // "unknown"' 2>/dev/null)
            printf "${C_CYAN}${BOX_V}${C_RESET}  ${C_RED}${ICON_ERROR} Read failed: %s${C_RESET}\n" "$err" >&2
            printf "${C_CYAN}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${C_RESET}\n" >&2

          # Generic tool error
          elif echo "$line" | jq -e '.tool_call | .. | .error? // empty | select(. != null)' > /dev/null 2>&1; then
            local tool_key=$(echo "$line" | jq -r '.tool_call | keys[0] // "unknown"' 2>/dev/null)
            printf "${C_DIM}${BOX_V}${C_RESET}  ${C_RED}${ICON_ERROR} Tool failed${C_RESET}\n" >&2
            printf "${C_DIM}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${C_RESET}\n" >&2

          # Unknown tool result - show in verbose mode
          elif [[ "$VERBOSE" == "true" ]]; then
            local tool_key=$(echo "$line" | jq -r '.tool_call | keys[0] // "unknown"' 2>/dev/null)
            printf "${C_DIM}${BOX_V}${C_RESET}  ${C_GREEN}${ICON_SUCCESS}${C_RESET} ${C_DIM}%s completed${C_RESET}\n" "$tool_key" >&2
            # Show full result in debug mode
            if [[ "$DEBUG" == "true" ]]; then
              local result=$(echo "$line" | jq -c '.tool_call | to_entries[0].value.result // {}' 2>/dev/null)
              printf "${C_DIM}${BOX_V}${C_RESET}  ${C_DIM}Result: %s${C_RESET}\n" "$result" >&2
            fi
            printf "${C_DIM}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${C_RESET}\n" >&2
          fi

          # Check token threshold after each tool call
          local total_chars=$((bytes_read + bytes_written + assistant_chars + shell_chars + 3000))
          local tokens=$((total_chars / 4))

          if [[ $tokens -ge $ROTATE_THRESHOLD ]]; then
            printf "\n${C_BG_YELLOW}${C_BLACK}${C_BOLD} 🔄 CONTEXT ROTATION ${C_RESET} ${C_YELLOW}Token threshold reached (%d tokens)${C_RESET}\n" "$tokens" >&2
            log_activity "🔄 Token threshold reached ($tokens)"
            echo "ROTATE"
          elif [[ $tokens -ge $WARN_THRESHOLD ]] && [[ $warn_sent -eq 0 ]]; then
            printf "\n${C_YELLOW}${ICON_WARN}Approaching token limit (%d tokens)${C_RESET}\n" "$tokens" >&2
            log_activity "⚠️ Approaching token limit ($tokens)"
            warn_sent=1
            echo "WARN"
          fi
        fi
        ;;

      "error")
        local error_msg=$(echo "$line" | jq -r '.error.data.message // .error.message // .message // "Unknown error"' 2>/dev/null) || error_msg="Unknown"
        
        printf "\n" >&2
        printf "${C_BG_RED}${C_WHITE}${C_BOLD}  ERROR  ${C_RESET}\n" >&2
        printf "${C_RED}${BOX_TL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_TR}${C_RESET}\n" >&2
        printf "${C_RED}${BOX_V}${C_RESET} %s\n" "$error_msg" >&2
        printf "${C_RED}${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_BR}${C_RESET}\n" >&2
        log_activity "❌ ERROR: $error_msg"

        # Check for retryable errors
        if [[ "$error_msg" =~ (rate.?limit|429|timeout|connection|503|502|504|overloaded) ]]; then
          echo "DEFER"
        else
          echo "GUTTER"
        fi
        ;;

      "result")
        local duration=$(echo "$line" | jq -r '.duration_ms // 0' 2>/dev/null)
        local total_chars=$((bytes_read + bytes_written + assistant_chars + shell_chars + 3000))
        local tokens=$((total_chars / 4))
        
        printf "\n" >&2
        printf "${C_DIM}${BOX_BL}${BOX_H}${BOX_H} Session Complete ${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${C_RESET}\n" >&2
        printf "${C_DIM}  Duration: ${C_BRIGHT_WHITE}%dms${C_RESET}${C_DIM}  │  Tokens: ${C_BRIGHT_WHITE}~%d${C_RESET}\n" "$duration" "$tokens" >&2
        log_activity "SESSION END: ${duration}ms, ~$tokens tokens"
        ;;

      *)
        # Unknown event type - show in verbose/debug mode
        if [[ "$VERBOSE" == "true" ]] && [[ -n "$type" ]]; then
          printf "${C_BRIGHT_BLACK}[unknown event: %s/%s]${C_RESET}\n" "$type" "$subtype" >&2
        fi
        ;;
    esac
  done

  echo "DONE"
}

# =============================================================================
# ITERATION RUNNER
# =============================================================================

run_iteration() {
  local iteration="$1"
  local prompt=$(build_prompt "$iteration")
  local completed=$(count_completed)
  local total=$(count_total)
  local remaining=$((total - completed))
  
  # Calculate progress bar
  local progress_pct=0
  [[ $total -gt 0 ]] && progress_pct=$((completed * 100 / total))
  local bar_width=30
  local filled=$((progress_pct * bar_width / 100))
  local empty=$((bar_width - filled))

  echo ""
  printf "${C_BRIGHT_CYAN}╔════════════════════════════════════════════════════════════════════╗${C_RESET}\n"
  printf "${C_BRIGHT_CYAN}║${C_RESET}  ${C_BOLD}🐛 Ralph Wiggum${C_RESET} ${C_DIM}│${C_RESET} Iteration ${C_BRIGHT_WHITE}${C_BOLD}%d${C_RESET}                                    ${C_BRIGHT_CYAN}║${C_RESET}\n" "$iteration"
  printf "${C_BRIGHT_CYAN}╠════════════════════════════════════════════════════════════════════╣${C_RESET}\n"
  printf "${C_BRIGHT_CYAN}║${C_RESET}  ${C_DIM}Model:${C_RESET}     ${C_BRIGHT_WHITE}%-45s${C_RESET}       ${C_BRIGHT_CYAN}║${C_RESET}\n" "$MODEL"
  printf "${C_BRIGHT_CYAN}║${C_RESET}  ${C_DIM}Progress:${C_RESET}  ${C_GREEN}%d${C_RESET}/${C_BRIGHT_WHITE}%d${C_RESET} tasks ${C_DIM}(%d remaining)${C_RESET}                          ${C_BRIGHT_CYAN}║${C_RESET}\n" "$completed" "$total" "$remaining"
  printf "${C_BRIGHT_CYAN}║${C_RESET}  ${C_DIM}Status:${C_RESET}    [${C_GREEN}%s${C_RESET}${C_DIM}%s${C_RESET}] ${C_BRIGHT_WHITE}%d%%${C_RESET}                              ${C_BRIGHT_CYAN}║${C_RESET}\n" "$(printf '█%.0s' $(seq 1 $filled 2>/dev/null) 2>/dev/null)" "$(printf '░%.0s' $(seq 1 $empty 2>/dev/null) 2>/dev/null)" "$progress_pct"
  printf "${C_BRIGHT_CYAN}╚════════════════════════════════════════════════════════════════════╝${C_RESET}\n"
  echo ""

  log_activity "SESSION $iteration START: model=$MODEL"
  log_progress "**Session $iteration started** (model: $MODEL)"

  # Capture knowledge state BEFORE iteration
  local knowledge_before=""
  if [[ -f "$WORKSPACE/.ralph/knowledge.md" ]]; then
    knowledge_before=$(md5 -q "$WORKSPACE/.ralph/knowledge.md" 2>/dev/null || md5sum "$WORKSPACE/.ralph/knowledge.md" | cut -d' ' -f1)
  fi

  # Run cursor-agent and parse output
  local signal=""
  local fifo="$WORKSPACE/.ralph/.parser_fifo_$$"

  rm -f "$fifo"
  mkfifo "$fifo"

  # Start agent, pipe through parser
  (
    cd "$WORKSPACE"
    cursor-agent -p --force --output-format stream-json --model "$MODEL" "$prompt" 2>&1 | parse_stream > "$fifo"
  ) &
  local agent_pid=$!

  # Read signals from parser
  while IFS= read -r line; do
    case "$line" in
      COMPLETE|GUTTER|ROTATE|DEFER|NEXT)
        signal="$line"
        kill $agent_pid 2>/dev/null || true
        break
        ;;
      WARN)
        echo "⚠️ Context warning - agent should wrap up soon..."
        ;;
      DONE)
        signal="DONE"
        break
        ;;
    esac
  done < "$fifo"

  wait $agent_pid 2>/dev/null || true
  rm -f "$fifo"

  # Check if knowledge was updated AFTER iteration
  local knowledge_after=""
  local learning_logged=false
  
  if [[ -f "$WORKSPACE/.ralph/knowledge.md" ]]; then
    knowledge_after=$(md5 -q "$WORKSPACE/.ralph/knowledge.md" 2>/dev/null || md5sum "$WORKSPACE/.ralph/knowledge.md" | cut -d' ' -f1)
  fi

  # Log if knowledge.md was updated
  if [[ -n "$knowledge_before" ]] && [[ -n "$knowledge_after" ]] && [[ "$knowledge_before" != "$knowledge_after" ]]; then
    # Extract what sections were updated
    local knowledge_changes=$(git -C "$WORKSPACE" diff .ralph/knowledge.md 2>/dev/null | grep "^+[^+]" | head -5 | sed 's/^+//' || echo "knowledge updated")
    printf "\n${C_GREEN}${ICON_SUCCESS} Knowledge updated:${C_RESET}\n"
    echo "$knowledge_changes" | while read -r line; do
      printf "  ${C_DIM}+${C_RESET} ${C_BRIGHT_WHITE}%s${C_RESET}\n" "$line"
    done
    log_activity "🧠 LEARNED: knowledge.md updated"
    log_progress "**Knowledge base updated** - agent added new learnings"
    learning_logged=true
  elif [[ -z "$knowledge_before" ]] && [[ -n "$knowledge_after" ]]; then
    printf "\n${C_GREEN}${ICON_SUCCESS} Knowledge base created${C_RESET}\n"
    log_activity "🧠 Knowledge base initialized"
    learning_logged=true
  fi

  # Warn if no learning was logged (agent should be learning something)
  if [[ "$learning_logged" == "false" ]] && [[ "$signal" != "COMPLETE" ]]; then
    printf "\n${C_DIM}💡 Tip: Agent didn't update knowledge.md this iteration. Learning improves future runs.${C_RESET}\n"
  fi

  echo "$signal"
}

# =============================================================================
# MAIN LOOP
# =============================================================================

run_loop() {
  # Commit uncommitted changes
  cd "$WORKSPACE"
  if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    printf "${C_DIM}📦 Committing uncommitted changes...${C_RESET}\n"
    git add -A
    git commit -m "ralph: initial commit before loop" || true
  fi

  # Create branch if requested
  if [[ -n "$BRANCH" ]]; then
    printf "${C_CYAN}🌿 Creating branch: ${C_BRIGHT_WHITE}%s${C_RESET}\n" "$BRANCH"
    git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
  fi

  echo ""
  printf "${C_BRIGHT_GREEN}🚀 Starting Ralph loop...${C_RESET}\n"
  printf "${C_DIM}   Tasks: ${C_GREEN}%d${C_DIM}/${C_BRIGHT_WHITE}%d${C_DIM} complete${C_RESET}\n" "$(count_completed)" "$(count_total)"
  echo ""

  local iteration=1
  local current_task_id=""  # Track current task for session rotation on task change

  while [[ $iteration -le $MAX_ITERATIONS ]]; do
    # Check if already complete
    if is_complete; then
      echo ""
      printf "${C_BG_GREEN}${C_BLACK}${C_BOLD}                                                                       ${C_RESET}\n"
      printf "${C_BG_GREEN}${C_BLACK}${C_BOLD}  🎉 RALPH COMPLETE!                                                   ${C_RESET}\n"
      printf "${C_BG_GREEN}${C_BLACK}${C_BOLD}  All tasks done.                                                      ${C_RESET}\n"
      printf "${C_BG_GREEN}${C_BLACK}${C_BOLD}                                                                       ${C_RESET}\n"
      log_progress "**COMPLETE** after $iteration iterations"
      open_pr_if_requested
      return 0
    fi

    # Check if task has changed - if so, start a new session
    local next_task_info=$(get_next_task)
    local next_task_id=""
    if [[ -n "$next_task_info" ]]; then
      next_task_id=$(echo "$next_task_info" | cut -d'|' -f1)
    fi
    
    if [[ -n "$current_task_id" ]] && [[ -n "$next_task_id" ]] && [[ "$current_task_id" != "$next_task_id" ]]; then
      printf "\n${C_CYAN}📋 New task detected: ${C_BRIGHT_WHITE}%s${C_RESET} ${C_DIM}(was: %s)${C_RESET}\n" "$next_task_id" "$current_task_id"
      printf "${C_CYAN}🔄 Starting fresh session for new task...${C_RESET}\n"
      log_progress "**Session $iteration ended** - 📋 New task: $next_task_id (was: $current_task_id)"
      log_activity "NEW TASK: $next_task_id (previous: $current_task_id) - starting fresh session"
      iteration=$((iteration + 1))
    fi
    
    # Update current task tracker
    current_task_id="$next_task_id"

    # Run iteration
    local signal=$(run_iteration "$iteration")

    # Check completion after iteration
    if is_complete; then
      echo ""
      printf "${C_BG_GREEN}${C_BLACK}${C_BOLD}                                                                       ${C_RESET}\n"
      printf "${C_BG_GREEN}${C_BLACK}${C_BOLD}  🎉 RALPH COMPLETE!                                                   ${C_RESET}\n"
      printf "${C_BG_GREEN}${C_BLACK}${C_BOLD}  All tasks done in %d iterations.                                     ${C_RESET}\n" "$iteration"
      printf "${C_BG_GREEN}${C_BLACK}${C_BOLD}                                                                       ${C_RESET}\n"
      log_progress "**COMPLETE** after $iteration iterations"
      open_pr_if_requested
      return 0
    fi

    # Handle signal
    case "$signal" in
      COMPLETE)
        if is_complete; then
          log_progress "**Session $iteration ended** - ✅ COMPLETE"
          open_pr_if_requested
          return 0
        else
          printf "${C_YELLOW}${ICON_WARN}Agent signaled complete but tasks remain. Continuing...${C_RESET}\n"
          iteration=$((iteration + 1))
        fi
        ;;
      NEXT)
        # Agent completed one task and signaled for fresh context
        log_progress "**Session $iteration ended** - → NEXT (task complete, fresh context)"
        printf "\n${C_CYAN}→ Starting fresh iteration...${C_RESET}\n"
        iteration=$((iteration + 1))
        ;;
      ROTATE)
        log_progress "**Session $iteration ended** - 🔄 Context rotation (token threshold)"
        printf "\n${C_CYAN}🔄 Rotating to fresh context (token threshold reached)...${C_RESET}\n"
        iteration=$((iteration + 1))
        ;;
      GUTTER)
        log_progress "**Session $iteration ended** - 🚨 GUTTER"
        printf "\n${C_BG_RED}${C_WHITE}${C_BOLD} 🚨 GUTTER ${C_RESET} ${C_RED}Agent is stuck. Check ${C_UNDERLINE}.ralph/errors.log${C_RESET}\n"
        return 1
        ;;
      DEFER)
        log_progress "**Session $iteration ended** - ⏸️ Rate limit/error"
        local delay=$((15 * iteration))
        [[ $delay -gt 120 ]] && delay=120
        printf "\n${C_YELLOW}⏸️  Rate limit detected. Waiting ${C_BRIGHT_WHITE}%ds${C_RESET}${C_YELLOW}...${C_RESET}\n" "$delay"
        sleep $delay
        # Don't increment - retry same iteration
        ;;
      *)
        # Agent finished without explicit signal - continue anyway
        local remaining=$(count_remaining)
        if [[ $remaining -gt 0 ]]; then
          log_progress "**Session $iteration ended** - $remaining tasks remaining (no signal)"
          printf "\n${C_YELLOW}${ICON_WARN}Agent ended without signal. ${C_BRIGHT_WHITE}%d${C_YELLOW} tasks remaining. Continuing...${C_RESET}\n" "$remaining"
          iteration=$((iteration + 1))
        fi
        ;;
    esac

    sleep 2
  done

  log_progress "**Loop ended** - ⚠️ Max iterations reached"
  printf "\n${C_YELLOW}${ICON_WARN}Max iterations (${C_BRIGHT_WHITE}%d${C_YELLOW}) reached.${C_RESET}\n" "$MAX_ITERATIONS"
  return 1
}

open_pr_if_requested() {
  if [[ "$OPEN_PR" == "true" ]] && [[ -n "$BRANCH" ]]; then
    echo ""
    echo "📝 Opening pull request..."
    cd "$WORKSPACE"
    git push -u origin "$BRANCH" 2>/dev/null || git push
    if command -v gh &> /dev/null; then
      gh pr create --fill || echo "⚠️ Could not create PR automatically."
    else
      echo "⚠️ gh CLI not found. Create PR manually."
    fi
  fi
}

# =============================================================================
# MAIN
# =============================================================================

main() {
  parse_args "$@"

  # Resolve workspace path
  WORKSPACE="$(cd "$WORKSPACE" && pwd)"

  # Show beautiful banner
  echo ""
  printf "${C_BRIGHT_CYAN}"
  echo "╔═══════════════════════════════════════════════════════════════════╗"
  echo "║                                                                   ║"
  echo "║   🐛  Ralph Wiggum: Autonomous Development Loop                   ║"
  echo "║                                                                   ║"
  echo "╚═══════════════════════════════════════════════════════════════════╝"
  printf "${C_RESET}\n"

  # Init only mode
  if [[ "$INIT_ONLY" == "true" ]]; then
    init_ralph
    exit 0
  fi

  # Check prerequisites
  if ! check_prerequisites; then
    exit 1
  fi

  # Initialize .ralph directory
  init_ralph

  # Show task summary with beautiful formatting
  local completed=$(count_completed)
  local total=$(count_total)
  local remaining=$((total - completed))
  
  printf "${C_DIM}┌─────────────────────────────────────────────────────────────────────┐${C_RESET}\n"
  printf "${C_DIM}│${C_RESET}  ${C_DIM}Workspace:${C_RESET}   ${C_BRIGHT_WHITE}%s${C_RESET}\n" "$WORKSPACE"
  printf "${C_DIM}│${C_RESET}  ${C_DIM}Model:${C_RESET}       ${C_BRIGHT_CYAN}%s${C_RESET}\n" "$MODEL"
  printf "${C_DIM}│${C_RESET}  ${C_DIM}Iterations:${C_RESET}  ${C_BRIGHT_WHITE}%d${C_RESET} ${C_DIM}max${C_RESET}\n" "$MAX_ITERATIONS"
  [[ -n "$BRANCH" ]] && printf "${C_DIM}│${C_RESET}  ${C_DIM}Branch:${C_RESET}      ${C_BRIGHT_GREEN}%s${C_RESET}\n" "$BRANCH"
  [[ "$OPEN_PR" == "true" ]] && printf "${C_DIM}│${C_RESET}  ${C_DIM}Open PR:${C_RESET}     ${C_GREEN}Yes${C_RESET}\n"
  [[ "$DEBUG" == "true" ]] && printf "${C_DIM}│${C_RESET}  ${C_DIM}Debug:${C_RESET}       ${C_YELLOW}Yes${C_RESET} ${C_DIM}(raw JSON)${C_RESET}\n"
  [[ "$VERBOSE" == "true" ]] && [[ "$DEBUG" != "true" ]] && printf "${C_DIM}│${C_RESET}  ${C_DIM}Verbose:${C_RESET}     ${C_GREEN}Yes${C_RESET} ${C_DIM}(full outputs)${C_RESET}\n"
  printf "${C_DIM}├─────────────────────────────────────────────────────────────────────┤${C_RESET}\n"
  printf "${C_DIM}│${C_RESET}  ${C_DIM}Tasks:${C_RESET}       ${C_GREEN}%d${C_RESET}/${C_BRIGHT_WHITE}%d${C_RESET} complete ${C_DIM}(%d remaining)${C_RESET}\n" "$completed" "$total" "$remaining"
  printf "${C_DIM}└─────────────────────────────────────────────────────────────────────┘${C_RESET}\n"
  echo ""

  # Check if already complete
  if is_complete && [[ $(count_total) -gt 0 ]]; then
    printf "${C_GREEN}🎉 All tasks already complete!${C_RESET}\n"
    exit 0
  fi

  # Run the loop
  run_loop
}

main "$@"
