# Debian Stretch on the TS-7800-v2: A Time Capsule

## The Situation

The TS-7800-v2 ships with **Debian 9 "Stretch"**, released June 2017. For context:

- Python 3.5 was cutting edge
- Node.js 8 was the LTS
- Docker was at version 17
- People still remembered what a "fidget spinner" was

Debian Stretch reached **end of life in June 2022**. It no longer receives security updates. We are running a museum exhibit.

## Why This Matters

### Package Antiquity

```bash
apt-cache show python3 | grep Version
# Version: 3.5.3-1
```

Modern Python is 3.12+. Many packages we take for granted simply don't exist or require extensive backporting. `pip install` becomes an archaeological expedition.

### Security Concerns

No security patches since 2022. Every CVE published since then is a potential vulnerability. This device should not be exposed to untrusted networks.

### Dependency Hell

Want to install a modern tool? Prepare for:
- "Requires glibc 2.28" (Stretch has 2.24)
- "Requires OpenSSL 1.1.1" (Stretch has 1.1.0)
- "Requires kernel 5.x" (Stretch has 4.x)

The cascade of dependencies will crush your spirit.

### The "Just Upgrade" Fantasy

Upgrading from Stretch to Buster to Bullseye to Bookworm is theoretically possible. In practice, on an embedded ARM board with custom kernel modules (looking at you, WILC driver), this path is littered with broken boots and kernel panics.

Technologic Systems provides Stretch. They do not provide a clear upgrade path. We are marooned.

## Coping Strategies

### 1. Use Static Binaries

Compile on a modern system with `-static` flags. Avoid the dependency swamp entirely.

### 2. Container Escape (Sort Of)

Docker *might* work if you can get a modern enough version installed. Your containers can run modern distros even if the host is ancient.

### 3. Cross-Compile Everything

Build on your modern workstation, deploy binaries to the board. Accept that `apt install` is mostly decorative.

### 4. Embrace the Constraints

Write minimal software. Avoid dependencies. Channel your inner 1990s embedded developer. If it doesn't fit in a shell script, question whether you need it.

## What Year Is It?

| Component | Stretch Version | Modern Version (2026) |
|-----------|-----------------|----------------------|
| Python | 3.5.3 | 3.12+ |
| GCC | 6.3 | 13+ |
| OpenSSL | 1.1.0 | 3.x |
| glibc | 2.24 | 2.38+ |
| Kernel | 4.9 | 6.x |
| systemd | 232 | 254+ |
| Git | 2.11 | 2.43+ |

The gap is not a crack. It is a chasm.

## The Embedded Systems Reality

This is unfortunately common in the embedded world:

1. **Hardware vendor provides BSP** (Board Support Package) based on whatever Debian was current when they developed it
2. **Vendor moves on** to new products, old BSP fossilizes
3. **Users inherit** the maintenance burden or accept obsolescence
4. **Everyone pretends** this is fine

It is not fine. But it is reality.

## Recommendations

1. **Minimize attack surface** - Disable unnecessary services, use firewall rules, don't expose to internet
2. **Air-gap when possible** - The OptConnect cellular gateway provides NAT isolation at least
3. **Plan for replacement** - This board will eventually need to be replaced or deeply re-imaged
4. **Document everything** - Future you (or your replacement) will need to understand why things are the way they are

## Business Risk Assessment

**This section is not hyperbole. It is a frank assessment of operational risk.**

The TS-7800-v2 running Debian Stretch is being considered for deployment to field units. These are not lab curiosities - they are control boards that will operate critical systems in remote locations. When they fail, we cannot walk over and reboot them.

### The Risk Chain

```
Outdated OS → Unpatched vulnerabilities → Potential compromise
Outdated OS → Package incompatibility → Inability to update software
Outdated OS → Driver rot → Hardware integration failures
Hardware failure → System failure → Business failure
```

This is not theoretical. This is the path we are walking.

### Specific Concerns

1. **Security vulnerabilities are permanent** - Every CVE since June 2022 affects us. We cannot patch. We can only hope attackers don't notice.

2. **No vendor support path** - Technologic Systems provides Stretch. They do not provide security updates, upgrade paths, or long-term support commitments. We are on our own.

3. **Field recovery is expensive** - A bricked board in the field requires a truck roll, technician time, and system downtime. At scale, this is unsustainable.

4. **Cascading failures** - These boards control other systems. A compromised or malfunctioning board doesn't just fail itself - it fails everything downstream.

5. **Regulatory exposure** - Depending on deployment context, running EOL software may violate compliance requirements (SOC2, industry regulations, customer contracts).

### The Hard Questions

- What is our plan when a critical vulnerability is published for OpenSSL 1.1.0 and we cannot patch?
- What is our recovery procedure when boards fail in the field?
- What is our exit strategy from this platform?
- Are we documenting these risks for stakeholders and customers?

### Mitigation Strategies (Imperfect)

1. **Network isolation** - Never expose these boards directly to the internet. The OptConnect cellular gateway provides some isolation, but defense in depth is essential.

