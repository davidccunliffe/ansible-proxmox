# CLAUDE.md — Claude Code Instructions for ansible-proxmox

## Project Overview

`ansible-proxmox` is an Ansible automation suite for full Proxmox VE lifecycle management.
It handles everything from initial host configuration to VM and LXC container provisioning.

**Key capabilities:**
- Proxmox host setup: community repos, package updates, dark theme UI, subscription nag removal
- SSL/ACME certificates via Let's Encrypt (Cloudflare or Azure DNS plugins)
- NGINX reverse proxy for the Proxmox web UI
- Network configuration: bonded NICs, VLAN-aware bridges (rendered via Jinja2)
- Storage: ISO downloads, LXC container template management, CIFS mounts
- VM templates: cloud image download, disk import, cloud-init preparation
- VMs: clone-based and standalone create/update/delete (fully idempotent)
- LXC containers: create/update/remove (fully idempotent)
- GPU/PCIe passthrough: IOMMU setup, vfio modules, driver blacklisting

---

## Running the Playbook

### Using the wrapper script

```bash
./run.sh <inventory-name> [tag]

# Examples:
./run.sh sample          # Run all tasks against the 'sample' inventory
./run.sh home-lab vms    # Run only VM tasks against the 'home-lab' inventory
```

`run.sh` expands to: `ansible-playbook ./playbooks/setup.yml -i ./inventories/<inventory-name> -t <tag>`

### Running directly with ansible-playbook

```bash
# Full run
ansible-playbook ./playbooks/setup.yml -i ./inventories/sample/hosts.yml

# With a tag (see tag reference below)
ansible-playbook ./playbooks/setup.yml -i ./inventories/sample/hosts.yml -t vms

# With SSH password prompt (when SSH keys are not configured)
ansible-playbook ./playbooks/setup.yml -i ./inventories/sample/hosts.yml -k

# With Ansible Vault password prompt
ansible-playbook ./playbooks/setup.yml -i ./inventories/sample/hosts.yml --ask-vault-pass

# Check mode (dry-run — no changes applied)
ansible-playbook ./playbooks/setup.yml -i ./inventories/sample/hosts.yml --check
```

### Helper playbooks

```bash
# List available LXC container images from Proxmox
ansible-playbook ./playbooks/list_ct_images.yml -i ./inventories/sample/hosts.yml

# List PCIe devices on Proxmox host
ansible-playbook ./playbooks/list_pcie_devices.yml -i ./inventories/sample/hosts.yml
```

---

## Ansible Tag Reference

| Tag | What it runs |
|---|---|
| `setup` | Initial Proxmox host config (repos, packages, dark theme, ACME, NGINX) |
| `networking` | Renders and applies `/etc/network/interfaces` |
| `storage` | Downloads ISOs and LXC container templates |
| `templates` | Creates VM templates from cloud images |
| `ubuntu_template` | Creates the Ubuntu 24.04 cloud-init template specifically |
| `vms` | Creates, updates, and removes VMs |
| `containers` | Creates, updates, and removes LXC containers |

Tags map directly to sections in `roles/proxmox/tasks/main.yml`.

---

## Setting Up an Inventory

1. Copy the sample inventory:
   ```bash
   cp -r inventories/sample inventories/my-lab
   ```

2. Edit `inventories/my-lab/hosts.yml` with your Proxmox host's IP and hostname.

3. Edit `inventories/my-lab/host_vars/<hostname>.yml` to configure:
   - Domain, ACME settings
   - PCIe passthrough device IDs
   - `templates`, `storage`, `vms`, `containers` dictionaries
   - Network config (if different from defaults)

All host-specific configuration lives in `host_vars/`. Do not edit `defaults/main.yml`
for per-environment values — use `host_vars/` overrides instead.

---

## Directory Reference

```
ansible-proxmox/
├── ansible.cfg                        # Ansible config (roles_path, callbacks)
├── run.sh                             # Playbook wrapper script
├── setup_env.sh                       # Dev environment setup (install deps)
├── .ansible-lint                      # ansible-lint config (skip rules, exclude paths)
├── .yamllint                          # YAML lint config (max 120 chars)
├── playbooks/
│   ├── setup.yml                      # Main playbook (entry point)
│   ├── list_ct_images.yml             # Helper: list available CT images
│   └── list_pcie_devices.yml          # Helper: list PCIe devices
├── inventories/
│   └── sample/
│       ├── hosts.yml                  # Host definitions
│       └── host_vars/sample.yml       # All configuration for the 'sample' host
├── roles/proxmox/
│   ├── defaults/main.yml              # Default variable values (safe to run as-is)
│   ├── handlers/main.yml              # Handlers: reboot, GRUB, initramfs, networking
│   ├── tasks/
│   │   ├── main.yml                   # Task orchestrator (imports sections by tag)
│   │   ├── setup/                     # Proxmox host setup (8 task files)
│   │   ├── networking/                # Network interface configuration
│   │   ├── storage/                   # ISO and CT template management
│   │   ├── templates/                 # VM template creation from cloud images
│   │   ├── vm/                        # VM lifecycle (12 task files)
│   │   └── containers/                # LXC container lifecycle (4 task files)
│   └── templates/                     # Jinja2 templates
│       ├── cloudinit/                 # Cloud-init user-data and meta-data
│       ├── interfaces.j2              # /etc/network/interfaces
│       ├── proxmox.conf.j2            # Proxmox node config
│       └── storage.cfg.j2             # Proxmox storage config
└── docs/
    ├── variables.md                   # Variable documentation
    ├── vm_variables.md                # VM-specific variable documentation
    └── cluster-template-replication.md  # Cluster template replication guide
```

