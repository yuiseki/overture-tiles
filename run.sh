#!/usr/bin/env bash

set -e
set -u

# Required environment variables
INPUT="${INPUT:?Error: INPUT environment variable is required}"
OUTPUT="${OUTPUT:?Error: OUTPUT environment variable is required}"
THEME="${THEME:?Error: THEME environment variable is required}"

# Optional environment variables
CUSTOM_PROFILE="${CUSTOM_PROFILE:-}"
CUSTOM_SCRIPT="${CUSTOM_SCRIPT:-}"
SKIP_UPLOAD="${SKIP_UPLOAD:-false}"

# TODO: Implement custom profile/script support later
if [ -n "$CUSTOM_PROFILE" ] || [ -n "$CUSTOM_SCRIPT" ]; then
  # Should download custom profile/script and use it. Currently not implemented.
  echo "Error: Custom profile/script support not yet implemented"
  exit 1
fi

# Download input data from S3
if [ -n "${BBOX:-}" ]; then
  echo "Downloading using bbox..."
  bash "$(dirname "$0")/bbox.sh" "$INPUT" "$BBOX" "$THEME" /data
else
  aws s3 sync --no-progress --region us-west-2 --no-sign-request "$INPUT/theme=$THEME" /data/theme=$THEME
fi

# Generate tiles based on theme
if [ "$THEME" == "places" ] || [ "$THEME" == "divisions" ]; then
  bash /scripts/${THEME}.sh /data $THEME.pmtiles
  if [ "$SKIP_UPLOAD" != "true" ]; then
    aws s3 cp --no-progress $THEME.pmtiles "$OUTPUT"
  fi
else
  className="${THEME^}"
  java -cp planetiler.jar /profiles/$className.java --data=/data
  if [ "$SKIP_UPLOAD" != "true" ]; then
    aws s3 cp --no-progress /data/$THEME.pmtiles "$OUTPUT"
  fi
fi
