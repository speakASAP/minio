#!/bin/bash
# MinIO Microservice Deployment Script
# Deploys MinIO to production using the nginx-microservice blue/green deployment system.
#
# Uses: nginx-microservice/scripts/blue-green/deploy-smart.sh
# SSL: Managed by nginx-microservice (Let's Encrypt per-host or wildcard via WILDCARD_CERT_DOMAINS + DNS-01).
#
# The script automatically detects the nginx-microservice location and
# calls the deploy-smart.sh script to perform the deployment.

set -e

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load .env to determine environment
NODE_ENV=""
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    # shellcheck source=/dev/null
    source "$PROJECT_ROOT/.env" 2>/dev/null || true
    set +a
    NODE_ENV="${NODE_ENV:-}"
fi

# Pull from remote in production; preserve local changes (stash uncommitted if any, then reapply).
# Only sync if NODE_ENV is set to "production"
if [ -d ".git" ]; then
    if [ "$NODE_ENV" = "production" ]; then
        echo -e "${BLUE}Production environment detected (NODE_ENV=production)${NC}"
        echo -e "${BLUE}Pulling from remote (local changes preserved)...${NC}"
        git fetch origin
        BRANCH=$(git rev-parse --abbrev-ref HEAD)
        STASHED=0
        if [ -n "$(git status --porcelain)" ]; then
            git stash push -u -m "deploy.sh: stash before pull"
            STASHED=1
        fi
        git pull origin "$BRANCH"
        if [ "$STASHED" = "1" ]; then
            git stash pop
        fi
        echo -e "${GREEN}✓ Repository updated from origin/$BRANCH (local changes preserved)${NC}"
        echo ""
    else
        echo -e "${YELLOW}Development environment detected (NODE_ENV=${NODE_ENV:-not set})${NC}"
        echo -e "${YELLOW}Skipping git sync - local changes will be preserved${NC}"
        echo ""
    fi
fi

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           MinIO Microservice - Production Deployment       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

SERVICE_NAME="minio-microservice"

# Detect nginx-microservice path
NGINX_MICROSERVICE_PATH=""
if [ -d "/home/statex/nginx-microservice" ]; then
    NGINX_MICROSERVICE_PATH="/home/statex/nginx-microservice"
elif [ -d "/home/alfares/nginx-microservice" ]; then
    NGINX_MICROSERVICE_PATH="/home/alfares/nginx-microservice"
elif [ -d "/home/belunga/nginx-microservice" ]; then
    NGINX_MICROSERVICE_PATH="/home/belunga/nginx-microservice"
elif [ -d "$HOME/nginx-microservice" ]; then
    NGINX_MICROSERVICE_PATH="$HOME/nginx-microservice"
elif [ -d "$(dirname "$PROJECT_ROOT")/nginx-microservice" ]; then
    NGINX_MICROSERVICE_PATH="$(dirname "$PROJECT_ROOT")/nginx-microservice"
elif [ -d "$PROJECT_ROOT/../nginx-microservice" ]; then
    NGINX_MICROSERVICE_PATH="$(cd "$PROJECT_ROOT/../nginx-microservice" && pwd)"
fi

if [ -z "$NGINX_MICROSERVICE_PATH" ] || [ ! -d "$NGINX_MICROSERVICE_PATH" ]; then
    echo -e "${RED}❌ Error: nginx-microservice not found${NC}"
    echo ""
    echo "Please ensure nginx-microservice is installed in one of these locations:"
    echo "  - /home/statex/nginx-microservice"
    echo "  - /home/alfares/nginx-microservice"
    echo "  - /home/belunga/nginx-microservice"
    echo "  - $HOME/nginx-microservice"
    echo "  - $(dirname "$PROJECT_ROOT")/nginx-microservice (sibling directory)"
    echo ""
    echo "Or set NGINX_MICROSERVICE_PATH environment variable:"
    echo "  export NGINX_MICROSERVICE_PATH=/path/to/nginx-microservice"
    exit 1
fi

DEPLOY_SCRIPT="$NGINX_MICROSERVICE_PATH/scripts/blue-green/deploy-smart.sh"
if [ ! -f "$DEPLOY_SCRIPT" ]; then
    echo -e "${RED}❌ Error: deploy-smart.sh not found at $DEPLOY_SCRIPT${NC}"
    exit 1
fi

if [ ! -x "$DEPLOY_SCRIPT" ]; then
    echo -e "${YELLOW}⚠️  Making deploy-smart.sh executable...${NC}"
    chmod +x "$DEPLOY_SCRIPT"
