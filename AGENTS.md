# RimWorld Mod Development — Agent Instructions

## 1. Project Purpose

This workspace is used to develop, maintain, test, and package multiple independent RimWorld mods.

Mods may include:
- Texture and graphical add-ons.
- XML definitions and patches.
- Gene, race, body-part, and anatomy integrations.
- Gameplay features and mechanics.
- C# assemblies and Harmony patches.
- Compatibility patches for existing mods.
- Developer tools for inspecting, validating, and testing mods.

Keep each mod's implementation independent unless code sharing is explicitly justified.

## 2. Core Development Principles

- Inspect the existing project structure and instructions before making changes.
- Verify the actual RimWorld version, installed mod versions, APIs, definitions, and implementation details before relying on them.
- Prefer the smallest implementation that satisfies the requested feature.
- Reuse existing definitions, extension points, and rendering or gameplay systems where appropriate.
- Prefer XML and asset-only solutions when they fully support the intended behavior.
- Introduce C# or Harmony only when the existing systems cannot provide the required functionality.
- Do not add unnecessary dependencies, frameworks, abstractions, or configuration layers.
- Do not introduce gameplay mechanics when the request concerns presentation alone.
- Preserve existing game and mod behavior outside the requested scope.
- Clearly distinguish verified findings from assumptions and unresolved questions.

## 3. Workspace and Mod Isolation

- Treat each directory under `mods/` as an independent mod project.
- Each mod must have its own `About/About.xml`, assets, definitions, patches, source code, and packaging configuration as required.
- Do not assume every mod needs C#, XML Defs, or the same folder structure.
- Keep dependencies specific to the mod that requires them.
- Do not introduce cross-mod runtime dependencies merely to share a small amount of code.
- Put reusable developer utilities, templates, and documentation in appropriate shared directories.
- Do not copy entire installed mods or Workshop directories into this repository without a clear need.
- Keep distributable mod contents separate from development-only files and tooling.
- Follow any more specific instructions defined in a mod's own `AGENTS.md`.

## 4. Source Inspection and Compatibility

Before implementing a change involving an existing mod:

1. Identify the relevant mod, its version, and its dependencies.
2. Locate the definitions, assets, methods, and patches responsible for the behavior.
3. Trace the relevant data and execution flow.
4. Check for existing extension points and competing patches.
5. Determine the minimum compatible implementation.
6. Document any version assumptions or unresolved compatibility risks.

When source code is available, inspect it directly. When only compiled assemblies or definitions are available, use the evidence that can actually be verified.

Never invent Def names, XML fields, method signatures, texture paths, or APIs.

Use the existing mod-repair project and its available reports or tools when they can help identify conflicts, definitions, dependencies, or relevant source files. Do not assume those tools are installed, operational, or complete without checking.

## 5. Safe Modification Practices

- Never modify installed RimWorld or Workshop mod files directly.
- Make changes only within the development workspace or another explicitly authorized development directory.
- Do not modify saves, player settings, or load order without explicit authorization.
- Do not overwrite user-created work without first understanding its purpose.
- Before significant edits, inspect the Git working tree and preserve unrelated changes.
- Prefer small, reviewable changes over large rewrites.
- Do not delete existing features or assets merely because they appear unused.
- Ask before performing destructive operations or changing the intended scope.
- Do not install packages, change system configuration, or require administrator privileges without justification and authorization.

## 6. XML, Assets, and Defs

- Follow RimWorld's actual naming, loading, and directory conventions.
- Verify XML structure, Def inheritance, referenced Defs, patch operations, and dependency availability.
- Use existing asset conventions and inspect image dimensions, orientation, transparency, and naming requirements.
- Ensure texture paths correspond to actual files and match the renderer's expectations.
- Check patch conditions and load order when interacting with other mods.
- Avoid duplicate definitions or patches that unintentionally override unrelated mods.
- Prefer graceful fallbacks when optional content or assets are absent, where the underlying system supports them.

## 7. C# and Harmony

When C# is required:

- Target the appropriate RimWorld and .NET/Mono environment for the installed game version.
- Inspect available assemblies and references before writing code.
- Follow the APIs and method signatures actually available in the target version.
- Keep patches narrowly scoped and avoid unnecessary transpilers or broad method replacements.
- Check compatibility with existing Harmony patches where feasible.
- Handle absent optional mods and unsupported definitions safely.
- Keep source code, build outputs, and distributable assemblies organized.
- Do not claim code compiles or works in-game unless it has actually been verified.

## 8. Testing and Diagnostics

Use the strongest available validation for each change.

Where applicable:
- Validate XML syntax and patch targets.
- Verify all referenced Defs and assets exist.
- Build C# projects against the correct references.
- Confirm required dependencies and load order.
- Test with a disposable save or controlled test environment.
- Inspect Player.log for new errors and warnings.
- Check for regressions when optional mods are absent.
- Record test conditions, results, and unresolved issues.

Do not assume the presence of Python, a compiler, RimWorld assemblies, or other tools. Check the environment first and propose a practical alternative if a tool is unavailable.

Do not treat the absence of logged errors as proof that every feature works correctly.

## 9. Git and Project Documentation

- Use Git to track source changes and provide recoverable checkpoints.
- Do not commit secrets, personal paths, credentials, unnecessary logs, or temporary build artifacts.
- Do not ignore source files or assets needed to reproduce or build a mod.
- Keep READMEs, dependency lists, and installation instructions accurate.
- Document meaningful compatibility assumptions and non-obvious implementation decisions.
- Keep generated reports separate from authoritative source files.
- Never rewrite Git history or discard existing changes without authorization.

## 10. Workflow for New Features

For each requested feature:

1. Clarify the intended behavior and constraints.
2. Inspect the relevant mod and workspace instructions.
3. Investigate the existing implementation and dependencies.
4. Propose the simplest viable design.
5. Identify expected file changes and compatibility risks.
6. Implement in small, understandable steps.
7. Validate the result using available tools.
8. Summarize changed files, behavior, tests performed, and remaining limitations.

For investigations explicitly requested as read-only, do not modify files or implement changes.

## 11. Communication

- Explain important architectural choices concisely.
- Prefer concrete file paths, Def names, class names, and methods over vague descriptions.
- State when information is inferred rather than verified.
- Do not claim to have run tests, inspected files, or checked compatibility unless that work was performed.
- Avoid feature creep: implement the requested behavior first and leave unrelated improvements for later.