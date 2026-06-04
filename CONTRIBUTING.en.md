# 📖 Contribution Guide

> **Language / Idioma:** **[🟢 English]** | [Português](CONTRIBUTING.md)

Thank you for considering contributing to the **Armbian Amlogic Image Repacker**!

All contributions are welcome! There are several ways to collaborate with the project:

---

## 🐛 Reporting Bugs

Found a problem? Help us fix it!

1. Go to the [Issues](https://github.com/projetotvbox/armbian-amlogic-image-repacker/issues) tab
2. Check if the issue has already been reported
3. Open a new issue including:
   - Operating system and Linux distribution used
   - Armbian image model and version used
   - Full execution log (found in `./logs/`)
   - Detailed steps to reproduce the problem
   - Error messages shown in the terminal or dialog

---

## 📝 Improving Documentation

Clear documentation is essential! Contributions include:

- ✍️ Typo and grammar corrections
- 📚 Clarifications and text improvements
- 🌐 Translations to other languages
- 📊 Additional examples or diagrams
- 🎥 Video tutorials or illustrative images

> ⚠️ When updating documentation, always maintain parity between the **PT-BR** (`README.md`, `CONTRIBUTING.md`) and **English** (`README.en.md`, `CONTRIBUTING.en.md`) versions.

---

## 💻 Contributing Code

### Standard Contribution Flow

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/your-username/armbian-amlogic-image-repacker.git
   cd armbian-amlogic-image-repacker
   ```

3. **Create a branch for your feature**
   ```bash
   git checkout -b feature/MyFeature
   # Name examples:
   # - feature/custom-boot-size-support
   # - fix/uuid-detection-fix
   # - docs/update-requirements
   ```

4. **Make your changes**
   - Edit the necessary files
   - Test extensively

5. **Commit your changes**
   ```bash
   git add .
   git commit -m 'Add support for custom boot partition size'
   ```

   **Tips for commit messages:**
   - Use imperative verbs ("Add", "Fix", "Update")
   - Be specific and descriptive
   - Limit the first line to 50–72 characters
   - Add details in the body if necessary

6. **Push to your fork**
   ```bash
   git push origin feature/MyFeature
   ```

7. **Open a Pull Request**
   - Go to your fork on GitHub
   - Click "Compare & pull request"
   - Fill in the description in detail:
     - What was changed?
     - Why was it changed?
     - How to test?
     - Related issues (if any)

---

## ✅ Best Practices

When contributing code, follow these guidelines:

### Testing

- ✅ Test extensively before submitting
- ✅ Validate the result with a real Armbian image
- ✅ Confirm the repacked image boots correctly on the device
- ✅ Test error scenarios (e.g. user cancellation, missing dependencies, invalid image)
- ✅ Verify that cleanup works correctly on failure (loop devices detached, partitions unmounted)

### Commits

- ✅ Keep commits atomic (one logical change per commit)
- ✅ Use descriptive messages
- ✅ Avoid commits with "WIP" or "test" in the final history

### Code

- ✅ Follow the existing code style (bash script)
- ✅ Use uppercase and descriptive variable names
- ✅ Add log calls (`log_info`, `log_debug`, etc.) for relevant operations
- ✅ Use `dialog_assert_exit_status` after critical commands
- ✅ Declare local variables with `local` inside functions — and separate the declaration from the assignment when capturing command output:
   ```bash
   # Correct
   local MY_VAR
   MY_VAR=$(some-command)

   # Avoid — local swallows the command's exit code
   local MY_VAR=$(some-command)
   ```
- ✅ Add comments for complex logic

### Documentation

- ✅ Update the README if you add or change features
- ✅ Update code comments when necessary
- ✅ Maintain parity between PT-BR and EN versions

---

## 📋 Pull Request Checklist

Before submitting, verify:

- [ ] Script tested with a real Armbian image
- [ ] Repacked image validated (functional boot on device)
- [ ] Documentation updated in PT-BR and EN (if applicable)
- [ ] Commits organized with descriptive messages
- [ ] No temporary files, logs, or `.img` image files included in the commit
- [ ] Local variables correctly declared inside functions
- [ ] Clear and user-friendly error messages

---

## 💡 Questions?

If you have questions about how to contribute:

1. Read the full documentation in [README.en.md](README.en.md)
2. Check existing issues on [GitHub Issues](https://github.com/projetotvbox/armbian-amlogic-image-repacker/issues)
3. Open a discussion on [Discussions](https://github.com/projetotvbox/armbian-amlogic-image-repacker/discussions)

---

## 🙏 Acknowledgements

**🎉 Every contribution, no matter how small, makes a difference!**

This project is maintained by volunteers and is part of a social initiative at **IFSP Campus Salto**. Your contribution helps to:

- ♻️ Reduce electronic waste
- 🎓 Promote digital inclusion
- 🔧 Teach technology to students
- 🌍 Create positive social impact

**Thank you for being part of this initiative!** ❤️

---

## 📄 Code of Conduct

This project follows the principles of respect, collaboration, and inclusion. We expect all contributors to:

- Be respectful and constructive
- Accept constructive criticism
- Focus on what is best for the community
- Show empathy towards other members

---

**Developed for Projeto TVBox - Instituto Federal de São Paulo (IFSP), Campus Salto**