fi

echo -e "${GREEN}✅ Found nginx-microservice at: $NGINX_MICROSERVICE_PATH${NC}"
echo -e "${GREEN}✅ Deploying service: $SERVICE_NAME${NC}"
echo ""

# Remove existing minio nginx configs so deploy-smart.sh regenerates them from current
# nginx-api-routes.conf (ensures location / and location /minio/ are both present).
MINIO_DOMAIN="minio.alfares.cz"
BLUE_GREEN_DIR="$NGINX_MICROSERVICE_PATH/nginx/conf.d/blue-green"
STAGING_DIR="$NGINX_MICROSERVICE_PATH/nginx/conf.d/staging"
for f in "$BLUE_GREEN_DIR/${MINIO_DOMAIN}.blue.conf" "$BLUE_GREEN_DIR/${MINIO_DOMAIN}.green.conf" \
         "$STAGING_DIR/${MINIO_DOMAIN}.blue.conf" "$STAGING_DIR/${MINIO_DOMAIN}.green.conf"; do
    if [ -f "$f" ]; then
        rm -f "$f"
        echo -e "${BLUE}Removed $f so config will be regenerated${NC}"
    fi
done

# Timing and phase summary
get_timestamp_seconds() { date +%s.%N; }
PHASE_TIMING_FILE=$(mktemp /tmp/deploy-phases-XXXXXX)
trap "rm -f $PHASE_TIMING_FILE" EXIT
start_phase() { local n="$1" t=$(get_timestamp_seconds); echo "$n|START|$t" >> "$PHASE_TIMING_FILE"; echo -e "${YELLOW}⏱️  PHASE START: $n${NC}" >&2; }
end_phase() { local n="$1" t=$(get_timestamp_seconds); echo "$n|END|$t" >> "$PHASE_TIMING_FILE"; local sl=$(grep "^${n}|START|" "$PHASE_TIMING_FILE" | tail -1); if [ -n "$sl" ]; then local st=$(echo "$sl" | cut -d'|' -f3); local d=$(awk "BEGIN {printf \"%.2f\", $t - $st}"); echo -e "${GREEN}⏱️  PHASE END: $n (duration: ${d}s)${NC}" >&2; fi; }
print_phase_summary() {
    if [ ! -f "$PHASE_TIMING_FILE" ] || [ ! -s "$PHASE_TIMING_FILE" ]; then echo ""; echo -e "${YELLOW}⚠️  No phase timing data available${NC}"; echo ""; return; fi
    echo ""; echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"; echo -e "${BLUE}📊 DEPLOYMENT PHASE TIMING SUMMARY${NC}"; echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    local cur="" st="" tot=0; while IFS='|' read -r p e ts; do
        if [ "$e" = "START" ]; then cur="$p"; st="$ts"
        elif [ "$e" = "END" ] && [ -n "$st" ] && [ -n "$cur" ]; then local d=$(awk "BEGIN {printf \"%.2f\", $ts - $st}"); tot=$(awk "BEGIN {printf \"%.2f\", $tot + $d}"); printf "  ${GREEN}%-45s${NC} ${YELLOW}%10.2fs${NC}\n" "$cur:" "$d"; cur=""; st=""; fi
    done < "$PHASE_TIMING_FILE"
    if [ "$(echo "$tot > 0" | bc 2>/dev/null || echo "0")" = "1" ]; then echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"; printf "  ${GREEN}%-45s${NC} ${YELLOW}%10.2fs${NC}\n" "Total (all phases):" "$tot"; fi
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"; echo ""
}

