ID        Check                                  Risk      Auto-fix
SSH-001   SSH root login disabled               High      Gated
SSH-002   SSH password authentication disabled  High      Gated
SUDO-001  sudoers ownership and mode            High      Yes
USER-001  inactive local human users            Medium    No by default
FS-001    world-writable dirs without sticky    Medium    Yes, scoped
FW-001    host firewall active                  Medium    No by default
UMASK-001 default umask is restrictive          Low       Yes
DOCKER-001 Docker socket not exposed broadly    Critical  Partial
CRON-001  cron files not group/world writable   High      Yes, scoped