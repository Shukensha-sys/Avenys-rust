import * as vscode from 'vscode';

const LANGUAGE_ID = 'mire';

function activate(context: vscode.ExtensionContext) {
    console.log('[Mire] Language extension activated');
    
    const config = vscode.workspace.getConfiguration('mire');
    const runtimePath = config.get<string>('runtimePath') || 'mire';
    
    registerCompletionProvider(context);
    registerHoverProvider(context);
    registerDocumentSymbolProvider(context);
    registerCommands(context, runtimePath);
    
    vscode.languages.setLanguageConfiguration(LANGUAGE_ID, {
        comments: {
            lineComment: '//',
            blockComment: ['/*', '*/']
        },
        brackets: [
            ['{', '}'],
            ['[', ']'],
            ['(', ')']
        ],
        autoClosingPairs: [
            { open: '{', close: '}' },
            { open: '[', close: ']' },
            { open: '(', close: ')' },
            { open: '"', close: '"' },
            { open: "'", close: "'" }
        ],
        indentationRules: {
            increaseIndentPattern: new RegExp('^\\s*(fn|pub|struct|enum|impl|skill|match|if|elif|else|while|for|do|unsafe)\\s*.*\\{$'),
            decreaseIndentPattern: new RegExp('^\\s*\\}')
        }
    });
}

function deactivate() {}

function registerCommands(context: vscode.ExtensionContext, runtimePath: string) {
    const runFileCmd = vscode.commands.registerCommand('mire.runFile', async () => {
        const editor = vscode.window.activeTextEditor;
        if (!editor || !editor.document.fileName.endsWith('.mire')) {
            vscode.window.showWarningMessage('No .mire file active');
            return;
        }
        
        const filePath = editor.document.fileName;
        const terminal = vscode.window.createTerminal('Mire Output');
        terminal.sendText(`${runtimePath} "${filePath}"`);
        terminal.show();
    });
    
    context.subscriptions.push(runFileCmd);
}

function registerCompletionProvider(context: vscode.ExtensionContext) {
    const provider = vscode.languages.registerCompletionItemProvider(
        LANGUAGE_ID,
        {
            provideCompletionItems(document, position, token) {
                const line = document.lineAt(position.line).text;
                const beforeCursor = line.substring(0, position.character);
                const afterCursor = line.substring(position.character);
                
                const textBefore = beforeCursor.trim();
                const textAfter = afterCursor.trim();
                
                if (textBefore.length === 0 && textAfter.length === 0) {
                    return getTopLevelCompletions();
                }
                
                if (isInString(document, position) || isInComment(document, position)) {
                    return [];
                }
                
                return getSmartCompletions(textBefore, textAfter, document, position);
            }
        },
        ...[' ', ':', '.']
    );
    
    context.subscriptions.push(provider);
}

function isInString(document: vscode.TextDocument, position: vscode.Position): boolean {
    const line = document.lineAt(position.line).text;
    let inString = false;
    let stringChar = '';
    
    for (let i = 0; i < position.character; i++) {
        const char = line[i];
        if (!inString && (char === '"' || char === "'")) {
            inString = true;
            stringChar = char;
        } else if (inString && char === stringChar && line[i-1] !== '\\') {
            inString = false;
        }
    }
    
    return inString;
}

function isInComment(document: vscode.TextDocument, position: vscode.Position): boolean {
    const line = document.lineAt(position.line).text;
    const beforeCursor = line.substring(0, position.character);
    
    if (beforeCursor.includes('//')) {
        const lastComment = beforeCursor.lastIndexOf('//');
        const lastString = beforeCursor.lastIndexOf('"');
        return lastComment > lastString;
    }
    
    let inBlockComment = false;
    for (let i = 0; i < position.line; i++) {
        const prevLine = document.lineAt(i).text;
        if (prevLine.includes('/*') && !prevLine.includes('*/')) {
            inBlockComment = true;
        }
        if (prevLine.includes('*/')) {
            inBlockComment = false;
        }
    }
    
    return inBlockComment;
}

