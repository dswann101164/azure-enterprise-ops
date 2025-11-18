# Architecture Overview

## System Design

The AI-Assisted Azure Operations environment consists of three main components working together to enable natural language interaction with Azure infrastructure:

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Layer                              │
│  ┌──────────────────┐           ┌─────────────────────────┐    │
│  │  Azure Portal    │           │    Claude Desktop       │    │
│  │  (Visual Mgmt)   │           │  (AI-Assisted Ops)      │    │
│  └────────┬─────────┘           └───────────┬─────────────┘    │
└───────────┼─────────────────────────────────┼──────────────────┘
            │                                 │
            │                                 │ MCP Protocol
            │                                 │
┌───────────▼─────────────────────────────────▼──────────────────┐
│                    Integration Layer                            │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────────┐  │
│  │  Azure CLI     │  │  MCP Servers   │  │   PowerShell    │  │
│  │  (Commands)    │  │  (8 Servers)   │  │   (Scripting)   │  │
│  └────────┬───────┘  └────────┬───────┘  └────────┬────────┘  │
└───────────┼──────────────────┼───────────────────┼────────────┘
            │                   │                   │
            │                   │                   │
            └───────────────────┼───────────────────┘
                                │
┌───────────────────────────────▼──────────────────────────────────┐
│                    Azure Infrastructure                          │
│  ┌──────────────┬────────────────┬────────────────┬──────────┐  │
│  │   Identity   │    Security    │   Compute      │ Storage  │  │
│  ├──────────────┼────────────────┼────────────────┼──────────┤  │
│  │ Service      │   Key Vault    │   Linux VM     │ Storage  │  │
│  │ Principal    │   (Secrets)    │   (B2s)        │ Account  │  │
│  │ (Cert Auth)  │   RBAC         │   Auto-Off     │ (LRS)    │  │
│  └──────────────┴────────────────┴────────────────┴──────────┘  │
│  ┌──────────────┬────────────────┬────────────────┬──────────┐  │
│  │  Networking  │   Monitoring   │  Governance    │   Cost   │  │
│  ├──────────────┼────────────────┼────────────────┼──────────┤  │
│  │  VNet        │  Log Analytics │   Tags         │  Budget  │  │
│  │  NSG         │  Diagnostics   │   Policies     │  Alerts  │  │
│  │  Public IP   │  Metrics       │   RBAC         │  Reports │  │
│  └──────────────┴────────────────┴────────────────┴──────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. User Layer

#### Claude Desktop
- **Role**: AI-powered interface for Azure operations
- **Capabilities**:
  - Natural language queries about infrastructure
  - Code generation (PowerShell, Terraform, KQL)
  - Documentation creation
  - Cost analysis and optimization
  - Automated remediation

#### Azure Portal
- **Role**: Traditional visual management interface
- **Use Cases**:
  - Initial resource verification
  - Visual topology understanding
  - Compliance and policy review
  - Cost Management dashboard

**Design Philosophy**: Claude Desktop complements (not replaces) Azure Portal. Use Portal for visual tasks, Claude for automation and analysis.

### 2. Integration Layer

#### MCP Servers (8 Configured)

**Official Anthropic Servers**:

1. **filesystem** - Local file operations
   - Read/write Terraform files
   - Manage PowerShell scripts
   - Store query results
   - Version control integration

2. **git** - Repository management
   - Commit history
   - Branch operations
   - Diff analysis
   - Change tracking

3. **fetch** - HTTP API calls
   - Azure REST APIs
   - Azure Resource Graph
   - Cost Management API
   - Documentation retrieval

4. **memory** - Persistent context
   - Infrastructure patterns
   - Common queries
   - Project preferences
   - Historical decisions

5. **time** - Temporal operations
   - Scheduling
   - Log analysis
   - Cost reporting
   - Maintenance windows

6. **everything** - Desktop search
   - Find documentation
   - Locate scripts
   - Search logs
   - Discover resources

7. **sequentialthinking** - Complex reasoning
   - Multi-step deployments
   - Query optimization
   - Troubleshooting workflows
   - Architecture planning

**Community Servers**:

8. **windows-mcp** - Windows system ops
   - PowerShell execution
   - Service management
   - System configuration
   - File operations

