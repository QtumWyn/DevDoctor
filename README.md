DevDoctor

DevDoctor is an early-stage system diagnostics CLI written in Zig. It runs diagnostic checks, presents a readable terminal report, and provides structured JSON output for use by graphical frontends and other tools.

Current features

Checks whether configured commands are available

Reports passed and failed checks

Human-readable terminal output

Versioned JSON output for frontend integrations

Requirements

Zig 0.16.0

Running DevDoctor

Human-readable output:

zig run src/main.zig

JSON output:

zig run src/main.zig -- --json

The JSON report currently uses schema version 1 and is intended to be the interface between the Zig diagnostics engine and future graphical frontends.

Project status

DevDoctor is under active early development. Additional diagnostic categories, configuration options, documentation, and a graphical frontend are planned.

License

DevDoctor is licensed under the Mozilla Public License 2.0. See LICENSE for details.