function getTopLevelCompletions(): vscode.CompletionItem[] {
    const items: vscode.CompletionItem[] = [
        createCompletion('fn', 'Function declaration', 'fn ${1:name}: ($2) :${3:i64} {\n    $0\n}', 'keyword'),
        createCompletion('pub fn', 'Public function', 'pub fn ${1:name}: ($2) :${3:i64} {\n    $0\n}', 'keyword'),
        createCompletion('struct', 'Struct declaration', 'struct ${1:Name} {\n    ${2:field} :${3:i64}\n}', 'keyword'),
        createCompletion('enum', 'Enum declaration', 'enum ${1:Name} {\n    ${2:Variant}\n}', 'keyword'),
        createCompletion('impl', 'Implementation block', 'impl ${1:Type} {\n    fn ${2:method}: (self) :${3:i64} {\n        $0\n    }\n}', 'keyword'),
        createCompletion('pub skill', 'Skill (trait)', 'pub skill ${1:Name} {\n    fn ${2:method}: (self) :${3:str}\n}', 'keyword'),
        createCompletion('import', 'Import module', 'import ${1:std}', 'keyword'),
        createCompletion('set', 'Variable binding', 'set ${1:name} = ${2:value} :${3:type}', 'keyword'),
        createCompletion('if', 'If statement', 'if ${1:condition} {\n    $0\n}', 'keyword'),
        createCompletion('while', 'While loop', 'while ${1:condition} {\n    $0\n}', 'keyword'),
        createCompletion('for', 'For loop', 'for ${1:i} in range(${2:10}) {\n    $0\n}', 'keyword'),
        createCompletion('match', 'Match expression', 'match ${1:expr} {\n    ${2:Pattern} { $0 }\n    _ { }\n}', 'keyword'),
        createCompletion('unsafe', 'Unsafe block', 'unsafe {\n    $0\n}', 'keyword'),
        createCompletion('extern lib', 'Extern library', 'extern lib "${1:c}" "${2:libc.so.6}"', 'keyword'),
        createCompletion('extern fn', 'Extern function', 'extern fn ${1:name}: ($2) :${3:i64} lib "${4:c}"', 'keyword'),
    ];
    
    return items;
}