#### Azure CLI
- **Role**: Primary Azure interaction tool
- **Authentication**: User credentials or service principal
- **Usage**: Direct commands or via Claude

#### PowerShell
- **Role**: Scripting and automation
- **Modules**: Az PowerShell, Azure AD
- **Integration**: Called by Claude via MCP servers

### 3. Azure Infrastructure

#### Identity & Access

**Service Principal**
- Certificate-based authentication (no secrets)
- Contributor role on subscription
- Used for automated operations
- Certificate stored securely (never in Git)

**Key Vault**
- RBAC-enabled (no access policies)
- Stores VM passwords, SSH keys, SP details
- Audit logging enabled
- Soft delete protection

#### Compute

**Linux VM (Ubuntu 22.04)**
- Size: Standard_B2s (burstable, cost-effective)
- Auto-shutdown: 7 PM EST daily
- Boot diagnostics enabled
- SSH key authentication
- No public password auth

#### Storage

**Storage Account**
- Standard LRS (lowest cost)
- TLS 1.2 minimum
- Blob soft delete (7 days)
- Private container for diagnostics

#### Networking

**Virtual Network**
- Address space: 10.0.0.0/16
- Single subnet: 10.0.1.0/24
- NSG with restrictive rules
- Public IP for VM access

**Network Security Group**
- SSH allowed from specified IPs
- HTTPS outbound allowed
- All other traffic denied by default

#### Monitoring

**Log Analytics Workspace**
- 30-day retention
- Centralized logging
- VM insights integration
- Custom queries

**Diagnostic Settings**
- Key Vault audit logs
- VM metrics and logs
- Storage operations
- Network flow logs

#### Governance

**Resource Tags**
- Environment: Test
- Project: AI-Ops
- ManagedBy: Terraform
- Custom tags supported

**Budget Alerts**
- $50/month default
- 80% threshold notification
- Resource group scope
- Email notifications

## Data Flow Examples

### Example 1: Query Azure Resources

```
User → Claude Desktop
  ↓ MCP fetch server
Azure REST API
  ↓ JSON response
Claude Desktop → User
  ↓ Natural language + formatted data
```

### Example 2: Create Infrastructure Script

```
User → Claude Desktop
  ↓ MCP filesystem server
Create PowerShell script
  ↓ Save to local disk
Claude Desktop → User
  ↓ Script ready to execute
```

### Example 3: Cost Analysis

```
User → Claude Desktop
  ↓ MCP fetch server
Azure Cost Management API
  ↓ Cost data
MCP memory server
  ↓ Store patterns
Claude Desktop → User
  ↓ Analysis + recommendations
```

## Security Architecture

### Authentication Flow

```
┌──────────────┐
│    User      │
└──────┬───────┘
       │ Azure CLI login
       ▼
┌──────────────┐
│   Azure AD   │
└──────┬───────┘
       │ Token
       ▼
┌──────────────────────────────┐
│   Service Principal          │
│   (Certificate Auth)         │
└──────┬───────────────────────┘
       │ Authenticated
       ▼
┌──────────────────────────────┐
│   Azure Resources            │
│   (RBAC Controls Access)     │
└──────────────────────────────┘
```

### Security Layers

1. **Authentication**: Service principal with certificate
2. **Authorization**: RBAC at subscription/resource level
3. **Secrets Management**: Key Vault with audit logging
4. **Network Security**: NSG rules, private endpoints
5. **Monitoring**: All operations logged
6. **Compliance**: Tags for governance

### Least Privilege Model

- Service principal: Contributor (not Owner)
- Key Vault: Specific RBAC roles only
- VM: No password auth, SSH keys only
- Storage: Private containers only
- Network: Explicit allow rules

## Scalability Considerations

### Current Design (Test Environment)
- Single resource group
- One subscription
- Minimal resources
- Cost optimized

### Production Scaling Path
1. Multiple resource groups (dev/test/prod)
2. Hub-spoke network topology
3. Private endpoints for services
4. Centralized Key Vault
5. Shared services subscription
6. Landing zone architecture

### Cost Scaling
- Test: $20-35/month
- Small production: $100-500/month
- Medium production: $500-2000/month
- Enterprise: Custom sizing required

