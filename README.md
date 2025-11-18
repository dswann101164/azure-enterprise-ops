# Azure Enterprise Operations

> Real-world Azure operational templates and documentation from enterprise-scale deployments. No vendor fluff, no basic tutorials — just the stuff that actually works at scale.

**By [David Swann](https://azure-noob.com)** | Azure Architect specializing in enterprise-scale operations

---

## Why This Exists

Microsoft's documentation shows you *how to create* Azure resources. This repository shows you *how to actually operate* them at enterprise scale — the gap between "tutorial complete" and "production at 3 AM."

This is the operational reality that:
- Cloud Adoption Framework glosses over
- MVPs don't blog about (because it's not sexy)
- You can't learn from certifications
- Your vendor won't tell you (because it makes their product look hard)

**For more context, see my blog: [azure-noob.com](https://azure-noob.com)**

---

## What's Inside

### 📚 [Documentation (`/docs`)](./docs)
Enterprise operational patterns based on running Azure at scale:

- **[Architecture Patterns](./docs/architecture.md)** - Hub-spoke networking, governance at scale, migration strategies
- **[Security Operations](./docs/security.md)** - Real NSG rules, Key Vault patterns, Azure AD integration
- **[Troubleshooting Guide](./docs/troubleshooting.md)** - Common production issues and actual fixes
- **[MCP Servers](./docs/mcp-servers.md)** - AI-assisted Azure administration with Model Context Protocol

### 💡 [Examples (`/examples`)](./examples)
Working code and real scenarios, not proof-of-concepts:

- **[Automation Scenarios](./examples/automation-scenarios.md)** - End-to-end automation patterns for common tasks
- **[Cost Analysis](./examples/cost-analysis.md)** - FinOps queries, cost allocation strategies, budget automation
- **[Query Resources](./examples/query-resources.md)** - Azure Resource Graph KQL queries for inventory and analysis

### 🏗️ [Terraform (`/terraform`)](./terraform)
Production-ready infrastructure code:

- Test resource deployment
- Key Vault configuration
- Modular design patterns
- Variables and outputs for reuse

### 🤖 [MCP Integration (`/mcp`)](./mcp)
AI-powered Azure operations using Model Context Protocol servers

---

## Who This Is For

- **Azure Architects** managing multi-subscription environments
- **Cloud Engineers** dealing with real operational problems
- **FinOps Teams** trying to allocate costs in complex environments
- **Merger/Acquisition Teams** consolidating Azure infrastructures
- **Anyone tired of vendor documentation** that assumes simple scenarios

---

## The Gap This Fills

**Vendor Documentation Says:**
> "Deploy your first VM in 5 minutes!"

**Enterprise Reality:**
- Which subscription goes in which management group?
- How do we handle cost allocation when applications span multiple subscriptions?
- What's our NSG rule strategy across dozens of subscriptions?
- How do we migrate multiple Active Directory domains during a merger?

This repository addresses the **second set of questions**.

---

## Not Included

❌ Basic "getting started" tutorials (Azure Docs does this fine)  
❌ Certification exam prep (plenty of boot camps for that)  
❌ Vendor marketing materials (you have LinkedIn for that)  
❌ Theoretical architecture (you need working solutions)

---

## Getting Started

### Prerequisites
- Azure subscription(s) with appropriate permissions
- Azure CLI or PowerShell Az module
- Basic understanding of Azure Resource Manager
- Terraform (for infrastructure code)

### Quick Start
1. Browse [`/docs`](./docs) for operational patterns
2. Check [`/examples`](./examples) for working code
3. Review [`SETUP.md`](./SETUP.md) for detailed configuration

### Contributing
See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for guidelines on:
- Suggesting KQL queries
- Submitting operational patterns
- Reporting issues
- Code review process

---

## Philosophy

### 1. Applications, Not Subscriptions
Subscriptions are administrative boundaries. Applications are your real organizational units for cost management and governance.

### 2. Search, Don't Memorize
Azure has 200+ services with thousands of configuration options. The skill isn't memorization — it's knowing how to find answers quickly.

### 3. Automate the Boring Stuff
If you're clicking through the portal daily, you're doing it wrong. Automate repetitive tasks so you can focus on architecture.

### 4. Document What Surprised You
When you hit a problem that Azure docs didn't cover, write it down. That's your edge over the competition.

---

## Related Resources

- **Blog Post**: [Why I Open-Sourced This Repository](https://azure-noob.com/blog/open-source-enterprise-azure-ops/) - The story and strategy behind building portable IP
- **Blog**: [azure-noob.com](https://azure-noob.com) - In-depth articles on enterprise Azure operations
- **Azure Resource Graph**: [Official Docs](https://learn.microsoft.com/azure/governance/resource-graph/)
- **FinOps Foundation**: [finops.org](https://www.finops.org/)
- **Cloud Adoption Framework**: [Microsoft CAF](https://learn.microsoft.com/azure/cloud-adoption-framework/)

---

## License

MIT License - See [LICENSE](./LICENSE) for details.

Free to use, modify, and distribute. Attribution appreciated but not required.

---

## About the Author

**David Swann** maintains [azure-noob.com](https://azure-noob.com), documenting real-world Azure operational challenges that don't make it into vendor documentation or certification courses.

**Connect**: Blog comments or GitHub issues (not on LinkedIn due to employer policy)

---

## Disclaimer

This repository contains generalized examples and patterns. It does not include any proprietary code, company-specific configurations, or sensitive information.

All examples use RFC 1918 private addressing, placeholder values, and generic naming conventions.

---

**⭐ Star this repo** if you find it useful — helps others discover real-world Azure operations content.

**🔗 Share your own patterns** via pull requests — the community benefits when we share operational reality.