function getSmartCompletions(textBefore: string, textAfter: string, document: vscode.TextDocument, position: vscode.Position): vscode.CompletionItem[] {
    const items: vscode.CompletionItem[] = [];
    const wordMatch = textBefore.match(/([a-zA-Z_][a-zA-Z0-9_]*)$/);
    const word = wordMatch ? wordMatch[1] : '';
    
    if (word.length < 1) {
        return items;
    }
    
    const keywordMap: Record<string, vscode.CompletionItem[]> = {
        'fn': [
            createCompletion('fn', 'Function name', '${1:name}: ($2) :${3:i64} {\n    $0\n}', 'keyword'),
        ],
        'pub': [
            createCompletion('pub fn', 'Public function', 'fn ${1:name}: ($2) :${3:i64} {\n    $0\n}', 'keyword'),
            createCompletion('pub skill', 'Public skill', 'skill ${1:Name} {\n    fn ${2:method}: (self) :${3:str}\n}', 'keyword'),
        ],
        'struc': [
            createCompletion('struct', 'Struct name', 't ${1:Name} {\n    ${2:field} :${3:i64}\n}', 'keyword'),
        ],
        'struct': [
            createCompletion('struct', 'Struct field', ' ${1:field} :${2:i64}', 'keyword'),
        ],
        'enum': [
            createCompletion('enum', 'Enum variant', ' ${1:Variant}', 'keyword'),
            createCompletion('enum', 'Enum variant with value', ' ${1:Variant}(${2:value} :${3:i64})', 'keyword'),
        ],
        'impl': [
            createCompletion('impl', 'Method name', ' fn ${1:method}: (self) :${2:i64} {\n    $0\n}', 'keyword'),
        ],
        'skill': [
            createCompletion('skill', 'Skill method', ' fn ${1:method}: (self) :${2:str}', 'keyword'),
        ],
        'match': [
            createCompletion('match', 'Match pattern', ' ${1:Pattern} { $0 }', 'keyword'),
        ],
        'if': [
            createCompletion('if', 'Condition', '${1:condition} {\n    $0\n}', 'keyword'),
            createCompletion('if', 'If with else', '${1:condition} {\n    $0\n} else {\n    \n}', 'keyword'),
        ],
        'elif': [
            createCompletion('elif', 'Else-if condition', '${1:condition} {\n    $0\n}', 'keyword'),
        ],
        'else': [
            createCompletion('else', 'Else block', '{\n    $0\n}', 'keyword'),
        ],
        'while': [
            createCompletion('while', 'Loop condition', '${1:condition} {\n    $0\n}', 'keyword'),
        ],
        'for': [
            createCompletion('for', 'Loop variable', '${1:i} in range(${2:10}) {\n    $0\n}', 'keyword'),
        ],
        'do': [
            createCompletion('do', 'Do block', '{\n    $0\n}', 'keyword'),
        ],
        'ret': [
            createCompletion('return', 'Return value', 'rn ${1:value}', 'keyword'),
        ],
        'return': [
            createCompletion('return', 'Return value', ' ${1:value}', 'keyword'),
        ],
        'imp': [
            createCompletion('import', 'Import name', 'ort ${1:std}', 'keyword'),
        ],
        'import': [
            createCompletion('import', 'Module name', ' ${1:strings}', 'keyword'),
        ],
        'set': [
            createCompletion('set', 'Variable name', ' ${1:name} = ${2:value} :${3:type}', 'keyword'),
        ],
        'uns': [
            createCompletion('unsafe', 'Unsafe block', 'e {\n    $0\n}', 'keyword'),
        ],
        'unsafe': [
            createCompletion('unsafe', 'Unsafe body', ' {\n    $0\n}', 'keyword'),
        ],
        'ex': [
            createCompletion('extern', 'Extern library', 'tern lib "${1:c}" "${2:libc.so.6}"', 'keyword'),
        ],
        'extern': [
            createCompletion('extern', 'Extern function', ' fn ${1:name}: ($2) :${3:i64} lib "${4:c}"', 'keyword'),
        ],
        'lis': [
            createCompletion('lists', 'lists module', 'ts', 'module'),
        ],
        'lists.': [
            createCompletion('lists.push', 'Push to list', 'push(${1:list} ${2:value})', 'function'),
            createCompletion('lists.pop', 'Pop from list', 'pop(${1:list})', 'function'),
            createCompletion('lists.len', 'List length', 'len(${1:list})', 'function'),
            createCompletion('lists.map', 'Map over list', 'map((${1:x}) => ${2:x * 2}, ${3:list})', 'function'),
            createCompletion('lists.filter', 'Filter list', 'filter((${1:x}) => ${2:x > 0}, ${3:list})', 'function'),
            createCompletion('lists.fold', 'Fold list', 'fold(${1:acc}, (${2:acc} ${3:elem}) => ${4:acc + elem}, ${5:list})', 'function'),
        ],
        'str': [
            createCompletion('strings', 'strings module', 'ings', 'module'),
        ],
        'strings.': [
            createCompletion('strings.upper', 'Uppercase', 'upper(${1:str})', 'function'),
            createCompletion('strings.lower', 'Lowercase', 'lower(${1:str})', 'function'),
            createCompletion('strings.split', 'Split string', 'split(${1:str} ${2:sep})', 'function'),
            createCompletion('strings.replace', 'Replace', 'replace(${1:str} ${2:old} ${3:new})', 'function'),
            createCompletion('strings.contains', 'Contains', 'contains(${1:str} ${2:sub})', 'function'),
            createCompletion('strings.len', 'String length', 'len(${1:str})', 'function'),
        ],
        'math': [
            createCompletion('math', 'math module', '', 'module'),
        ],
        'math.': [
            createCompletion('math.abs', 'Absolute value', 'abs(${1:n})', 'function'),
            createCompletion('math.min', 'Minimum', 'min(${1:a} ${2:b})', 'function'),
            createCompletion('math.max', 'Maximum', 'max(${1:a} ${2:b})', 'function'),
            createCompletion('math.sum', 'Sum', 'sum(${1:list})', 'function'),
        ],
        'dict': [
            createCompletion('dicts', 'dicts module', 's', 'module'),
        ],
        'dicts.': [
            createCompletion('dicts.get', 'Get value', 'get(${1:map} ${2:key})', 'function'),
            createCompletion('dicts.set', 'Set value', 'set(${1:map} ${2:key} ${3:value})', 'function'),
            createCompletion('dicts.has', 'Has key', 'has(${1:map} ${2:key})', 'function'),
            createCompletion('dicts.len', 'Dict length', 'len(${1:map})', 'function'),
        ],
        'time': [
            createCompletion('time', 'time module', '', 'module'),
        ],
        'time.': [
            createCompletion('time.mark', 'Mark time', 'mark()', 'function'),
            createCompletion('time.elapsed_ms', 'Elapsed ms', 'elapsed_ms(${1:mark})', 'function'),
            createCompletion('time.sleep_ms', 'Sleep ms', 'sleep_ms(${1:ms})', 'function'),
        ],
        'fs': [
            createCompletion('fs', 'fs module', '', 'module'),
        ],
        'fs.': [
            createCompletion('fs.read', 'Read file', 'read("${1:file.txt}")', 'function'),
            createCompletion('fs.write', 'Write file', 'write("${1:file.txt}" "${2:data}")', 'function'),
            createCompletion('fs.exists', 'Check exists', 'exists("${1:path}")', 'function'),
            createCompletion('fs.list', 'List directory', 'list("${1:path}")', 'function'),
        ],
        'env': [
            createCompletion('env', 'env module', '', 'module'),
        ],
        'env.': [
            createCompletion('env.get', 'Get env var', 'get("${1:KEY}")', 'function'),
            createCompletion('env.set', 'Set env var', 'set("${1:KEY}" "${2:value}")', 'function'),
            createCompletion('env.cwd', 'Current directory', 'cwd()', 'function'),
        ],
    };
    
    const lowerWord = word.toLowerCase();
    
    for (const [key, completions] of Object.entries(keywordMap)) {
        if (lowerWord === key || lowerWord.startsWith(key)) {
            for (const comp of completions) {
                items.push(comp);
            }
        }
    }
    
    if (items.length === 0) {
        const typeCompletions = getTypeCompletions(lowerWord);
        items.push(...typeCompletions);
    }
    
    if (items.length === 0) {
        const intrinsicCompletions = getIntrinsicCompletions(lowerWord);
        items.push(...intrinsicCompletions);
    }
    
    return items;
}