---

## Variable Conventions

### Defaults vs. Host Vars

- `roles/proxmox/defaults/main.yml` — global defaults applied to all hosts
- `inventories/<name>/host_vars/<host>.yml` — per-host overrides (always takes precedence)

### VM Defaults

All `vm_defaults_*` variables set global VM defaults that apply to every VM unless overridden per VM:

```yaml
vm_defaults_cores: 1
vm_defaults_memory: 512
vm_defaults_bios: seabios
vm_defaults_machine: q35
vm_defaults_cpu: host
vm_defaults_onboot: false
vm_defaults_vga: qxl
vm_defaults_scsihw: virtio-scsi-pci
vm_defaults_netdev_type: virtio
vm_defaults_netdev_bridge: vmbr0
vm_defaults_netdev_firewall: true
```

Per-VM keys inside the `vms:` dictionary override these defaults.

### Container Defaults

```yaml
container_defaults:
  cores: 1
  memory: 512
  swap: 512
  onboot: false
  unprivileged: true
  nesting: true
  timezone: host
```

### Lifecycle Management Tags

These booleans control whether unreferenced Ansible-managed resources are removed:

```yaml
vm_remove_unreferenced: true          # Delete VMs not in `vms:` dict
container_remove_unreferenced: true   # Delete containers not in `containers:` dict
vm_iso_remove_unreferenced: true      # Remove ISOs not in storage config
ct_template_remove_unreferenced: true # Remove CT templates not in storage config
```

Set to `false` if you want to keep resources that aren't defined in the current config.

### The `managed_by_ansible_tag`

Every VM and container created by this role is tagged with `managed_by_ansible` (configurable via `managed_by_ansible_tag`). Removal logic only targets resources with this tag, protecting manually-created VMs/containers.

---

## Adding New Functionality

### Adding a new setup task

1. Create a task file in `roles/proxmox/tasks/setup/`
2. Import it in `roles/proxmox/tasks/setup/main.yml`
3. The `setup` tag on `tasks/main.yml` automatically covers all setup subtasks

### Adding a new top-level section

1. Create a directory under `roles/proxmox/tasks/`
2. Create a `main.yml` in that directory
3. Import it in `roles/proxmox/tasks/main.yml` with an appropriate tag:
   ```yaml
   - name: My new section
     ansible.builtin.import_tasks: my_section/main.yml
     tags: my_section
   ```

### Adding new default variables

Add to `roles/proxmox/defaults/main.yml`. Document them in `docs/variables.md`.

### Adding a new Jinja2 template

Add to `roles/proxmox/templates/`. Reference it in tasks using `ansible.builtin.template`.

---

## Linting

### Setup (first time)

```bash
./setup_env.sh   # Installs yamllint, ansible-lint, ansible
```

### Run linters

```bash
yamllint .        # YAML style checks (max line length 120)
ansible-lint      # Ansible best-practice checks
```

### Lint config

- `.yamllint` — allows up to 120 character lines, warnings only for line length
- `.ansible-lint` — skips `package-latest` and `git-latest` rules; excludes `playbooks/debug.yml`

### CI

GitHub Actions runs both linters on push and pull request via `.github/workflows/lint.yml`.

---

## Common Pitfalls

### Handlers must flush between sections

After tasks that change network or system config, `flush_handlers` is called in `tasks/main.yml`.
If you add tasks that need a handler to run before subsequent tasks, ensure `flush_handlers`
appears at the appropriate point.

### pvesh API idempotency

VM and container tasks use `pvesh` to query current state and compute diffs before applying
changes. Avoid using shell commands that bypass this — always check if a pvesh-based approach
is available.

### `vm_remove_unreferenced` caution

If `vm_remove_unreferenced: true` and a VM is accidentally omitted from `vms:`, it will be
deleted. Double-check your `vms:` dictionary before running with this enabled, especially
against production inventories.

### Network changes trigger a handler

Modifying `network_config` will trigger the `Restart networking` handler, which reloads
`/etc/network/interfaces`. This can briefly disrupt connectivity to the Proxmox host.

### Ubuntu 24.04 template uses a cloud-init ISO

The `ubuntu_template` task creates a cloud-init ISO (not just meta-data in the Proxmox
cloud-init UI). This is intentional for full customization but requires extra disk resources.

---

## Sensitive Variables

The following variables contain secrets and should be stored in Ansible Vault in production:

| Variable | Description |
|---|---|
| `acme_plugin_cloudflare_token` | Cloudflare API token for ACME DNS challenge |
| `acme_plugin_cloudflare_email` | Cloudflare account email |
| `acme_plugin_azure_clientsecret` | Azure service principal client secret |
| `acme_plugin_azure_appid` | Azure app ID |
| `acme_plugin_azure_tenantid` | Azure tenant ID |
| `acme_plugin_azure_subscriptionid` | Azure subscription ID |
| `ssh_keys` | SSH public keys for VM/container users |
| `containers[*].password` | LXC container root passwords |

**To encrypt a value with Vault:**
```bash
ansible-vault encrypt_string 'secret-value' --name 'variable_name'
```

**To run with a vault password:**
```bash
ansible-playbook ./playbooks/setup.yml -i ./inventories/my-lab/hosts.yml --ask-vault-pass
```

See `run.sh` for the commented-out vault example.