## Technology Choices

### Why Terraform?
- Infrastructure as code
- State management
- Consistent deployments
- Version control friendly
- Azure provider maturity

### Why Certificate Authentication?
- More secure than client secrets
- No password rotation needed
- Certificate expiration manageable
- Industry best practice
- Audit trail in Key Vault

### Why MCP Protocol?
- Open standard (not proprietary)
- Server ecosystem growing
- Local execution (security)
- Tool composability
- Active development

### Why Linux VM?
- Lower licensing costs
- Cloud-init support
- Better automation
- Docker ready
- OpenSSH native

## Limitations & Trade-offs

### Current Limitations
1. **Single subscription**: Designed for one subscription
2. **Test only**: Not production-hardened
3. **No HA**: Single region, single instance
4. **Basic networking**: No hub-spoke or ExpressRoute
5. **Limited monitoring**: Basic metrics only

### Intentional Trade-offs
1. **Security vs. Ease**: Public IP on VM (restrict via NSG)
2. **Cost vs. Features**: Standard tier (not Premium)
3. **Simplicity vs. Scale**: Single RG (easier management)
4. **Speed vs. Robustness**: Fast deployment (less validation)

### Enterprise Requirements Not Included
- Private Link / Service Endpoints
- Azure Firewall / NVAs
- DDoS Protection Standard
- ExpressRoute connectivity
- Multi-region replication
- Custom DNS
- Backup and DR
- WAF for web apps

## Extension Points

### Adding New Resources
1. Create new Terraform file in `terraform/`
2. Follow naming convention: `{resource-type}.tf`
3. Use local variables for consistency
4. Apply common tags
5. Add outputs
6. Document in README

### Adding MCP Servers
1. Find server on MCP directory
2. Add to `mcp/servers.json`
3. Test in Claude Desktop
4. Document capabilities
5. Add examples

### Connecting to Other Subscriptions
1. Update service principal scope
2. Add subscription IDs to variables
3. Configure Terraform providers
4. Test RBAC permissions
5. Update documentation

## Operational Patterns

### Daily Operations
- Query resource status via Claude
- Check costs and budgets
- Review security alerts
- Update resource tags
- Execute maintenance scripts

### Weekly Operations
- Review Log Analytics queries
- Analyze cost trends
- Update automation scripts
- Test backup/restore
- Update documentation

### Monthly Operations
- Security review
- Cost optimization analysis
- Tag compliance audit
- Service principal certificate check
- Infrastructure updates

## Disaster Recovery

### What's Protected
- Infrastructure code (in Git)
- MCP configuration (in Git)
- Documentation (in Git)

### What's Not Protected
- VM data (no backup configured)
- Storage account data (no replication)
- Key Vault secrets (export manually)
- Log Analytics data (retention-based)

### Recovery Process
1. Re-run `Deploy-AIOps.ps1`
2. Restore Git repository
3. Reconfigure Claude Desktop
4. Recreate manual configurations
5. Test all integrations

**Recovery Time Objective**: ~15 minutes
**Recovery Point Objective**: Last Git commit

## Monitoring & Alerting

### Key Metrics
- VM CPU/Memory utilization
- Storage account operations
- Key Vault access frequency
- Network throughput
- Cost per resource

### Alert Types
- Budget threshold exceeded
- VM availability < 99%
- Key Vault availability < 99%
- Security anomalies
- Certificate expiration (manual check)

### Logging
- All Azure operations logged
- MCP server operations visible in Claude
- Git commits track infrastructure changes
- PowerShell execution logs in console

## Future Enhancements

### Near Term (1-3 months)
- Azure Policy integration
- Custom MCP server for Azure-specific ops
- Automated cost reports
- Enhanced security baselines
- Multi-subscription support

### Medium Term (3-6 months)
- Hub-spoke networking
- Backup and DR automation
- Compliance as code
- Infrastructure testing framework
- SaaS product features

### Long Term (6+ months)
- Enterprise landing zone
- Multi-cloud support
- Advanced AI capabilities
- Commercial offering
- Community contributions

---

**This architecture is designed for learning and experimentation. Adapt it for your production needs with appropriate security, compliance, and scalability enhancements.**