function getTypeCompletions(word: string): vscode.CompletionItem[] {
    const types = ['i64', 'i32', 'i16', 'i8', 'u64', 'u32', 'u16', 'u8', 'f64', 'f32', 'bool', 'char', 'str', 'none'];
    const items: vscode.CompletionItem[] = [];
    
    for (const t of types) {
        if (t.startsWith(word)) {
            items.push(createCompletion(t, 'Type: ' + t, t, 'type'));
        }
    }
    
    return items;
}

function getIntrinsicCompletions(word: string): vscode.CompletionItem[] {
    const intrinsics = [
        { label: 'dasu', detail: 'Print to stdout' },
        { label: 'ireru', detail: 'Read from stdin' },
        { label: 'range', detail: 'Create range [0, n)' },
        { label: 'true', detail: 'Boolean true' },
        { label: 'false', detail: 'Boolean false' },
        { label: 'none', detail: 'Unit type' },
    ];
    const items: vscode.CompletionItem[] = [];
    
    for (const i of intrinsics) {
        if (i.label.startsWith(word)) {
            items.push(createCompletion(i.label, i.detail, i.label, 'constant'));
        }
    }
    
    return items;
}

function createCompletion(label: string, detail: string, insertText: string, kind: string): vscode.CompletionItem {
    const item = new vscode.CompletionItem(label);
    item.detail = detail;
    
    const kindMap: Record<string, vscode.CompletionItemKind> = {
        'keyword': vscode.CompletionItemKind.Keyword,
        'type': vscode.CompletionItemKind.TypeParameter,
        'function': vscode.CompletionItemKind.Function,
        'module': vscode.CompletionItemKind.Module,
        'constant': vscode.CompletionItemKind.Constant,
    };
    
    item.kind = kindMap[kind] || vscode.CompletionItemKind.Keyword;
    item.insertText = new vscode.SnippetString(insertText);
    
    return item;
}

