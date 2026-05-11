"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const child_process_1 = require("child_process");
const LANGUAGE_ID = 'mire';
function activate(context) {
    const info = readRuntimeInfo();
    registerLanguageConfig();
    registerCompletionProvider(context);
    registerHoverProvider(context);
    registerDocumentSymbolProvider(context);
    registerSemanticTokensProvider(context);
    registerDiagnostics(context, info);
    registerCommands(context, info);
    registerProjectContext(context);
}
function deactivate() { }
function readRuntimeInfo() {
    const cfg = vscode.workspace.getConfiguration('mire');
    return {
        mirePath: cfg.get('runtimePath') || 'mire',
        owlPath: cfg.get('owlPath') || 'owl',
        enableDiagnostics: cfg.get('enableDiagnostics', true),
        useCompilerCheck: cfg.get('useCompilerCheck', false),
    };
}
function registerLanguageConfig() {
    vscode.languages.setLanguageConfiguration(LANGUAGE_ID, {
        comments: {
            lineComment: '//',
            blockComment: ['/*', '*/'],
        },
        brackets: [
            ['{', '}'],
            ['[', ']'],
            ['(', ')'],
        ],
        autoClosingPairs: [
            { open: '{', close: '}' },
            { open: '[', close: ']' },
            { open: '(', close: ')' },
            { open: '"', close: '"' },
            { open: "'", close: "'" },
        ],
        indentationRules: {
            increaseIndentPattern: /^\s*(?:fn|pub|struct|enum|impl|skill|match|if|elif|else|while|for|do|unsafe)\b.*\{\s*$/,
            decreaseIndentPattern: /^\s*\}/,
        },
    });
}
function registerProjectContext(context) {
    const refresh = async () => {
        const hasOwl = await hasWorkspaceFile('owl.toml');
        await vscode.commands.executeCommand('setContext', 'mire.isOwlProject', hasOwl);
    };
    refresh();
    const watcher = vscode.workspace.createFileSystemWatcher('**/owl.toml');
    watcher.onDidCreate(refresh);
    watcher.onDidDelete(refresh);
    watcher.onDidChange(refresh);
    context.subscriptions.push(watcher);
}
async function hasWorkspaceFile(glob) {
    const files = await vscode.workspace.findFiles(`**/${glob}`, '**/node_modules/**', 1);
    return files.length > 0;
}
function registerCommands(context, info) {
    const runFileCmd = vscode.commands.registerCommand('mire.runFile', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor || editor.document.languageId !== LANGUAGE_ID) {
            vscode.window.showWarningMessage('No active .mire file');
            return;
        }
        const terminal = vscode.window.createTerminal('Mire Run');
        terminal.sendText(`${info.mirePath} run "${editor.document.fileName}" --debug -O0`);
        terminal.show();
    });
    const checkFileCmd = vscode.commands.registerCommand('mire.checkFile', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor || editor.document.languageId !== LANGUAGE_ID) {
            vscode.window.showWarningMessage('No active .mire file');
            return;
        }
        const terminal = vscode.window.createTerminal('Mire Check');
        terminal.sendText(`${info.mirePath} check "${editor.document.fileName}"`);
        terminal.show();
    });
    const buildProjectCmd = vscode.commands.registerCommand('mire.buildProject', async () => {
        const terminal = vscode.window.createTerminal('Mire Build');
        terminal.sendText(`${info.mirePath} build --debug -O0`);
        terminal.show();
    });
    const owlRunCmd = vscode.commands.registerCommand('mire.owlRun', async () => {
        const terminal = vscode.window.createTerminal('Owl Run');
        terminal.sendText(`${info.owlPath} run --debug -O0`);
        terminal.show();
    });
    const owlBuildCmd = vscode.commands.registerCommand('mire.owlBuild', async () => {
        const terminal = vscode.window.createTerminal('Owl Build');
        terminal.sendText(`${info.owlPath} build --debug -O0`);
        terminal.show();
    });
    context.subscriptions.push(runFileCmd, checkFileCmd, buildProjectCmd, owlRunCmd, owlBuildCmd);
}
function registerCompletionProvider(context) {
    const provider = vscode.languages.registerCompletionItemProvider(LANGUAGE_ID, {
        provideCompletionItems(document, position) {
            if (isInString(document, position) || isInComment(document, position)) {
                return [];
            }
            const line = document.lineAt(position.line).text;
            const before = line.substring(0, position.character);
            const lower = before.toLowerCase();
            if (/\b(import|use)\s+[a-z0-9_\.]*$/i.test(before)) {
                return moduleCompletions();
            }
            if (/\b(set)\s+[a-z0-9_]*$/i.test(before)) {
                return variableSnippetCompletions();
            }
            if (/\b(fn|pub\s+fn)\s+[a-z0-9_]*$/i.test(before)) {
                return fnSnippetCompletions();
            }
            if (lower.trim().endsWith('.')) {
                return memberCompletions(lower);
            }
            return [
                ...keywordCompletions(),
                ...typeCompletions(),
                ...intrinsicCompletions(),
            ];
        },
    }, '.', ' ', ':');
    context.subscriptions.push(provider);
}
function keywordCompletions() {
    const defs = [
        ['fn', 'Function declaration'],
        ['pub fn', 'Public function declaration'],
        ['struct', 'Struct declaration'],
        ['enum', 'Enum declaration'],
        ['impl', 'Implementation block'],
        ['pub skill', 'Trait-like skill declaration'],
        ['import', 'Module import'],
        ['set', 'Variable binding'],
        ['if', 'Conditional'],
        ['match', 'Pattern match'],
        ['while', 'While loop'],
        ['for', 'For loop'],
        ['unsafe', 'Unsafe block'],
        ['extern fn', 'FFI function declaration'],
    ];
    return defs.map(([label, detail]) => makeCompletion(label, detail, label, vscode.CompletionItemKind.Keyword));
}
function fnSnippetCompletions() {
    return [
        makeCompletion('fn template', 'Function template', 'fn ${1:name}: (${2:args}) :${3:i64} {\n    $0\n}', vscode.CompletionItemKind.Snippet),
        makeCompletion('pub fn template', 'Public function template', 'pub fn ${1:name}: (${2:args}) :${3:i64} {\n    $0\n}', vscode.CompletionItemKind.Snippet),
    ];
}
function variableSnippetCompletions() {
    return [
        makeCompletion('set immutable', 'Immutable binding', 'set ${1:name} = ${2:value} :${3:i64}', vscode.CompletionItemKind.Snippet),
        makeCompletion('set mutable', 'Mutable binding', 'set ${1:name} = ${2:value} :${3:i64} mut', vscode.CompletionItemKind.Snippet),
    ];
}
function moduleCompletions() {
    const mods = ['std', 'math', 'strings', 'lists', 'dicts', 'time', 'fs', 'env', 'proc', './modules'];
    return mods.map((m) => makeCompletion(m, 'Module', m, vscode.CompletionItemKind.Module));
}
function memberCompletions(lower) {
    const table = {
        'lists.': ['push(list value)', 'pop(list)', 'get(list index)', 'len(list)', 'map(fn list)', 'filter(fn list)', 'fold(init fn list)'],
        'strings.': ['upper(str)', 'lower(str)', 'split(str sep)', 'replace(str old new)', 'contains(str sub)', 'len(str)', 'trim(str)'],
        'dicts.': ['get(map key)', 'set(map key value)', 'has(map key)', 'len(map)'],
        'time.': ['mark()', 'elapsed_ms(mark)', 'sleep_ms(ms)'],
        'fs.': ['read(path)', 'write(path data)', 'exists(path)', 'list(path)'],
        'env.': ['get(key)', 'set(key value)', 'args()', 'cwd()'],
        'proc.': ['run(cmd)', 'shell(cmd)'],
    };
    for (const [prefix, members] of Object.entries(table)) {
        if (lower.endsWith(prefix)) {
            return members.map((m) => makeCompletion(m, `${prefix} member`, m, vscode.CompletionItemKind.Function));
        }
    }
    return [];
}
function typeCompletions() {
    const types = ['i64', 'i32', 'i16', 'i8', 'u64', 'u32', 'u16', 'u8', 'f64', 'f32', 'bool', 'char', 'str', 'none'];
    return types.map((t) => makeCompletion(t, 'Type', t, vscode.CompletionItemKind.TypeParameter));
}
function intrinsicCompletions() {
    return [
        makeCompletion('dasu', 'Print to stdout', 'dasu(${1:value})', vscode.CompletionItemKind.Function),
        makeCompletion('ireru', 'Read from stdin', 'ireru()', vscode.CompletionItemKind.Function),
        makeCompletion('range', 'Range constructor', 'range(${1:end})', vscode.CompletionItemKind.Function),
        makeCompletion('true', 'Boolean true', 'true', vscode.CompletionItemKind.Constant),
        makeCompletion('false', 'Boolean false', 'false', vscode.CompletionItemKind.Constant),
        makeCompletion('none', 'Unit value', 'none', vscode.CompletionItemKind.Constant),
    ];
}
function makeCompletion(label, detail, insert, kind) {
    const item = new vscode.CompletionItem(label, kind);
    item.detail = detail;
    item.insertText = new vscode.SnippetString(insert);
    return item;
}
function isInString(document, position) {
    const line = document.lineAt(position.line).text;
    let open = null;
    for (let i = 0; i < position.character; i++) {
        const ch = line[i];
        const prev = i > 0 ? line[i - 1] : '';
        if ((ch === '"' || ch === "'") && prev !== '\\') {
            if (!open) {
                open = ch;
            }
            else if (open === ch) {
                open = null;
            }
        }
    }
    return open !== null;
}
function isInComment(document, position) {
    const line = document.lineAt(position.line).text;
    const left = line.substring(0, position.character);
    const idx = left.indexOf('//');
    return idx >= 0;
}
function registerHoverProvider(context) {
    const provider = vscode.languages.registerHoverProvider(LANGUAGE_ID, {
        provideHover(document, position) {
            const range = document.getWordRangeAtPosition(position);
            if (!range)
                return null;
            const w = document.getText(range);
            const info = {
                fn: '**fn**: define function',
                struct: '**struct**: define record type',
                enum: '**enum**: define variant type',
                impl: '**impl**: methods for a type',
                skill: '**skill**: trait-like contract',
                set: '**set**: bind variable',
                unsafe: '**unsafe**: opt into unsafe operations',
                dasu: '**dasu(x)**: print value',
                ireru: '**ireru()**: read input',
                range: '**range(...)**: iterable constructor',
                str: '**str**: string type',
                bool: '**bool**: boolean type',
                i64: '**i64**: 64-bit signed integer',
            };
            if (!info[w])
                return null;
            return new vscode.Hover(new vscode.MarkdownString(info[w]), range);
        },
    });
    context.subscriptions.push(provider);
}
function registerDocumentSymbolProvider(context) {
    const provider = vscode.languages.registerDocumentSymbolProvider(LANGUAGE_ID, {
        provideDocumentSymbols(document) {
            const out = [];
            const lines = document.getText().split('\n');
            const patterns = [
                { regex: /^(?:\s*pub\s+)?fn\s+([A-Za-z_][A-Za-z0-9_]*)\s*:/, kind: vscode.SymbolKind.Function, detail: 'function' },
                { regex: /^\s*struct\s+([A-Z][A-Za-z0-9_]*)\s*\{/, kind: vscode.SymbolKind.Struct, detail: 'struct' },
                { regex: /^\s*enum\s+([A-Z][A-Za-z0-9_]*)\s*\{/, kind: vscode.SymbolKind.Enum, detail: 'enum' },
                { regex: /^\s*impl\s+([A-Z][A-Za-z0-9_]*)\s*\{/, kind: vscode.SymbolKind.Class, detail: 'impl' },
                { regex: /^\s*(?:pub\s+)?skill\s+([A-Z][A-Za-z0-9_]*)\s*\{/, kind: vscode.SymbolKind.Interface, detail: 'skill' },
            ];
            for (let i = 0; i < lines.length; i++) {
                for (const p of patterns) {
                    const m = lines[i].match(p.regex);
                    if (!m)
                        continue;
                    const r = new vscode.Range(i, 0, i, lines[i].length);
                    out.push(new vscode.DocumentSymbol(m[1], p.detail, p.kind, r, r));
                }
            }
            return out;
        },
    });
    context.subscriptions.push(provider);
}
function registerSemanticTokensProvider(context) {
    const legend = new vscode.SemanticTokensLegend(['keyword', 'function', 'type', 'variable', 'number', 'string', 'comment', 'operator'], ['declaration', 'readonly']);
    const provider = {
        provideDocumentSemanticTokens(document) {
            const builder = new vscode.SemanticTokensBuilder(legend);
            const lines = document.getText().split('\n');
            const addMatches = (lineNo, regex, tokenType) => {
                const line = lines[lineNo];
                let m;
                regex.lastIndex = 0;
                while ((m = regex.exec(line))) {
                    builder.push(lineNo, m.index, m[0].length, legend.tokenTypes.indexOf(tokenType), 0);
                }
            };
            for (let i = 0; i < lines.length; i++) {
                addMatches(i, /\b(?:fn|pub|struct|enum|impl|skill|set|if|elif|else|while|for|match|unsafe|extern|import|return|use)\b/g, 'keyword');
                addMatches(i, /\b(?:i64|i32|i16|i8|u64|u32|u16|u8|f64|f32|bool|char|str|none|vec|map|arr|slice)\b/g, 'type');
                addMatches(i, /\b\d+(?:\.\d+)?\b/g, 'number');
                addMatches(i, /"(?:[^"\\]|\\.)*"/g, 'string');
                addMatches(i, /\/\/.*$/g, 'comment');
                addMatches(i, /\b(?:dasu|ireru|range|len|type)\b/g, 'function');
                addMatches(i, /\+|\-|\*|\/|%|==|!=|<=|>=|<|>|&&|\|\||!|\^|\|>|=>/g, 'operator');
            }
            return builder.build();
        },
    };
    context.subscriptions.push(vscode.languages.registerDocumentSemanticTokensProvider(LANGUAGE_ID, provider, legend));
}
function registerDiagnostics(context, info) {
    if (!info.enableDiagnostics) {
        return;
    }
    const collection = vscode.languages.createDiagnosticCollection('mire');
    context.subscriptions.push(collection);
    const lint = async (doc) => {
        if (doc.languageId !== LANGUAGE_ID)
            return;
        const diagnostics = [];
        diagnostics.push(...basicTextDiagnostics(doc));
        if (info.useCompilerCheck) {
            const fromCompiler = await compilerDiagnostics(doc, info.mirePath);
            diagnostics.push(...fromCompiler);
        }
        collection.set(doc.uri, diagnostics);
    };
    context.subscriptions.push(vscode.workspace.onDidOpenTextDocument(lint));
    context.subscriptions.push(vscode.workspace.onDidChangeTextDocument((e) => lint(e.document)));
    context.subscriptions.push(vscode.workspace.onDidSaveTextDocument(lint));
    context.subscriptions.push(vscode.workspace.onDidCloseTextDocument((doc) => collection.delete(doc.uri)));
    vscode.workspace.textDocuments.forEach(lint);
}
function basicTextDiagnostics(doc) {
    const out = [];
    const stack = [];
    const openers = { '{': '}', '(': ')', '[': ']' };
    const closers = { '}': '{', ')': '(', ']': '[' };
    const lines = doc.getText().split('\n');
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];
        if (/\bset\s+[A-Za-z_][A-Za-z0-9_]*\s*=\s*$/.test(line)) {
            out.push(new vscode.Diagnostic(new vscode.Range(i, 0, i, line.length), 'incomplete assignment: expected expression after "="', vscode.DiagnosticSeverity.Error));
        }
        if (/\b(?:fn|pub\s+fn)\s+[A-Za-z_][A-Za-z0-9_]*\s*$/.test(line.trim())) {
            out.push(new vscode.Diagnostic(new vscode.Range(i, 0, i, line.length), 'function declaration likely missing ": (args) :type" signature', vscode.DiagnosticSeverity.Warning));
        }
        if (/\bimport\s*$/.test(line.trim())) {
            out.push(new vscode.Diagnostic(new vscode.Range(i, 0, i, line.length), 'import missing module path', vscode.DiagnosticSeverity.Error));
        }
        const commentIdx = line.indexOf('//');
        const scan = commentIdx >= 0 ? line.substring(0, commentIdx) : line;
        for (let j = 0; j < scan.length; j++) {
            const ch = scan[j];
            if (openers[ch]) {
                stack.push({ ch, pos: new vscode.Position(i, j) });
            }
            else if (closers[ch]) {
                const top = stack.pop();
                if (!top || top.ch !== closers[ch]) {
                    out.push(new vscode.Diagnostic(new vscode.Range(i, j, i, j + 1), `unmatched closing '${ch}'`, vscode.DiagnosticSeverity.Error));
                }
            }
        }
    }
    for (const rem of stack) {
        out.push(new vscode.Diagnostic(new vscode.Range(rem.pos, rem.pos.translate(0, 1)), `unclosed '${rem.ch}'`, vscode.DiagnosticSeverity.Error));
    }
    return out;
}
async function compilerDiagnostics(doc, mirePath) {
    return new Promise((resolve) => {
        (0, child_process_1.execFile)(mirePath, ['check', doc.fileName], { timeout: 6000 }, (err, stdout, stderr) => {
            const text = `${stdout || ''}\n${stderr || ''}`;
            const lines = text.split('\n');
            const diagnostics = [];
            const locRe = /:(\d+):(\d+)/;
            for (const line of lines) {
                if (!(line.includes('error[') || line.includes('warning[')))
                    continue;
                const loc = line.match(locRe);
                if (!loc)
                    continue;
                const row = Math.max(0, Number(loc[1]) - 1);
                const col = Math.max(0, Number(loc[2]) - 1);
                const msg = line.replace(/\x1b\[[0-9;]*m/g, '').trim();
                diagnostics.push(new vscode.Diagnostic(new vscode.Range(row, col, row, col + 1), msg, line.includes('warning[') ? vscode.DiagnosticSeverity.Warning : vscode.DiagnosticSeverity.Error));
            }
            if (err && diagnostics.length === 0) {
                diagnostics.push(new vscode.Diagnostic(new vscode.Range(0, 0, 0, 1), `mire check failed: ${String(err)}`, vscode.DiagnosticSeverity.Warning));
            }
            resolve(diagnostics);
        });
    });
}
//# sourceMappingURL=extension.js.map