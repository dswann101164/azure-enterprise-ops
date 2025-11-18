# MCP Servers Documentation

Complete guide to the Model Context Protocol (MCP) servers configured for AI-Assisted Azure Operations.

## Table of Contents

1. [What is MCP?](#what-is-mcp)
2. [Server Overview](#server-overview)
3. [Individual Server Details](#individual-server-details)
4. [Configuration](#configuration)
5. [Advanced Usage](#advanced-usage)
6. [Troubleshooting](#troubleshooting)
7. [Building Custom Servers](#building-custom-servers)

---

## What is MCP?

**Model Context Protocol (MCP)** is an open standard for connecting AI models to external tools and data sources. It enables Claude Desktop to:

- Access local filesystems
- Execute commands
- Make HTTP requests
- Remember context across sessions
- Integrate with desktop applications

### Why MCP?

**Traditional Approach:**
```
User → Claude (web) → Copy command → Terminal → Execute → Copy output → Claude
```

**MCP Approach:**
```
User → Claude (desktop) → MCP Server → Direct execution → Claude
```

**Benefits:**
- No context switching
- Automated workflows
- Persistent memory
- Secure local execution
- Extensible architecture

---

## Server Overview

The AI-Ops environment includes 8 pre-configured MCP servers:

| Server | Purpose | Use Cases |
|--------|---------|-----------|
| **filesystem** | File operations | Read/write scripts, Terraform files, logs |
| **git** | Version control | Commit history, diffs, branch operations |
| **fetch** | HTTP requests | Azure APIs, documentation, web scraping |
| **memory** | Persistent context | Remember preferences, patterns, decisions |
| **time** | Temporal operations | Scheduling, timezones, date calculations |
| **everything** | Desktop search | Find files, documents, scripts |
| **sequentialthinking** | Complex reasoning | Multi-step deployments, troubleshooting |
| **windows-mcp** | Windows operations | PowerShell, services, system config |

### Server Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Claude Desktop                           │
│  (AI Model with Natural Language Understanding)            │
└────────────┬────────────────────────────────────────────────┘
             │ MCP Protocol (JSON-RPC over stdio)
             │
┌────────────▼────────────────────────────────────────────────┐
│              MCP Server Collection                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Each server runs as separate Node.js process       │  │
│  │  Communication via stdin/stdout                      │  │
│  │  Isolated execution environment                      │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────┬────────────────────────────────────────────────┘
             │ Server-specific protocols
             │
┌────────────▼────────────────────────────────────────────────┐
│           System Resources / APIs                           │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐  │
│  │Filesystem│   Git    │   HTTP   │  Memory  │ Windows  │  │
│  │   APIs   │  Commands│  Clients │  Storage │   APIs   │  │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Individual Server Details

### 1. Filesystem Server

**Package:** `@modelcontextprotocol/server-filesystem`

**Purpose:** Secure file and directory operations on local filesystem.

**Capabilities:**
- Read files (text, JSON, CSV, etc.)
- Write files
- Create directories
- List directory contents
- Search files
- File metadata (size, timestamps, permissions)

**Configuration:**
```json
{
  "filesystem": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-filesystem",
      "C:\\Users\\YourUsername\\Documents\\GitHub\\ai-ops2",
      "C:\\Users\\YourUsername\\Documents\\GitHub"
    ]
  }
}
```

**Allowed Directories:**
- Only paths specified in `args` are accessible
- Prevents accidental access to system files
- Add multiple paths as separate arguments

**Example Prompts:**
```
"Read the Terraform main.tf file and show me the Key Vault configuration"

"Create a new PowerShell script at C:\Users\YourUsername\Documents\GitHub\ai-ops2\scripts\query-vms.ps1"

"List all .tf files in the terraform directory"

"Search for files containing 'service-principal' in the ai-ops2 directory"
```

**Security Notes:**
- Cannot access paths outside allowed directories
- Cannot execute files (use bash/PowerShell for execution)
- File writes require explicit paths
- Symbolic links are not followed

---

### 2. Git Server

**Package:** `@modelcontextprotocol/server-git`

**Purpose:** Interact with Git repositories for version control.

**Capabilities:**
- View commit history
- Show file diffs
- List branches
- View repository status
- Analyze changes
- Read commit messages

**Configuration:**
```json
{
  "git": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-git",
      "--repository",
      "C:\\Users\\YourUsername\\Documents\\GitHub\\ai-ops2"
    ]
  }
}
```

**Example Prompts:**
```
"Show me the last 10 commits in this repository"

"What changed in the last commit to main.tf?"

"Show me all commits related to Key Vault configuration"

"What files were modified in the last 24 hours?"

"Compare the current Terraform configuration with the version from last week"
```

**Supported Operations:**
- `git log` - Commit history
- `git diff` - File changes
- `git show` - Commit details
- `git status` - Repository status
- `git branch` - Branch listing

**Security Notes:**
- Read-only operations only
- Cannot commit, push, or modify repository
- Respects .gitignore patterns
- Single repository per server instance

---

### 3. Fetch Server

**Package:** `@modelcontextprotocol/server-fetch`

**Purpose:** Make HTTP/HTTPS requests to external APIs and websites.

**Capabilities:**
- GET/POST/PUT/DELETE requests
- Custom headers
- Query parameters
- Response parsing (JSON, HTML, text)
- Follow redirects

**Configuration:**
```json
{
  "fetch": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-fetch"
    ]
  }
}
```

**Example Prompts:**
```
"Fetch the Azure status page and summarize any incidents"

"Make an API call to Azure Resource Graph to list all VMs"

"Download the Terraform Azure provider documentation"

"Check if azure-noob.com is accessible and show response time"
```

**Azure API Integration:**
```
User: "Query Azure Resource Graph for all VMs"

Claude:
1. Gets access token via Azure CLI
2. Makes POST to https://management.azure.com/providers/Microsoft.ResourceGraph/resources
3. Parses JSON response
4. Formats as table
```

**Security Notes:**
- Respects CORS policies
- No automatic authentication (must provide tokens)
- Rate limiting handled by target servers
- SSL/TLS certificate validation enabled

---

### 4. Memory Server

**Package:** `@modelcontextprotocol/server-memory`

**Purpose:** Persistent storage of context and preferences across Claude sessions.

**Capabilities:**
- Store key-value pairs
- Remember user preferences
- Save common queries
- Track project context
- Persist across Claude restarts

**Configuration:**
```json
{
  "memory": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-memory"
    ]
  }
}
```

**Example Prompts:**
```
"Remember that our production resource group is 'rg-prod-eastus'"

"What was the subscription ID I used last time?"

"Store this KQL query for future use"

"What Azure regions have we deployed to?"
```

**Storage Location:**
- Stored in Claude Desktop's app data directory
- Encrypted at rest (OS-level file encryption)
- Persists across Claude Desktop restarts
- Cleared when Claude Desktop is uninstalled

**Common Uses:**
- Subscription IDs
- Resource group names
- Naming conventions
- Common queries
- Deployment patterns

**Security Notes:**
- Do not store secrets or passwords
- Memory is local to your machine
- Backed up with Claude Desktop config
- Can be cleared manually

---

### 5. Time Server

**Package:** `@modelcontextprotocol/server-time`

**Purpose:** Time-related operations and timezone conversions.

**Capabilities:**
- Current time in any timezone
- Date calculations
- Time comparisons
- Scheduling helpers
- Duration formatting

**Configuration:**
```json
{
  "time": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-time"
    ]
  }
}
```

**Example Prompts:**
```
"What time is it in UTC right now?"

"Convert 2:00 PM EST to all Azure region timezones"

"How many days until our certificate expires on 2025-12-31?"

"When should I schedule maintenance in East US to minimize impact in Asia?"
```

**Azure-Specific Uses:**
- Auto-shutdown scheduling
- Log analysis across timezones
- Maintenance windows
- Cost report periods
- Certificate expiration tracking

---

### 6. Everything Server

**Package:** `@modelcontextprotocol/server-everything`

**Purpose:** Search entire desktop using Everything (Windows search tool).

**Capabilities:**
- Instant file search
- Search by name, extension, path
- Date/size filters
- Real-time index
- Fast results (milliseconds)

**Prerequisites:**
- **Everything by voidtools** must be installed
- Download: https://www.voidtools.com/

**Configuration:**
```json
{
  "everything": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-everything"
    ]
  }
}
```

**Example Prompts:**
```
"Find all .tf files on my computer"

"Where is my Azure service principal certificate?"

"Find PowerShell scripts modified in the last week"

"Locate all files named 'terraform.tfvars'"
```

**Search Syntax:**
- `*.tf` - All Terraform files
- `path:GitHub` - Files in GitHub folder
- `dm:today` - Modified today
- `size:>1mb` - Larger than 1MB

**Security Notes:**
- Searches entire accessible filesystem
- Respects NTFS permissions
- No file content indexing (name/metadata only)
- Local execution (no network traffic)

---

### 7. Sequential Thinking Server

**Package:** `@modelcontextprotocol/server-sequential-thinking`

**Purpose:** Enhanced reasoning for complex, multi-step problems.

**Capabilities:**
- Break down complex tasks
- Step-by-step reasoning
- Dependency tracking
- Error recovery strategies
- Decision trees

**Configuration:**
```json
{
  "sequentialthinking": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-sequential-thinking"
    ]
  }
}
```

**Example Prompts:**
```
"Plan a multi-region Azure deployment with these requirements: [...]"

"Troubleshoot why my Terraform apply is failing, checking each possible cause"

"Design a disaster recovery strategy for my Azure environment"

"Debug this PowerShell script that's producing unexpected results"
```

**How It Works:**
1. Receives complex task
2. Breaks into subtasks
3. Determines dependencies
4. Plans execution order
5. Executes with error handling
6. Adapts based on results

**Use Cases:**
- Complex Terraform deployments
- Troubleshooting cascading failures
- Architecture planning
- Cost optimization analysis
- Security audits

---

### 8. Windows MCP Server

**Package:** `@wonderwhy-er/windows-mcp`

**Purpose:** Windows-specific system operations.

**Capabilities:**
- Execute PowerShell commands
- Manage Windows services
- Read/write registry
- Process management
- System information

**Configuration:**
```json
{
  "windows-mcp": {
    "command": "npx",
    "args": [
      "-y",
      "@wonderwhy-er/windows-mcp"
    ]
  }
}
```

**Example Prompts:**
```
"Check if the Azure CLI service is running"

"Get system information (OS version, memory, CPU)"

"List all running processes related to Node.js"

"Execute this PowerShell script and show results"
```

**PowerShell Integration:**
```
User: "Run Get-AzVM and format as table"

Claude:
1. Validates PowerShell syntax
2. Executes via Windows MCP
3. Captures output
4. Formats for readability
```

**Security Notes:**
- Requires elevated permissions for some operations
- PowerShell execution policy applies
- Script validation recommended
- Audit logging advised

---

## Configuration

### Claude Desktop Configuration File

**Location:**
```
%APPDATA%\Claude\claude_desktop_config.json
```

**Full Configuration Example:**

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "C:\\Users\\YourUsername\\Documents\\GitHub",
        "C:\\Projects",
        "C:\\Work"
      ]
    },
    "git": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-git",
        "--repository",
        "C:\\Users\\YourUsername\\Documents\\GitHub\\ai-ops2"
      ]
    },
    "fetch": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-fetch"
      ]
    },
    "memory": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-memory"
      ]
    },
    "time": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-time"
      ]
    },
    "everything": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-everything"
      ]
    },
    "sequentialthinking": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sequential-thinking"
      ]
    },
    "windows-mcp": {
      "command": "npx",
      "args": [
        "-y",
        "@wonderwhy-er/windows-mcp"
      ]
    }
  }
}
```

### Adding Environment Variables

```json
{
  "mcpServers": {
    "custom-server": {
      "command": "npx",
      "args": ["-y", "@namespace/server"],
      "env": {
        "API_KEY": "your-api-key",
        "DEBUG": "true",
        "LOG_LEVEL": "info"
      }
    }
  }
}
```

### Multiple Repository Git Servers

```json
{
  "mcpServers": {
    "git-aiops": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-git",
        "--repository",
        "C:\\Users\\YourUsername\\Documents\\GitHub\\ai-ops2"
      ]
    },
    "git-blog": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-git",
        "--repository",
        "C:\\Users\\YourUsername\\Documents\\GitHub\\azure-noob-blog"
      ]
    }
  }
}
```

---

## Advanced Usage

### Chaining Multiple Servers

**Example: Create, execute, and commit script**

```
User: "Create a PowerShell script to list all VMs, execute it, and commit to Git"

