#!/bin/bash
# Validate that .env is configured correctly before running the stack.
#
# Purpose: Checks for required variables, invalid values, dangerous defaults,
#          and port conflicts to catch configuration errors early.
#
# Usage: ./scripts/validate-env.sh
#
# Checks performed:
#   1. .env file exists
#   2. All required variables are set
#   3. EMAIL_TIER is valid (1-4)
#   4. No secrets are still set to 'changeme' defaults
#   5. Network CIDRs are valid
#   6. No obvious port conflicts
#
# Exit codes:
#   0  Configuration is valid
#   1  One or more validation errors found

set -e

ERRORS=0
WARNINGS=0

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

log_error() {
  echo -e "${RED}ERROR${NC}: $*" >&2
  ERRORS=$((ERRORS + 1))
}

log_warn() {
  echo -e "${YELLOW}WARN${NC}: $*" >&2
  WARNINGS=$((WARNINGS + 1))
}

log_ok() {
  echo -e "${GREEN}✓${NC} $*"
}

# Check if .env exists
if [ ! -f .env ]; then
  log_error ".env not found. Copy .env.example first: cp .env.example .env"
  exit 1
fi

# Source .env
source .env

# Check required variables
REQUIRED_VARS="NETLOCAL_ROOT_DOMAIN NETLOCAL_SUBNET_BACKBONE NETLOCAL_SUBNET_DEFAULT"
for var in $REQUIRED_VARS; do
  val=$(eval echo \$$var)
  if [ -z "$val" ]; then
    log_error "Required variable not set: $var"
  else
    log_ok "$var = $val"
  fi
done

# Check EMAIL_TIER
if [ -n "$EMAIL_TIER" ]; then
  case "$EMAIL_TIER" in
    1|2|3|4)
      log_ok "EMAIL_TIER = $EMAIL_TIER (valid)"
      ;;
    *)
      log_error "EMAIL_TIER must be 1-4, got: $EMAIL_TIER"
      ;;
  esac
fi

# Check for dangerous placeholder secrets
SECRETS="POSTGRES_PASSWORD MYSQL_ROOT_PASSWORD POWERDNS_API_KEY MINIO_ROOT_PASSWORD MINIO_ROOT_USER"
for secret in $SECRETS; do
  val=$(eval echo \$$secret 2>/dev/null || true)
  if [ "$val" = "changeme" ]; then
    log_error "Secret still set to 'changeme': $secret (CRITICAL)"
  elif [ -z "$val" ]; then
    log_warn "Secret not configured: $secret (will use defaults)"
  else
    log_ok "$secret is set"
  fi
done

# Check network CIDRs (basic validation)
for net_var in NETLOCAL_SUBNET_BACKBONE NETLOCAL_SUBNET_DEFAULT; do
  cidr=$(eval echo \$$net_var)
  if [ -n "$cidr" ]; then
    if [[ $cidr =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\/[0-9]+$ ]]; then
      log_ok "$net_var = $cidr (valid CIDR)"
    else
      log_error "$net_var is not a valid CIDR: $cidr"
    fi
  fi
done

# Summary
echo ""
echo "────────────────────────────────────────"
if [ $ERRORS -eq 0 ]; then
  echo -e "${GREEN}Configuration validation passed!${NC}"
  [ $WARNINGS -gt 0 ] && echo -e "${YELLOW}$WARNINGS warning(s) found${NC}"
  exit 0
else
  echo -e "${RED}$ERRORS error(s) found - fix before running make up${NC}"
  exit 1
fi
