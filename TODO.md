# TODO

Development backlog for `ansible-proxmox`. Items are organized by category and roughly
prioritized within each section (top = highest priority).

---

## Testing

- [ ] **Add Molecule testing framework** — Set up Molecule with a delegated or Docker driver
      to enable unit and integration testing for individual task files
- [ ] **Add Molecule scenarios for VM tasks** — Cover create, update, and delete flows
      in `tasks/vm/`
- [ ] **Add Molecule scenarios for container tasks** — Cover LXC create/update/remove
      flows in `tasks/containers/`
- [ ] **Add CI dry-run (check mode) job** — Add a GitHub Actions job that runs
      `ansible-playbook --check` against the sample inventory to catch regressions
      without a live Proxmox host
- [ ] **Add Testinfra or ansible.builtin.assert checks** — Post-provisioning verification
      tasks to confirm VM/container state matches desired config

---

## Security / Secrets

- [ ] **Document Ansible Vault usage** — Add a `docs/vault.md` guide covering how to
      encrypt sensitive variables (`acme_plugin_*` tokens, container passwords, SSH keys),
      vault file structure, and how to run with `--ask-vault-pass`
- [ ] **Add a vault example file** — Create `inventories/sample/host_vars/sample.vault.yml`
      with placeholder encrypted values to show the expected vault structure
- [ ] **Audit `sample.yml` for plaintext secrets** — Replace all `changeme` sentinel values
      with vault-encrypted placeholders in the sample inventory

---

## Code Quality

- [ ] **Fix `setup_env.sh` to use a virtualenv** — Replace bare `pip3 install` (which
      installs globally or requires sudo) with a Python virtualenv to match CI behavior
      and avoid system package conflicts
      ```bash
      python3 -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
      ```
- [ ] **Add `requirements.txt`** — Pin `yamllint`, `ansible-lint`, `ansible`, and `jmespath`
      versions to match the CI environment
- [ ] **Improve `run.sh`** — Add error handling, argument validation, and a `--help` flag;
      currently fails silently if no inventory is provided
- [ ] **Add pre-commit hooks** — Configure `.pre-commit-config.yaml` with `yamllint` and
      `ansible-lint` hooks so linting runs automatically before every commit
- [ ] **Rename or remove `playbooks/debug.yml`** — The file is excluded from lint but its
      purpose is undocumented; clean up or add a comment explaining its use

---

## Features

- [ ] **Implement cluster template replication tasks** — `docs/cluster-template-replication.md`
      documents the workflow but no corresponding tasks exist; implement replication of VM
      templates across Proxmox cluster nodes using `pvesh` or `qm`
- [ ] **Add multi-node cluster inventory example** — Create
      `inventories/sample-cluster/` showing how to configure a 3-node Proxmox cluster
      with shared storage and cluster networking
- [ ] **Add Debian 12 (Bookworm) cloud image template** — Mirror the Ubuntu 24.04 template
      task for a current Debian cloud image
- [ ] **Add Rocky Linux / AlmaLinux cloud image template** — Add RHEL-compatible template
      support for workloads requiring RPM-based guests
- [ ] **Add ZFS storage configuration** — Extend `templates/storage.cfg.j2` and storage
      tasks to support ZFS pools as Proxmox storage targets
- [ ] **Add Ceph storage support** — Initial support for Ceph RBD storage pools for
      clustered deployments
- [ ] **Add snapshot rollback playbook** — Add a helper playbook that rolls back VMs to
      a named snapshot; complement the existing snapshot creation support in `vms:`
- [ ] **Add support for VM/container tags list** — Allow specifying additional Proxmox
      tags per VM beyond `managed_by_ansible_tag`

---

## Documentation

- [ ] **Document ACME Azure plugin variable requirements** — The Azure plugin variables
      (`acme_plugin_azure_*`) are listed in `sample.yml` but not explained in `docs/variables.md`
- [ ] **Document GPU passthrough verification steps** — Add post-setup verification steps
      (e.g. `lspci`, IOMMU group checks, vfio binding confirmation) to either
      `docs/variables.md` or a new `docs/gpu-passthrough.md`
- [ ] **Add architecture diagram** — Visual overview of how playbook → role → tasks →
      handlers flow, and how inventories map to Proxmox nodes
- [ ] **Document `network_config` structure** — The bonded NIC + bridge config in
      `defaults/main.yml` is complex; add inline comments and a `docs/networking.md`
      reference with example topologies
- [ ] **Add `CONTRIBUTING.md`** — Contributor guide covering: branching strategy, how to
      test changes, lint requirements, and PR process

---

## CI/CD

- [ ] **Pin Python and Ansible versions in CI** — `lint.yml` installs latest versions;
      pin to specific versions for reproducibility
- [ ] **Add a release workflow** — Tag-triggered GitHub Actions workflow to publish
      versioned releases with a changelog
- [ ] **Add dependabot for GitHub Actions** — Keep CI action versions up to date
      automatically