Claude:
1. Uses filesystem server to create script.ps1
2. Uses windows-mcp to execute script
3. Captures output
4. Uses git server to verify repository status
5. Creates commit message based on changes
```

### Using Memory for Context

```
User: "Remember our naming convention: rg-{env}-{app}-{region}"

Claude: [Stores in memory server]

Later...

User: "Create a resource group for production web app in East US"

Claude: [Retrieves from memory]
Creates: rg-prod-web-eastus
```

### Fetch + Sequential Thinking

```
User: "Check Azure status, and if there's an incident affecting East US, 
analyze which of our resources are impacted"

Claude:
1. Uses fetch to get Azure status
2. Sequential thinking breaks down analysis:
   - Identify affected services
   - Query our resources (filesystem + previous analyses)
   - Determine overlap
   - Calculate impact
3. Generates report
```

---

## Troubleshooting

### Server Not Loading

**Check Node.js:**
```powershell
node --version
npm --version
# Must be 18.0+ for MCP servers
```

**Test server manually:**
```powershell
npx -y @modelcontextprotocol/server-filesystem C:\Users\YourUsername\Documents
# Should start without errors
```

**Check Claude Desktop logs:**
```
%APPDATA%\Claude\logs\
```

### Server Crashes

**Enable debug logging:**
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "C:\\Path"],
      "env": {
        "DEBUG": "*"
      }
    }
  }
}
```

