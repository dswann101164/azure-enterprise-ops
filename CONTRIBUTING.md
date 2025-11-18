# Contributing to AI-Ops2

Thank you for your interest in contributing to the AI-Assisted Azure Operations project!

## Ways to Contribute

### 1. Report Issues
Found a bug or have a feature request? [Open an issue](https://github.com/yourusername/ai-ops2/issues) with:
- Clear description of the problem or feature
- Steps to reproduce (for bugs)
- Expected vs actual behavior
- Your environment (OS, PowerShell version, Azure CLI version)

### 2. Improve Documentation
Documentation is critical for this project. You can help by:
- Fixing typos or unclear explanations
- Adding examples for common scenarios
- Translating documentation
- Creating video tutorials or blog posts

### 3. Add Features
Want to add new functionality? Great! Please:
- Open an issue first to discuss the feature
- Follow the existing code style
- Add tests if applicable
- Update documentation

### 4. Share Your Experience
- Write a blog post about using this project
- Share on social media
- Give a talk at a meetup
- Help others in discussions/issues

## Development Setup

### Prerequisites
- Windows 10/11
- PowerShell 7.0+
- Azure CLI 2.50.0+
- Terraform 1.5.0+
- Node.js 18.0+ LTS
- Git
- Claude Desktop

### Fork and Clone
```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/ai-ops2.git
cd ai-ops2
```

### Test Changes Locally
```powershell
# Test Terraform
cd terraform
terraform init
terraform validate
terraform plan

# Test PowerShell scripts
Invoke-Pester -Script "./tests/*.tests.ps1"

# Test deployment script
.\Deploy-AIOps.ps1 -SkipPrerequisiteCheck
```

## Contribution Guidelines

### Code Style
- **PowerShell**: Follow [PowerShell Best Practices](https://poshcode.gitbooks.io/powershell-practice-and-style/)
- **Terraform**: Use `terraform fmt` before committing
- **Markdown**: Use consistent heading levels and formatting

### Commit Messages
Use clear, descriptive commit messages:
```
Good: Add auto-shutdown configuration for VMs
Bad: fix stuff

Good: Fix Key Vault RBAC assignment in terraform
Bad: update
```

### Pull Request Process
1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Make your changes
3. Test thoroughly
4. Update documentation
5. Commit with clear messages
6. Push to your fork
7. Open a Pull Request with:
   - Description of changes
   - Why the change is needed
   - How to test it
   - Screenshots (if UI changes)

### Branch Naming
- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation only
- `refactor/description` - Code improvements

## Code Review Process

All contributions require review before merging:
1. Automated checks must pass (if configured)
2. At least one maintainer approval
3. All comments addressed
4. Documentation updated

## Testing

### Manual Testing
```powershell
# Test deployment
.\Deploy-AIOps.ps1

# Verify MCP servers
# Open Claude Desktop and test each server

# Test cleanup
cd terraform
terraform destroy
```

### Automated Testing
```powershell
# Run all tests
Invoke-Pester

# Run specific test
Invoke-Pester -Script "./tests/terraform.tests.ps1"
```

## Documentation Standards

### Markdown Files
- Use proper heading hierarchy (h1 → h2 → h3)
- Include table of contents for long documents
- Add code examples with syntax highlighting
- Use tables for structured data
- Include screenshots where helpful

### Code Comments
```powershell
# Good: Explains WHY, not WHAT
# Rotate certificate to maintain security compliance
Invoke-CertificateRotation

# Bad: States the obvious
# Call the function
Invoke-CertificateRotation
```

### README Updates
When adding features, update README with:
- Feature description
- Usage examples
- Configuration options
- Known limitations

## Security

### Reporting Vulnerabilities
**DO NOT** open public issues for security vulnerabilities.

Instead:
1. Email: security@azure-noob.com
2. Include detailed description
3. Steps to reproduce
4. Potential impact
5. Suggested fix (if any)

We'll respond within 48 hours.

### Security Best Practices
- Never commit secrets or credentials
- Use Key Vault for sensitive data
- Follow least privilege principle
- Test in isolated environment first
- Review security implications of changes

## Community Guidelines

### Be Respectful
- Treat everyone with respect
- Welcome newcomers
- Be patient with questions
- Give constructive feedback
- Celebrate contributions

### Be Professional
- Keep discussions on-topic
- No spam or self-promotion
- No offensive or inappropriate content
- Respect differing viewpoints

## Questions?

- Open a [Discussion](https://github.com/yourusername/ai-ops2/discussions)
- Comment on existing issues
- Email: contact@azure-noob.com

## Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in blog posts (if applicable)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for making AI-Ops2 better!** 🚀
