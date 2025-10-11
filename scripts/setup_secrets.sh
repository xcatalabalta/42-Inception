#!/bin/sh
# scripts/setup_secrets.sh - Interactive secrets configuration

set -e
# Colors for output
GREEN="\e[0;32m"
RED="\e[0;31m"
YELLOW="\e[0;33m"
NC="\e[0m"
SECRETS_DIR="secrets"

validate_strict_wordpress_email() {
    local email="$1"
    local EMAIL_REGEX="^[A-Za-z0-9.!#$%&'*+/=?^\`{|}~-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
    # More practical strict validation
    if [[ ! "$email" =~ $EMAIL_REGEX ]]; then
        echo -e "${RED}✗ Invalid email format${NC}"
        return 1
    fi
    
    # WordPress-specific validations
    if [[ "$email" =~ \\.\\. ]]; then
        echo -e "${RED}✗ Email cannot contain consecutive dots${NC}"
        return 1
    fi
    
    if [[ "$email" =~ ^[.-] || "$email" =~ @[.-] || "$email" =~ [.-]$ ]]; then
        echo -e "${RED}✗ Email cannot start or end with . or -${NC}"
        return 1
    fi
    
    local local_part="${email%@*}"
    local domain_part="${email#*@}"
    
    if [[ ${#local_part} -gt 64 ]]; then
        echo -e "${RED}✗ Local part (before @) too long (max 64 characters)${NC}"
        return 1
    fi
    
    if [[ ${#domain_part} -gt 255 ]]; then
        echo -e "${RED}✗ Domain part too long${NC}"
        return 1
    fi
    
    if [[ "$domain_part" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${RED}✗ IP addresses not allowed in email domain${NC}"
        return 1
    fi
    
    return 0
}

echo "This script will create secret files for the Inception project."
echo "Passwords will not be displayed while typing."
echo ""

# Database credentials
echo "=== Database Configuration ==="

CONTROL=0
while [ $CONTROL == 0 ]; do
	echo "⚠️  Passwords must be minimum 5 characters."
	echo -en "${YELLOW}Database$ password:${NC} "
	read -s DB_PASS
	if [ `echo $DB_PASS | wc -m` -ge 6 ]; then
		CONTROL=1
	fi
done
echo ""
CONTROL=0
while [ $CONTROL == 0 ]; do
	
	echo -en "Database ${RED}ROOT${NC} password: "
	read -s DB_ROOT_PASS
	if [ ${#DB_ROOT_PASS} -ge 5 ]; then
		CONTROL=1
	else
		echo "⚠️  Passwords must be minimum 5 characters."
	fi
done

echo ""

# WordPress admin
CONTROL=0
echo ""
echo "=== WordPress Admin User ==="
echo "⚠️  Username must a single word and do NOT contain 'admin', 'Admin', or 'administrator'"
while [ $CONTROL == 0 ]; do
	read -p "Admin username: " WP_ADMIN_USER
	if echo "$WP_ADMIN_USER" | grep -qi "admin"; then
		echo "Error: Username cannot contain 'admin'!"
	else
		if [ `echo $WP_ADMIN_USER | wc -w` -eq 0 ]; then
			echo "Error: Username cannot be empty!"
		elif [ `echo $WP_ADMIN_USER | wc -w` -gt 1 ]; then
			echo "Error: Username must be a single word"
		else
			CONTROL=1
		fi
	fi
done

CONTROL=0
while [ $CONTROL == 0 ]; do
	
	echo -en "WP ${GREEN}Admin${NC} password: "
	read -s WP_ADMIN_PASS
	if [ ${#WP_ADMIN_PASS} -ge 5 ]; then
		CONTROL=1
	else
		echo "⚠️  Passwords must be minimum 5 characters."
	fi
done

echo ""

CONTROL=0
while [ $CONTROL -eq 0 ]; do
    read -p "Admin email: " WP_ADMIN_EMAIL
    
    if [[ -z "$WP_ADMIN_EMAIL" ]]; then
        echo -e "${RED}✗ Email cannot be empty.${NC}"
        continue
    fi
    
    if validate_strict_wordpress_email "$WP_ADMIN_EMAIL"; then
        echo -e "${GREEN}✓ Valid email format${NC}"
        CONTROL=1
    else
        echo -e "${RED}✗ Invalid email format. Please try again (example: admin@example.com).${NC}"
    fi
done

# WordPress editor
echo ""
echo "=== WordPress Editor User ==="
read -p "Editor username: " WP_USER
read -p "Editor password: " -s WP_USER_PASS
echo ""
read -p "Editor email: " WP_USER_EMAIL

# Write secrets
echo ""
echo "Writing secrets to ./$SECRETS_DIR/..."

echo -n "$DB_PASS" > "$SECRETS_DIR/db_password"
echo -n "$DB_ROOT_PASS" > "$SECRETS_DIR/db_root_password"
echo -n "$WP_ADMIN_USER" > "$SECRETS_DIR/wp_admin_user"
echo -n "$WP_ADMIN_PASS" > "$SECRETS_DIR/wp_admin_password"
echo -n "$WP_ADMIN_EMAIL" > "$SECRETS_DIR/wp_admin_email"
echo -n "$WP_USER" > "$SECRETS_DIR/wp_user"
echo -n "$WP_USER_PASS" > "$SECRETS_DIR/wp_user_password"
echo -n "$WP_USER_EMAIL" > "$SECRETS_DIR/wp_user_email"

# Create credentials reference
cat > "$SECRETS_DIR/credentials" << EOF
# Inception Project Credentials Reference
# DO NOT commit this file to Git!

Database:
  User: wp_user
  Password: [see db_password]
  Root Password: [see db_root_password]

WordPress Admin:
  Username: [see wp_admin_user]
  Password: [see wp_admin_password]
  Email: [see wp_admin_email]

WordPress Editor:
  Username: [see wp_user]
  Password: [see wp_user_password]
  Email: [see wp_user_email]
EOF

echo "Done!"