**Common issues:**
- Path doesn't exist
- Insufficient permissions
- Package version mismatch
- Network timeout (fetch server)

### Permission Errors

**Filesystem server:**
```powershell
# Check directory permissions
Get-Acl "C:\Users\YourUsername\Documents\GitHub\ai-ops2" | Format-List

# Grant read access
icacls "C:\Path" /grant "$env:USERNAME:(OI)(CI)R"
```

**Windows MCP:**
- Run Claude Desktop as administrator (not recommended for regular use)
- Or grant specific permissions to required operations

### Performance Issues

**Too many allowed directories:**
- Filesystem server scans all allowed paths
- Limit to necessary directories only
- Use specific paths, not entire drives

**Slow search:**
- Ensure Everything is installed and running
- Rebuild Everything index
- Close unnecessary applications

---

## Building Custom Servers

### MCP Server Template

```typescript
// my-azure-server.ts
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

const server = new Server(
  {
    name: 'azure-ops-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define tool
server.setRequestHandler('tools/list', async () => {
  return {
    tools: [
      {
        name: 'query_azure',
        description: 'Query Azure resources using Resource Graph',
        inputSchema: {
          type: 'object',
          properties: {
            query: {
              type: 'string',
              description: 'KQL query to execute',
            },
          },
          required: ['query'],
        },
      },
    ],
  };
});

// Handle tool execution
server.setRequestHandler('tools/call', async (request) => {
  if (request.params.name === 'query_azure') {
    const { query } = request.params.arguments;
    
    // Execute Azure CLI command
    const { exec } = require('child_process');
    const result = await new Promise((resolve, reject) => {
      exec(`az graph query -q "${query}"`, (error, stdout, stderr) => {
        if (error) reject(error);
        else resolve(stdout);
      });
    });
    
    return {
      content: [
        {
          type: 'text',
          text: result,
        },
      ],
    };
  }
  
  throw new Error('Unknown tool');
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);
```

