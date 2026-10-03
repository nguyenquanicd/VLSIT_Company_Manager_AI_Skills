# Tạo và sử dụng Skill trong Codex trên Windows / Creating and Using Skills in Codex on Windows

Skill là một thư mục chứa hướng dẫn để Codex thực hiện một workflow lặp lại. / A skill is a folder of instructions that teaches Codex to perform a repeatable workflow.

## Các cách tạo / Ways to create a skill

1. **Dùng `$skill-creator` / Use `$skill-creator`:** mở Codex CLI trong repo, gọi `$skill-creator`, rồi mô tả mục tiêu, thời điểm dùng, đầu vào và đầu ra mong muốn. / Start Codex CLI in the repository, invoke `$skill-creator`, and describe the goal, when to use it, its inputs, and expected outputs.
2. **Tạo thủ công / Create it manually:** tạo thư mục riêng và file `SKILL.md` theo mẫu bên dưới. / Create a dedicated folder and a `SKILL.md` file using the example below.

## Đường dẫn trên Windows / Windows locations

**Trong repo hiện tại / In the current repository:**

```text
C:\HQuan\102_MyGithub\VLSIT_RTL_Generator_AI_Model\.agents\skills\rtl-hierarchy-diagram\SKILL.md
```

**Dùng cá nhân trong mọi repo của tài khoản `PC` / Personal skill for all repositories under account `PC`:**

```text
C:\Users\PC\.agents\skills\rtl-hierarchy-diagram\SKILL.md
```

Codex tìm skill trong `.agents\skills` của repo và các thư mục cha phù hợp. Nếu skill mới chưa xuất hiện, hãy khởi động lại Codex. / Codex discovers skills in the repository's `.agents\skills` folders and applicable parent folders. Restart Codex if a new skill does not appear. [Tài liệu chính thức / Official documentation](https://learn.chatgpt.com/docs/build-skills)

## Tạo thư mục thủ công / Create the folder manually

Chạy PowerShell từ thư mục gốc của repo / Run PowerShell from the repository root:

```powershell
New-Item -ItemType Directory -Force ".agents\skills\rtl-hierarchy-diagram"
notepad ".agents\skills\rtl-hierarchy-diagram\SKILL.md"
```

Sau đó dán nội dung tiếng Anh bên dưới vào `SKILL.md`. / Then paste the English skill below into `SKILL.md`.

## Ví dụ Skill phân tích RTL / RTL analysis skill example

Sơ đồ có nhiều trang trong cùng một file: mỗi trang biểu diễn một cấp hierarchy; tab `00_TOP` đứng đầu, tiếp theo là `01_LEVEL_1`, `02_LEVEL_2` và các cấp sâu hơn theo thứ tự trái sang phải. / The diagram uses multiple pages in one file: one page per hierarchy depth, with tabs ordered left to right from `00_TOP` through `01_LEVEL_1`, `02_LEVEL_2`, and deeper levels.

```markdown
---
name: rtl-hierarchy-diagram
description: Analyze existing Verilog or SystemVerilog RTL and create an editable draw.io block diagram of its hierarchy. Use when asked to understand RTL structure or map modules from the top module down to leaf modules.
---

# RTL Hierarchy Analysis and draw.io Diagram

Analyze existing RTL source code and produce an editable `.drawio` diagram. Do not modify the RTL source.

## Workflow

1. Locate the Verilog/SystemVerilog source files and relevant project files, such as build scripts, file lists, constraints, and configuration files.
2. Identify the top module from the user's instruction or project configuration. If multiple top-module candidates remain, state the candidates and the assumption used.
3. Trace module instantiations recursively from the top module through every child level. Record each instance name, module name, source file, and hierarchy depth. Account for generate blocks and parameter-dependent branches when the source makes them clear.
4. Do not invent missing modules, connections, or behavior. Mark unresolved or external modules explicitly and list the evidence or uncertainty.
5. Create one diagrams.net page/tab for each hierarchy depth inside the same `rtl_hierarchy.drawio` file. Name and order the pages `00_TOP`, `01_LEVEL_1`, `02_LEVEL_2`, and so on, with the top level first and deeper levels following. The XML page order must make the tabs appear from left to right in this same top-down order. On each page, show the modules at that depth, their immediate parent modules for context, and the parent-to-child connections; the `00_TOP` page shows the top module.
6. Create `rtl_hierarchy.drawio` in the workspace as an editable multi-page diagrams.net XML file. Label each block `instance_name : module_name`. Use solid black outlines for modules found in the source and dashed black outlines for unresolved or external modules.
7. Use black-and-white styling only: white block fills, black borders, black text, and black connectors. Do not use color accents, gradients, shadows, or colored status markers.
8. Set all visible diagram text to 18 pt. Size blocks to fit their labels with comfortable padding. Keep sibling blocks evenly spaced, center parent blocks over their children where practical, use clear top-to-bottom levels, and route connectors to avoid overlaps and unnecessary crossings. Choose page orientation and spacing to keep each page balanced and readable.
9. Check that the `.drawio` XML is well-formed, contains one correctly ordered page per hierarchy depth, and agrees with the source. If a diagram preview can be rendered, inspect it for clipped text, overlaps, or poor spacing before reporting completion.

## Output

- Save the editable multi-page diagram as `rtl_hierarchy.drawio` in the workspace, with one tab per level ordered from `00_TOP` left to right through the deepest level.
- Report the selected top module, the hierarchy covered, the source files inspected, and any unresolved branches.
- Do not describe the diagram as verified if its XML or rendered layout could not be checked.
```

## Cách dùng / How to use it

Mở Codex tại repo / Start Codex in the repository:

```powershell
cd C:\HQuan\102_MyGithub\VLSIT_RTL_Generator_AI_Model
codex
```

Trong prompt của Codex, gọi skill và nêu top module/thư mục RTL nếu đã biết. / At the Codex prompt, invoke the skill and specify the top module or RTL directory when known:

```text
$rtl-hierarchy-diagram Analyze the existing RTL in the rtl folder. Use cpu_top as the top module, trace all child modules, and save an editable black-and-white multi-page draw.io file as rtl_hierarchy.drawio. Create one tab per hierarchy level, ordered left to right from 00_TOP through the deepest level. Use 18 pt text and balanced layouts; show each level's modules with their immediate parents and connections for context.
```

Codex cũng có thể tự chọn skill nếu yêu cầu khớp với `description`; dùng `/skills` để xem skill được nhận diện. / Codex may also select the skill when a request matches its `description`; use `/skills` to see discovered skills.
