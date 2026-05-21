#!/usr/bin/env bash
set -e

echo "=== Amazon Refund Tracker Setup ==="

# Install Python deps
pip install -r "$(dirname "$0")/requirements.txt" --quiet

# Install Playwright browsers (only Chromium needed)
python -m playwright install chromium

# Create credentials file if it doesn't exist
CREDS_DIR="$HOME/.amazon_refund_tracker"
ENV_FILE="$CREDS_DIR/.env"
mkdir -p "$CREDS_DIR"

if [ ! -f "$ENV_FILE" ]; then
    echo ""
    echo "Enter your Amazon credentials (stored locally at $ENV_FILE):"
    read -rp "Amazon email: " email
    read -rsp "Amazon password: " password
    echo ""
    cat > "$ENV_FILE" <<EOF
AMAZON_EMAIL=$email
AMAZON_PASSWORD=$password
EOF
    chmod 600 "$ENV_FILE"
    echo "Credentials saved to $ENV_FILE"
else
    echo "Credentials file already exists at $ENV_FILE"
fi

echo ""
echo "Setup complete! Run the tracker with:"
echo "  python -m amazon_refund_tracker"
echo ""
echo "Options:"
echo "  --report          Show saved data without re-scanning"
echo "  --export out.csv  Export results to CSV"
echo "  --days 14         Alert on refunds pending > 14 days"
echo "  --headless        Run without visible browser window"
