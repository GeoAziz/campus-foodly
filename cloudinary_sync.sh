#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

ENV_FILE=".env.development"
ARGS=()
VALIDATE_ONLY=false
DEBUG=false

for arg in "$@"; do
	case "$arg" in
		--env-file=*)
			ENV_FILE="${arg#--env-file=}"
			;;
		--validate)
			VALIDATE_ONLY=true
			;;
		--debug)
			DEBUG=true
			;;
		*)
			ARGS+=("$arg")
			;;
	esac
done

if [[ -f "$ENV_FILE" ]]; then
	set -a
	# shellcheck disable=SC1090
	source "$ENV_FILE"
	set +a
else
	echo "[ERROR] Environment file not found: $ENV_FILE"
	exit 1
fi

if [[ "$DEBUG" == "true" ]]; then
	echo "[DEBUG] Environment file: $ENV_FILE"
	echo "[DEBUG] CLOUDINARY_CLOUD_NAME=${CLOUDINARY_CLOUD_NAME:-<not set>}"
	echo "[DEBUG] CLOUDINARY_API_KEY=${CLOUDINARY_API_KEY:0:3}***"
	echo "[DEBUG] CLOUDINARY_API_SECRET=${CLOUDINARY_API_SECRET:0:3}***"
	echo "[DEBUG] CLOUDINARY_FOLDER=${CLOUDINARY_FOLDER:-<not set>}"
fi

if [[ "$VALIDATE_ONLY" == "true" ]]; then
	node scripts/validate_cloudinary.js
	exit 0
fi

node scripts/cloudinary_sync.js "${ARGS[@]}"