# Change to nginx-microservice directory and run deployment
start_phase "Pre-deployment Setup"
echo -e "${YELLOW}Starting blue/green deployment...${NC}"
echo ""
cd "$NGINX_MICROSERVICE_PATH"
end_phase "Pre-deployment Setup"
START_TIME=$(get_timestamp_seconds)
"$DEPLOY_SCRIPT" "$SERVICE_NAME" 2>&1 | {
    build_started=0; start_containers_started=0; health_check_started=0
    while IFS= read -r line; do echo "$line"
        if echo "$line" | grep -qE "Phase 0:.*Infrastructure"; then start_phase "Phase 0: Infrastructure Check"
        elif echo "$line" | grep -qE "Phase 0 completed|✅ Phase 0 completed"; then end_phase "Phase 0: Infrastructure Check"
        elif echo "$line" | grep -qE "Phase 1:.*Preparing|Phase 1:.*Prepare"; then start_phase "Phase 1: Prepare Green Deployment"
        elif echo "$line" | grep -qE "Phase 1 completed|✅ Phase 1 completed"; then end_phase "Phase 1: Prepare Green Deployment"
        elif echo "$line" | grep -qE "Phase 2:.*Switching|Phase 2:.*Switch"; then start_phase "Phase 2: Switch Traffic to Green"
        elif echo "$line" | grep -qE "Phase 2 completed|✅ Phase 2 completed"; then end_phase "Phase 2: Switch Traffic to Green"
        elif echo "$line" | grep -qE "Phase 3:.*Monitoring|Phase 3:.*Monitor"; then start_phase "Phase 3: Monitor Health"
        elif echo "$line" | grep -qE "Phase 3 completed|✅ Phase 3 completed"; then end_phase "Phase 3: Monitor Health"
        elif echo "$line" | grep -qE "Phase 4:.*Verifying|Phase 4:.*Verify"; then start_phase "Phase 4: Verify HTTPS"
        elif echo "$line" | grep -qE "Phase 4 completed|✅ Phase 4 completed"; then end_phase "Phase 4: Verify HTTPS"
        elif echo "$line" | grep -qE "Phase 5:.*Cleaning|Phase 5:.*Cleanup"; then start_phase "Phase 5: Cleanup"
        elif echo "$line" | grep -qE "Phase 5 completed|✅ Phase 5 completed"; then end_phase "Phase 5: Cleanup"
        elif echo "$line" | grep -qE "Building containers|Image.*Building" && [ "$build_started" -eq 0 ]; then start_phase "Build Containers"; build_started=1
        elif echo "$line" | grep -qE "All services built|✅ All services built" && [ "$build_started" -eq 1 ]; then end_phase "Build Containers"; build_started=2
        elif echo "$line" | grep -qE "Starting containers|Container.*Starting" && [ "$start_containers_started" -eq 0 ]; then start_phase "Start Containers"; start_containers_started=1
        elif echo "$line" | grep -qE "Container.*Started|Waiting.*services to start" && [ "$start_containers_started" -eq 1 ]; then end_phase "Start Containers"; start_containers_started=2
        elif echo "$line" | grep -qE "Checking.*health|Health check" && [ "$health_check_started" -eq 0 ]; then start_phase "Health Checks"; health_check_started=1
        elif echo "$line" | grep -qE "health check passed|✅.*health" && [ "$health_check_started" -eq 1 ]; then end_phase "Health Checks"; health_check_started=2
        fi
    done
}
DEPLOY_EXIT_CODE=${PIPESTATUS[0]}
END_TIME=$(get_timestamp_seconds)
TOTAL_DURATION=$(awk "BEGIN {printf \"%.2f\", $END_TIME - $START_TIME}")