2. **Minimal attack surface** - Disable every unnecessary service. Remove every unnecessary package. Reduce exposure.

3. **Monitoring and alerting** - Detect anomalies before they become outages. Log everything. Watch for signs of compromise.

4. **Hardware redundancy** - Plan for board failures. Have spares. Have a deployment process that doesn't require physical presence.

5. **Platform migration roadmap** - Begin evaluating alternatives now. Whether that's newer Technologic hardware with modern OS support, or a different vendor entirely. This platform has a shelf life.

### Our Operational Reality

**Current deployment:**
- ~12 field units
- 2 two-person crews
- Site visit capacity: once per week (normal ops), once per month (during R&D)

**Failure recovery timeline:**
- Best case: 1 week to reach a failed unit
- During R&D crunch: 1 month
- If multiple units fail simultaneously: triage required, some units stay down

### Failure Projections

**Conservative estimate: 5% annual board failure rate**

| Year | Expected Failures | Cumulative Downtime (weeks) | Notes |
|------|-------------------|----------------------------|-------|
| 1 | 0-1 boards | 1-4 weeks | Manageable |
| 2 | 1-2 boards | 2-8 weeks | Strain on crews |
| 3 | 2-3 boards | 4-12 weeks | Customer impact likely |

**Pessimistic estimate: 15% annual failure rate** (factoring in software instability, driver issues, security events)

| Year | Expected Failures | Cumulative Downtime (weeks) | Notes |
|------|-------------------|----------------------------|-------|
| 1 | 1-2 boards | 2-8 weeks | Early warning signs |
| 2 | 2-4 boards | 4-16 weeks | Crews overwhelmed |
| 3 | 3-5 boards | 6-20 weeks | Systemic crisis |

### The Death Spiral Scenario

1. **Month 1-6**: Board failures are rare, handled ad-hoc. "See? It's fine."

2. **Month 6-12**: A few failures occur. Crews handle them, but R&D slows because crews are doing field repairs. Technical debt accumulates.

3. **Month 12-18**: Software bugs emerge that require updates. Updates require packages that don't exist on Stretch. Workarounds are applied. Complexity grows.

4. **Month 18-24**: A security incident occurs, or a driver fails permanently, or a critical bug is unfixable. Multiple units need simultaneous attention. Crews cannot keep up.

5. **Month 24-30**: Customer SLAs are missed. Reputation damage begins. Revenue impact. Staff burnout as crews are perpetually firefighting.

6. **Month 30+**: The cost of maintaining the platform exceeds the cost of replacing it, but there's no budget for replacement because revenue is down.

**Time to critical business impact: 18-30 months** (estimate)

**Time to existential threat: 30-48 months** (estimate, if no intervention)

### The Uncomfortable Math

With 2 crews and 12 units:
- Maximum sustainable failure rate: ~2 failures/month (1 per crew per 2 weeks)
- At 15% annual failure rate: ~2 failures/year per unit → 24 failures/year → 2/month
- **We are at the edge of sustainable operations assuming pessimistic failure rates**

Any of the following pushes us over:
- A bad driver update that bricks multiple units
- A security incident requiring emergency response to all units
- A hardware batch defect
- Staff turnover on the crews
- R&D period where crews are unavailable

### The Bottom Line

We are deploying 2017-era software to control systems our business depends on. This is a calculated risk. It should be a conscious decision made by stakeholders who understand the implications, not a default inherited from a vendor BSP.

**Failed control boards = failed systems = failed company.**

Document this risk. Escalate this risk. Plan for this risk.

## Silver Linings

- Shell scripts work the same as they did in 2017
- Basic networking tools are present
- The kernel is stable (if ancient)
- `apt-get` still functions for packages that exist in Stretch repos (via archive.debian.org)

We cope. We endure. We write documentation.

---

## Glossary for Software Engineers

**BSP (Board Support Package)** - A collection of drivers, bootloader, kernel, and root filesystem provided by a hardware vendor to get their board running Linux. Quality varies wildly.

**Debian Release Cycle** - Debian releases are named after Toy Story characters. Stretch (Debian 9) → Buster (Debian 10) → Bullseye (Debian 11) → Bookworm (Debian 12). Each release is supported for ~5 years.

**glibc** - The GNU C Library. Almost every Linux binary depends on it. Version mismatches mean binaries won't run. This is why static compilation exists.

**LTS (Long Term Support)** - Extended support period for stable releases. Debian LTS extends support beyond the standard window, but even LTS for Stretch ended in 2022.

**Cross-Compilation** - Building software on one architecture (your x86 laptop) to run on another (ARM board). Required when the target system is too slow or too constrained to compile locally.

**EOL (End of Life)** - When a software version stops receiving updates. Running EOL software is a security risk and a compliance nightmare.

**Backporting** - Taking a newer version of software and making it work on an older system. Often involves patching dependencies, recompiling, and extensive testing. Time-consuming and fragile.

**apt/dpkg** - Debian's package management. `apt` is the friendly interface, `dpkg` is the low-level tool. Both will disappoint you when packages don't exist.
