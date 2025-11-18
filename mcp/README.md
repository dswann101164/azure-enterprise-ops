# MCP Server Configuration

Model Context Protocol (MCP) servers enable Claude Desktop to interact with external tools, data sources, and APIs. This directory contains the configuration for all MCP servers used in the AI-Ops environment.

## What is MCP?

Model Context Protocol is Anthropic's open standard for connecting AI assistants to external data and tools. Think of it as "plugins" for Claude Desktop - each MCP server provides a specific capability that Claude can use to help you.

## Configured Servers

### Official Anthropic MCP Servers

#### 1. **filesystem**
- **Purpose**: Read, write, and manipulate files on your local system
- **Use Cases**:
  - Analyzing Terraform state files
  - Reading Azure Resource Graph query results
  - Creating PowerShell scripts
  - Managing configuration files
- **Allowed Directories**: `C:\Users\YourUsername\Documents\GitHub\ai-ops2` and `C:\Users\YourUsername\Documents\GitHub`

#### 2. **git**
- **Purpose**: Git repository operations
- **Use Cases**:
  - Viewing commit history
  - Checking diffs
  - Managing branches
  - Reading repository metadata
- **Repository**: `C:\Users\YourUsername\Documents\GitHub\ai-ops2`

#### 3. **fetch**
- **Purpose**: Make HTTP requests to APIs
- **Use Cases**:
  - Calling Azure REST APIs
  - Querying Azure Resource Graph
  - Accessing Azure Cost Management APIs
  - Fetching Azure documentation

#### 4. **memory**
- **Purpose**: Persistent context storage across conversations
- **Use Cases**:
  - Remembering infrastructure patterns
  - Storing frequently used queries
  - Maintaining project context
  - Tracking cost optimization decisions

#### 5. **time**
- **Purpose**: Time and timezone operations
- **Use Cases**:
  - Scheduling VM shutdowns
  - Analyzing logs with timestamps
  - Planning maintenance windows
  - Cost reporting by time period

#### 6. **everything**
- **Purpose**: Windows desktop search integration
- **Use Cases**:
  - Finding Azure documentation files
  - Locating PowerShell scripts
  - Searching through logs
  - Discovering related projects

#### 7. **sequentialthinking**
- **Purpose**: Enhanced reasoning for complex tasks
- **Use Cases**:
  - Multi-step Azure deployments
  - Complex KQL query development
  - Cost optimization analysis
  - Troubleshooting workflows

### Community MCP Servers

#### 8. **windows-mcp**
- **Purpose**: Windows system operations
- **Use Cases**:
  - Executing PowerShell commands
  - Managing Windows services
  - File system operations
  - System configuration

## Installation

### Automatic (Recommended)

The `Deploy-AIOps.ps1` script automatically configures MCP servers:

```powershell
.\Deploy-AIOps.ps1
```

### Manual Configuration

1. **Locate Claude Desktop config**:
   ```powershell
   $configPath = "$env:APPDATA\Claude\claude_desktop_config.json"
   ```

2. **Backup existing config** (if present):
   ```powershell
   Copy-Item $configPath "$configPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
   ```

3. **Copy MCP configuration**:
   ```powershell
   Copy-Item .\mcp\servers.json $configPath
   ```

4. **Restart Claude Desktop**

## Verification

Test each server in Claude Desktop:

### filesystem
```
Claude: "List the contents of the ai-ops2 directory"
```

### git
```
Claude: "Show me the recent commits in this repository"
```

### fetch
```
Claude: "Fetch the latest Azure pricing information from the Azure API"
```

### memory
```
Claude: "Remember that our test resource group is rg-aiops-test"
```

### time
```
Claude: "What time is it in UTC?"
```

### everything
```
Claude: "Search my computer for Azure PowerShell scripts"
```

### windows-mcp
```
Claude: "Check the status of the Azure CLI on my system"
```

## Azure Integration

With these MCP servers, Claude can:

### 1. Query Azure Resources
```
You: "Show me all VMs in the test resource group"
Claude: [Uses filesystem + PowerShell to query Azure]
```

### 2. Analyze Costs
```
You: "What are my top 10 most expensive resources this month?"
Claude: [Queries Azure Cost Management API via fetch]
```