**Build and test:**

```powershell
# Install dependencies
npm install @modelcontextprotocol/sdk

# Compile TypeScript
npx tsc my-azure-server.ts

# Test locally
node my-azure-server.js
```

**Add to Claude Desktop:**

```json
{
  "mcpServers": {
    "azure-ops": {
      "command": "node",
      "args": ["C:\\Path\\To\\my-azure-server.js"]
    }
  }
}
```

### Publishing Custom Server

```powershell
# Create package.json
npm init

# Publish to npm
npm publish
```

**Then install via npx:**
```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "@yourusername/my-azure-server"]
    }
  }
}
```

---

## Best Practices

### 1. Minimize Allowed Paths
Only grant filesystem access to necessary directories.

### 2. Use Memory Server
Store frequently used values to reduce repetition.

### 3. Validate Before Execution
Review Claude-generated scripts before running via Windows MCP.

### 4. Regular Updates
Keep MCP servers updated:
```powershell
npm update -g
```

### 5. Monitor Resource Usage
MCP servers run as Node.js processes - check Task Manager if experiencing performance issues.

### 6. Backup Configuration
```powershell
Copy-Item "$env:APPDATA\Claude\claude_desktop_config.json" `
    "claude_desktop_config.backup.json"
```

---

## Resources

### Official Documentation
- [MCP Protocol Specification](https://modelcontextprotocol.io/spec)
- [MCP Server SDK](https://github.com/modelcontextprotocol/typescript-sdk)
- [Official MCP Servers](https://github.com/modelcontextprotocol/servers)

### Community Resources
- [MCP Server Directory](https://github.com/modelcontextprotocol/servers)
- [Community Servers](https://github.com/topics/mcp-server)

### Support
- [Anthropic Discord](https://discord.gg/anthropic)
- [GitHub Issues](https://github.com/modelcontextprotocol/typescript-sdk/issues)

---

**MCP servers are the foundation of AI-assisted Azure operations. Master them to unlock Claude's full potential for infrastructure automation!**
