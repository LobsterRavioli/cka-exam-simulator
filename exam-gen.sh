#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOPICS_DIR="$SCRIPT_DIR/topics"
EXAMS_DIR="$SCRIPT_DIR/exams"

usage() {
  cat <<'EOF'
Usage: exam-gen.sh <exam-type> [--seed <n>]

  exam-type   cka-prep-2025-v2 | dumbitguy | itkiddie
  --seed <n>  integer seed for reproducible random selection

Examples:
  ./exam-gen.sh cka-prep-2025-v2
  ./exam-gen.sh dumbitguy --seed 42
  ./exam-gen.sh itkiddie --seed 7
EOF
  exit 1
}

get_domain() {
  case "$1" in
    01-storage-pv-pvc|02-storage-storageclass)
      echo "Storage (10%)" ;;
    03-networking-services|04-networking-ingress|05-networking-gateway|06-networking-networkpolicy|07-networking-cni)
      echo "Services & Networking (20%)" ;;
    08-workloads-deployments|09-workloads-sidecar|10-workloads-resources|11-workloads-hpa|12-workloads-scheduling|13-workloads-priorityclass)
      echo "Workloads & Scheduling (15%)" ;;
    14-cluster-rbac|15-cluster-crd|16-cluster-etcd|17-cluster-helm|18-cluster-tls)
      echo "Cluster Architecture (25%)" ;;
    *) echo "CKA" ;;
  esac
}

[[ $# -lt 1 ]] && usage

EXAM_TYPE="$1"; shift
SEED=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --seed) SEED="$2"; shift 2 ;;
    *) echo "Error: unknown option '$1'"; usage ;;
  esac
done

case "$EXAM_TYPE" in
  cka-prep-2025-v2|dumbitguy|itkiddie) ;;
  *) echo "Error: unknown exam type '$EXAM_TYPE'"; usage ;;
esac

[[ -n "$SEED" ]] && RANDOM=$SEED

TIMESTAMP=$(date +%Y-%m-%d_%H%M%S)
OUTPUT_DIR="$EXAMS_DIR/${TIMESTAMP}-${EXAM_TYPE}"
mkdir -p "$OUTPUT_DIR"

EXAM_FILE="$OUTPUT_DIR/exam.md"
SETUP_FILE="$OUTPUT_DIR/setup.bash"

cat > "$EXAM_FILE" <<EOF
# CKA Practice Exam — ${EXAM_TYPE}

**Generated:** $(date)
**Type:** ${EXAM_TYPE}
**Seed:** ${SEED:-"none (random)"}

> Run \`bash setup.bash\` on Killercoda before starting.

---

EOF

cat > "$SETUP_FILE" <<'SHEOF'
#!/usr/bin/env bash
set -e

echo "================================="
echo " CKA Exam Environment Setup"
echo "================================="
echo ""
SHEOF
chmod +x "$SETUP_FILE"

Q=0
MISSING=()
DESTRUCTIVE=()

for topic_dir in "$TOPICS_DIR"/*/; do
  [[ -d "$topic_dir" ]] || continue
  topic=$(basename "$topic_dir")
  type_dir="${topic_dir}${EXAM_TYPE}"

  if [[ ! -d "$type_dir" ]]; then
    MISSING+=("$topic")
    continue
  fi

  vars=()
  for v in "$type_dir"/*/; do
    [[ -d "$v" ]] && vars+=("$v")
  done

  if [[ ${#vars[@]} -eq 0 ]]; then
    MISSING+=("$topic")
    continue
  fi

  chosen="${vars[$((RANDOM % ${#vars[@]}))]}"
  var_id=$(basename "$chosen")
  domain=$(get_domain "$topic")
  Q=$((Q + 1))

  {
    echo "## Question ${Q} — ${topic}"
    echo ""
    echo "**Domain:** ${domain}  "
    echo "**Variation:** ${var_id}"
    echo ""
    if [[ -f "$chosen/question.txt" ]]; then
      cat "$chosen/question.txt"
    else
      echo "_No question file found._"
    fi
    echo ""
    echo "<details>"
    echo "<summary>Solution</summary>"
    echo ""
    if [[ -f "$chosen/solution.txt" ]]; then
      cat "$chosen/solution.txt"
    else
      echo "_No solution file found._"
    fi
    echo ""
    echo "</details>"
    echo ""
    echo "---"
    echo ""
  } >> "$EXAM_FILE"

  {
    echo ""
    echo "# Q${Q}: ${topic} / ${var_id}"
    if [[ -f "$chosen/setup.bash" ]]; then
      if grep -q '^# DESTRUCTIVE' "$chosen/setup.bash" 2>/dev/null; then
        rel="${chosen#"$SCRIPT_DIR/"}"
        DESTRUCTIVE+=("Q${Q}: ${topic} — run manually: bash ${rel}setup.bash")
        echo "echo '[SKIP] Q${Q} ${topic}: destructive setup — run manually when ready'"
      else
        cat "$chosen/setup.bash"
      fi
    fi
    echo ""
  } >> "$SETUP_FILE"
done

if [[ ${#DESTRUCTIVE[@]} -gt 0 ]]; then
  {
    echo ""
    echo "echo ''"
    echo "echo '================================================'"
    echo "echo ' Destructive setups (run manually when ready):'"
    echo "echo '================================================'"
    for note in "${DESTRUCTIVE[@]}"; do
      echo "echo '  - ${note}'"
    done
  } >> "$SETUP_FILE"
fi

{
  echo ""
  echo "---"
  echo ""
  echo "_Total: **${Q} / 18** questions included._"
} >> "$EXAM_FILE"

echo ""
echo "+-----------------------------------------+"
echo "|  CKA Exam Generator                     |"
echo "+-----------------------------------------+"
printf "|  Type:      %-28s|\n" "$EXAM_TYPE"
printf "|  Questions: %-28s|\n" "${Q}/18"
printf "|  Output:    %-28s|\n" "${TIMESTAMP}-${EXAM_TYPE}"
echo "+-----------------------------------------+"
echo ""
echo "  exam.md    -> open to read questions"
echo "  setup.bash -> run on Killercoda before starting"
echo ""

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "  [WARN] No '${EXAM_TYPE}' exercises for:"
  for t in "${MISSING[@]}"; do
    printf "    - %s\n" "$t"
  done
  echo ""
fi
