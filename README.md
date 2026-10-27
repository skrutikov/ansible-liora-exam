# Liora Ansible Exam: WordPress + WooCommerce + MySQL

The `implement` branch automates an e-commerce demo on the **existing Ubuntu 24.04 Liora VM**, with two roles: MySQL and WordPress (including WooCommerce). No reinstall or extra VM is required.

The initial WordPress/MySQL deployment succeeded on the VM. WooCommerce automation has been added but requires runtime verification on the VM. If /shop/ displays the blog instead of products, the playbook now fixes an empty permalink structure. Verification prints an explicit failure reason instead of exiting silently.

## Deploy

```bash
cd ~/ansible-liora-exam
git switch implement
git pull --ff-only
ansible-galaxy collection install -r requirements.yml
bash generate-secrets.sh
ansible-playbook -i inventory.ini deploy.yml --syntax-check
mkdir -p evidence
set -o pipefail
ansible-playbook -i inventory.ini deploy.yml 2>&1 | tee evidence/deployment.txt
bash verify.sh 2>&1 | tee evidence/verification.txt
```

Your VM has passwordless sudo: **do not use `-K`**. The playbook installs WP-CLI, initializes WordPress only if it is not already initialized, installs and activates WooCommerce, creates standard store pages, sets EUR / Germany defaults, and seeds one demo product priced at €9.90, and sets the WordPress permalink structure to /%postname%/ only if the site still uses plain permalinks. A rerun is designed not to duplicate the product or overwrite an existing administrator.

On a fresh WordPress site, login is `liora_admin` and the password is stored locally in `.secrets/wp_admin_password`. The email defaults to `admin@example.invalid`; change this for non-demo usage. Existing WordPress administrator credentials and URL are preserved.

## See the shop from Windows

```powershell
ssh -L 8080:127.0.0.1:80 ubuntu@VM_IP
```

With the SSH connection open, visit http://localhost:8080/shop/ (or http://localhost:8080/wp-admin/). If redirects go to a different address, check the pre-existing site URL:

```bash
sudo -u www-data wp option get siteurl --path=/var/www/wordpress
```

## Repeatability and submission

```bash
ansible-playbook -i inventory.ini deploy.yml 2>&1 | tee evidence/repeat-deployment.txt
zip -r ../ansible-exam-submission.zip inventory.ini deploy.yml requirements.yml group_vars roles generate-secrets.sh verify.sh README.md evidence
```

The final archive includes both Ansible roles, master playbook and actual test logs. `.secrets/` is excluded; never commit or submit it.

## Limitations

This is a **local-only exam demo**, not a public production webshop. It has no payment gateway, TLS, shipping or tax configuration, production email, or backups. Do not accept real orders or payments. WooCommerce is installed from the official WordPress plugin distribution; version pinning and upgrades are not managed. Nginx listens only on VM localhost; Windows browser access requires SSH port forwarding.

## Ansible become-user permissions

The `wordpress` role installs Ubuntu's `acl` package before WP-CLI tasks run as `www-data`. This provides `setfacl`, which Ansible Core 2.16 uses for secure permissions on temporary module files when switching from the normal Ubuntu SSH/local user to an unprivileged account. Without `acl`, deployment can fail with `chmod: invalid mode: A+user:www-data:rx:allow`. On an existing VM, `sudo apt install -y acl` fixes the immediate problem; then rerun the playbook. Do not run WP-CLI as root just to bypass this error.
