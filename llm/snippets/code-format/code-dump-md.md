### Code dump format

The code dump(s) for this project are:

- <FILL>

Each dump is a flat text file beginning with a `Project Path:` line and a `Source Tree:` ASCII tree covering only its own slice of the repo, followed by a `## Code` section. Within that section, every file is introduced by a header line that is its backtick-wrapped, repo-relative path ending in a colon, immediately followed by a fenced code block with a language hint inferred from the extension. Files are separated only by the next path header.

Three parsing gotchas:

- Every content line inside a block is prefixed with a right-aligned line number and `|` (e.g. `  12 |     code`). This prefix is display-only. Strip it before using the content, including when constructing exact-match strings for edits.
- Markdown files can contain their own nested fences, so the first inner fence is not necessarily the end of a file. The block's own fence is always longer than any backtick run inside it, using four or more backticks when needed, so an inner fence never closes the block. Treat the next path header as the true file boundary.
- Some code might be intentionally omitted to save tokens. For example, a frontend dump might exclude boilerplate and primitive components, and a backend dump might exclude the repositories module. If a decision depends on code that isn't in the dumps, say so and ask for it. Base every decision on the actual code, never on assumptions.