### 3. Create Infrastructure
```
You: "Create a Terraform module for an App Service"
Claude: [Uses filesystem to create .tf files with proper structure]
```

### 4. Document Architecture
```
You: "Document the current infrastructure with diagrams"
Claude: [Queries resources, creates Mermaid diagrams, saves to files]
```

### 5. Automated Remediation
```
You: "Find unattached disks and create a cleanup script"
Claude: [Queries Azure, generates PowerShell, saves script]
```

## Security Considerations

### File System Access
- MCP filesystem server only has access to specified directories
- Cannot access sensitive system folders
- All file operations are logged

### API Access
- MCP fetch server uses your Azure CLI authentication
- Respects Azure RBAC permissions
- API calls are made with your credentials

### Best Practices
1. Never store credentials in files accessible to MCP servers
2. Use Azure Key Vault for all secrets
3. Review Claude's actions before executing scripts
4. Keep audit logs of significant operations
5. Test in lab environment before production

## Troubleshooting

### MCP Server Not Loading

**Symptom**: Claude doesn't have access to a tool

**Solutions**:
1. Check config file location:
   ```powershell
   Get-Content "$env:APPDATA\Claude\claude_desktop_config.json"
   ```

2. Verify JSON syntax:
   ```powershell
   Get-Content "$env:APPDATA\Claude\claude_desktop_config.json" | ConvertFrom-Json
   ```

3. Restart Claude Desktop completely:
   - Close all Claude windows
   - End Claude process in Task Manager if necessary
   - Relaunch Claude Desktop

### npm/npx Errors

**Symptom**: MCP servers fail to start

**Solutions**:
1. Install Node.js (v18 or later):
   ```powershell
   winget install OpenJS.NodeJS.LTS
   ```

2. Clear npm cache:
   ```powershell
   npm cache clean --force
   ```

3. Update npm:
   ```powershell
   npm install -g npm@latest
   ```

### Permission Errors

**Symptom**: MCP servers can't access files/directories

**Solutions**:
1. Check directory permissions
2. Update allowed directories in config
3. Run Claude Desktop as administrator (not recommended for regular use)

### Azure Authentication Issues

**Symptom**: Claude can't query Azure resources

**Solutions**:
1. Verify Azure CLI login:
   ```powershell
   az account show
   ```

2. Re-authenticate if needed:
   ```powershell
   az login
   ```

3. Check service principal certificate:
   ```powershell
   Get-ChildItem .\aiops-cert-*.pem
   ```

## Advanced Configuration

### Custom Allowed Directories

Edit `servers.json` to add more directories:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "C:\\Users\\YourUsername\\Documents\\GitHub\\ai-ops2",
        "C:\\Users\\YourUsername\\Documents\\GitHub",
        "C:\\Path\\To\\Your\\Directory"
      ]
    }
  }
}
```

### Adding New MCP Servers

To add additional MCP servers:

1. Find the server on [MCP Directory](https://github.com/modelcontextprotocol)
2. Add configuration to `servers.json`:
   ```json
   "server-name": {
     "command": "npx",
     "args": ["-y", "@modelcontextprotocol/server-name"]
   }
   ```
3. Restart Claude Desktop
4. Test the new server

### Environment Variables

MCP servers can use environment variables:

```json
{
  "mcpServers": {
    "custom-server": {
      "command": "npx",
      "args": ["-y", "@custom/server"],
      "env": {
        "API_KEY": "your-api-key",
        "ENDPOINT": "https://api.example.com"
      }
    }
  }
}
```

## Resources

- [MCP Documentation](https://modelcontextprotocol.io/)
- [MCP GitHub Repository](https://github.com/modelcontextprotocol)
- [MCP Server Implementations](https://github.com/modelcontextprotocol/servers)
- [Claude Desktop Documentation](https://docs.anthropic.com/claude/docs)

## Example Workflows

See `../examples/` directory for detailed workflows:

- `query-resources.md` - Querying Azure resources with Claude
- `cost-analysis.md` - Cost optimization workflows
- `automation-scenarios.md` - Infrastructure automation examples

## Contributing

Found a useful MCP server for Azure operations? Add it to this configuration and submit a pull request!

---

**Need help?** Check the [troubleshooting guide](../docs/troubleshooting.md) or open an issue on GitHub.