function registerHoverProvider(context: vscode.ExtensionContext) {
    const provider = vscode.languages.registerHoverProvider(LANGUAGE_ID, {
        provideHover(document, position) {
            const range = document.getWordRangeAtPosition(position);
            if (!range) return null;
            
            const word = document.getText(range);
            
            const hoverData: Record<string, string> = {
                'fn': '**fn** - Function declaration\n```mire\nfn add: (a :i64, b :i64) :i64 {\n    return a + b\n}\n```',
                'pub': '**pub** - Public visibility',
                'struct': '**struct** - Struct type\n```mire\nstruct Point {\n    x :i64\n    y :i64\n}\n```',
                'enum': '**enum** - Enum type\n```mire\nenum Color {\n    Red\n    Green\n    Blue\n}\n```',
                'impl': '**impl** - Implementation block',
                'skill': '**skill** - Trait declaration',
                'match': '**match** - Pattern matching',
                'if': '**if** - Conditional',
                'while': '**while** - While loop',
                'for': '**for** - For loop\n```mire\nfor i in range(10) { }\n```',
                'set': '**set** - Variable binding\n```mire\nset x = 10 :i64\nset y = "hello" :str mut\n```',
                'mut': '**mut** - Mutable modifier',
                'import': '**import** - Import module',
                'unsafe': '**unsafe** - Unsafe block',
                'dasu': '**dasu** - Print to stdout\n```mire\nuse dasu("Hello!")\n```',
                'ireru': '**ireru** - Read from stdin',
                'range': '**range** - Create range [0, n)',
                'i64': '**i64** - 64-bit signed integer',
                'i32': '**i32** - 32-bit signed integer',
                'u64': '**u64** - 64-bit unsigned integer',
                'bool': '**bool** - Boolean (true/false)',
                'str': '**str** - String',
                'char': '**char** - Character',
                'none': '**none** - Unit type',
            };
            
            const info = hoverData[word];
            if (info) {
                return new vscode.Hover(new vscode.MarkdownString(info), range);
            }
            
            return null;
        }
    });
    
    context.subscriptions.push(provider);
}

function registerDocumentSymbolProvider(context: vscode.ExtensionContext) {
    const provider = vscode.languages.registerDocumentSymbolProvider(LANGUAGE_ID, {
        provideDocumentSymbols(document, token) {
            const symbols: vscode.DocumentSymbol[] = [];
            const text = document.getText();
            const lines = text.split('\n');
            
            const patterns = [
                { regex: /^(?:pub\s+)?fn\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*:/, kind: vscode.SymbolKind.Function, detail: 'function' },
                { regex: /^struct\s+([A-Z][a-zA-Z0-9_]*)\s*\{/, kind: vscode.SymbolKind.Struct, detail: 'struct' },
                { regex: /^enum\s+([A-Z][a-zA-Z0-9_]*)\s*\{/, kind: vscode.SymbolKind.Enum, detail: 'enum' },
                { regex: /^impl\s+([A-Z][a-zA-Z0-9_]*)\s*\{/, kind: vscode.SymbolKind.Class, detail: 'impl' },
                { regex: /^pub\s+skill\s+([A-Z][a-zA-Z0-9_]*)\s*\{/, kind: vscode.SymbolKind.Interface, detail: 'skill' },
            ];
            
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];
                
                for (const pattern of patterns) {
                    const match = line.match(pattern.regex);
                    if (match) {
                        const symbol = new vscode.DocumentSymbol(
                            match[1],
                            pattern.detail,
                            pattern.kind,
                            new vscode.Range(i, 0, i, line.length),
                            new vscode.Range(i, 0, i, line.length)
                        );
                        symbols.push(symbol);
                    }
                }
            }
            
            return symbols;
        }
    });
    
    context.subscriptions.push(provider);
}

export { activate, deactivate };