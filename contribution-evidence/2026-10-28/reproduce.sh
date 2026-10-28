#!/usr/bin/env bash
set -euo pipefail
task_repo="$(git rev-parse --show-toplevel)"
task_evidence="$task_repo/contribution-evidence/2026-10-28"
task_flutter="$(command -v "${FLUTTER:-flutter}")"
task_flutter="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "$task_flutter")"
task_fonts="${FLUTTER_FONT_DIR:-$(dirname "$task_flutter")/cache/artifacts/material_fonts}"
task_output="$(python3 -c 'from pathlib import Path; import sys; print(Path(sys.argv[1]).resolve())' "${1:?Pass a capture output directory}")"
task_temp="$(mktemp -d "${TMPDIR:-/tmp}/finamp-evidence.XXXXXX")"
mkdir -p "$task_output"
printf 'Isolated reproduction clones: %s\n' "$task_temp"

capture_revision() {
  local task_stage="$1" task_revision="$2" task_test="$3"
  git clone --quiet --shared --no-checkout "$task_repo" "$task_temp/$task_stage"
  git -C "$task_temp/$task_stage" checkout --quiet --detach "$task_revision"
  cp "$task_evidence/contribution_evidence_test.dart" "$task_temp/$task_stage/test/"
  if [ "$task_stage" = after ]; then
    cp "$task_evidence/contribution_settings_evidence_test.dart" "$task_temp/$task_stage/test/"
  fi
  (
    cd "$task_temp/$task_stage"
    "$task_flutter" pub get > "$task_output/pub-$task_stage.log" 2>&1
    "$task_flutter" gen-l10n > "$task_output/localizations-$task_stage.log" 2>&1
    "$task_flutter" test --no-pub --update-goldens --reporter expanded \
      --dart-define="EVIDENCE_AFTER=$([ "$task_stage" = after ] && printf true || printf false)" \
      --dart-define="EVIDENCE_DIR=$task_output" \
      --dart-define="FLUTTER_FONT_DIR=$task_fonts" \
      "test/$task_test" > "$task_output/capture-$task_stage.log" 2>&1
  )
}

capture_revision before b72ba46a45eb45836516f23e3df989c89c693c88 contribution_evidence_test.dart
capture_revision after ec109989ace6143377567a1ec71664ec6863dcc3 contribution_settings_evidence_test.dart
printf 'Captured three before and four after images in %s\n' "$task_output"