if [ $DEPLOY_EXIT_CODE -eq 0 ]; then
    TOTAL_DURATION_FORMATTED=$(awk "BEGIN {printf \"%.2f\", $TOTAL_DURATION}")
    print_phase_summary 2>&1
    echo ""

    # Apply S3 SigV4-compatible proxy from minio.conf (Host $http_host, Authorization $http_authorization)
    MINIO_CONF="$PROJECT_ROOT/nginx/minio.conf"
    MINIO_INCLUDE_DST="$NGINX_MICROSERVICE_PATH/nginx/includes/minio-proxy-settings.conf"
    if [ -f "$MINIO_CONF" ]; then
        # Generate minio-proxy-settings.conf from minio.conf (single source of truth): extract proxy
        # directives from first location block, then add timeouts/buffers as in common-proxy-settings
        {
            echo "# MinIO/S3 proxy settings (SigV4). Generated from nginx/minio.conf - do not edit here."
            echo "# Proxy headers (S3 SigV4 compatible)"
            awk '/^location \/ \{/,/^\}$/ {
                if ($0 ~ /proxy_http_version|proxy_set_header|proxy_buffering|proxy_request_buffering|client_max_body_size/) print
            }' "$MINIO_CONF"
            echo "proxy_set_header Upgrade \$http_upgrade;"
            echo "proxy_set_header Connection 'upgrade';"
            echo "proxy_cache_bypass \$http_upgrade;"
            echo ""
            echo "# Proxy timeouts"
            echo "proxy_connect_timeout 300s;"
            echo "proxy_read_timeout 300s;"
            echo "proxy_send_timeout 300s;"
            echo ""
            echo "# Proxy buffer settings"
            echo "proxy_buffer_size 128k;"
            echo "proxy_buffers 4 256k;"
            echo "proxy_busy_buffers_size 256k;"
            echo ""
            echo "# CORS: allow portal to load presigned GET in browser (audio playback)"
            echo "add_header Access-Control-Allow-Origin '*' always;"
            echo "add_header Access-Control-Allow-Methods 'GET, HEAD, OPTIONS' always;"
            echo "add_header Access-Control-Expose-Headers 'Content-Length, Content-Type, ETag' always;"
        } > "$MINIO_INCLUDE_DST"
        echo -e "${GREEN}✓ Generated minio-proxy-settings.conf from nginx/minio.conf (SigV4 Host/Authorization)${NC}"
        for f in "$BLUE_GREEN_DIR/${MINIO_DOMAIN}.blue.conf" "$BLUE_GREEN_DIR/${MINIO_DOMAIN}.green.conf"; do
            if [ -f "$f" ]; then
                # Use MinIO-specific proxy settings include (SigV4‑safe headers).
                sed -i.bak 's|include /etc/nginx/includes/common-proxy-settings.conf|include /etc/nginx/includes/minio-proxy-settings.conf|g' "$f"
                # Ensure root S3 location does NOT rewrite the URI (no trailing slash on proxy_pass).
                sed -i.bak 's|proxy_pass http://\$TARGET_UPSTREAM/;|proxy_pass http://$TARGET_UPSTREAM;|g' "$f"
                # Strip /minio prefix so MinIO sees path-style /bucket/key (portal uses .../minio/).
                # Only within the /minio/ location block: replace proxy_pass line with rewrite + proxy_pass.
                sed -i.bak '/location \/minio\//,/}/ s|proxy_pass http://\$TARGET_UPSTREAM/minio/;|rewrite ^/minio/(.*)$ /$1 break;\
        proxy_pass http://$TARGET_UPSTREAM;|' "$f"
                # Allow local HTTPS checks from the host itself.
                sed -i.bak 's/server_name minio.alfares.cz;/server_name minio.alfares.cz 127.0.0.1;/' "$f"
                # Nginx must answer /health here; otherwise MinIO treats "health" as a bucket (403 AccessDenied).
                if ! grep -qE 'location = /health' "$f"; then
                    _tmp_hf=$(mktemp)
                    awk '/# Proxy locations \(auto-generated from service registry\)/ && !done {
                        print
                        print "    location = /health {"
                        print "        access_log off;"
                        print "        default_type text/plain;"
                        print "        return 200 \"ok\\n\";"
                        print "    }"
                        print ""
                        done=1
                        next
                    }
                    { print }' "$f" > "$_tmp_hf" && mv "$_tmp_hf" "$f"
                fi
                rm -f "${f}.bak"
                echo -e "${GREEN}✓ Patched $(basename "$f") for MinIO SigV4 (include + proxy_pass + server_name + /minio strip + /health)${NC}"
            fi
        done
        if docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^nginx-microservice$'; then
            docker exec nginx-microservice nginx -s reload 2>/dev/null && echo -e "${GREEN}✓ Nginx reloaded${NC}" || echo -e "${YELLOW}⚠ Nginx reload skipped or failed (reload manually if needed)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ nginx/minio.conf not found at $MINIO_CONF${NC}"
    fi
    echo ""

    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         ✅ MinIO deployment completed successfully!        ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}Total deployment time: ${TOTAL_DURATION_FORMATTED}s${NC}"
    echo ""
    echo "MinIO microservice has been deployed using blue/green deployment."
    echo "Check status with:"
    echo "  cd $NGINX_MICROSERVICE_PATH"
    echo "  ./scripts/status-all-services.sh"
    exit 0
else
    TOTAL_DURATION_FORMATTED=$(awk "BEGIN {printf \"%.2f\", $TOTAL_DURATION}")
    echo ""; echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}   ❌ MinIO deployment failed! Failed after: ${TOTAL_DURATION_FORMATTED}s${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════════${NC}"
    print_phase_summary
    echo ""; 
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                ❌ MinIO Deployment failed!                 ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Please check the error messages above and:"
    echo "  1. Verify nginx-microservice is properly configured"
    echo "  2. Check service registry: $NGINX_MICROSERVICE_PATH/service-registry/$SERVICE_NAME.json"
    echo "  3. Review deployment logs (and container logs if health check fails)"
    echo "  4. Check service health: cd $NGINX_MICROSERVICE_PATH && ./scripts/blue-green/health-check.sh $SERVICE_NAME"
    exit 1
fi
