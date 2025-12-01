setTimeout(()=>{
    if (window.bobot_editor) {
        bobot_editor.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' || e.key === 'F2') e.preventDefault();
        });

        // Autocompletion
        window.lang_tools = ace.require("ace/ext/language_tools");

        window.editor = ace.edit("bobot-editor-text");
        editor.setTheme("ace/theme/monokai");
        editor.session.setMode("ace/mode/elixir");
        editor.setKeyboardHandler("ace/keyboard/vscode");
        editor.setOptions({
            printMarginColumn: 98,
            fixedWidthGutter: true,
            newLineMode: 'unix',
            enableBasicAutocompletion: true,
            enableSnippets: false,
            enableLiveAutocompletion: true,
            liveAutocompletionDelay: 500,
            liveAutocompletionThreshold: 3,
            tabSize: 2,       // Set the number of spaces for indentation (e.g., 4)
            useSoftTabs: true // Use spaces for indentation instead of tabs
        });

        lang_tools.setCompleters([{
            getCompletions: function(editor, session, pos, prefix, callback) {
                // Logic to generate Elixir-specific suggestions based on `prefix`
                // For example, you could provide suggestions for common Elixir modules or functions.
                console.log(pos, prefix)

                let prefix_len = prefix.trim().length;
                let real_column = pos.column - prefix_len;
                let indent_base = ' '.repeat(real_column);
                let indent = '  ';
                let do_end = `do\n${indent_base}${indent}\n${indent_base}end\n`;
                let completer = {
                    insertMatch: function(editor, data, parent) {
                        // console.log(data); 
                        parent.insertMatchOriginal(editor, data)
                        editor.gotoLine(pos.row + 1 + data.move.rows, real_column + data.move.cols);
                    }
                };
                
                var bobotWords = [
                    { 
                        caption: "defblock",
                        value: `defblock :name ${do_end}`, 
                        meta: "Define a block",
                        move: {rows: 0, cols: 10},
                        fromCol: 2,
                        completer: completer
                    },
                    { 
                        caption: "defblock ... receive",
                        value: `defblock :name, receive: vars ${do_end}`, 
                        meta: "Define a block",
                        move: {rows: 0, cols: 10},
                        fromCol: 2,
                        completer: completer
                    },
                    { 
                        caption: "defcommand",
                        value: `defcommand "/cmd" ${do_end}`, 
                        meta: "Define a command",
                        move: {rows: 0, cols: 13},
                        fromCol: 2,
                        completer: completer
                    },
                    { 
                        caption: "defchannel",
                        value: `defchannel :channel ${do_end}`, 
                        meta: "Define a channel",
                        move: {rows: 0, cols: 12},
                        fromCol: 2,
                        completer: completer
                    },
                    { 
                        caption: "defchannel ... description",
                        value: `defchannel :channel, description: "" ${do_end}`, 
                        meta: "Define a channel",
                        move: {rows: 0, cols: 12},
                        fromCol: 2,
                        completer: completer
                    },
                    { 
                        caption: "call_block",
                        value: `call_block :name`, 
                        meta: "Jump to a block",
                        move: {rows: 0, cols: 12},
                        completer: completer
                    },
                    { 
                        caption: "call_block ... params",
                        value: `call_block :name, params: <params>`, 
                        meta: "Jump to a block",
                        move: {rows: 0, cols: 12},
                        completer: completer
                    },
                    { 
                        caption: "break",
                        value: `break`, 
                        meta: "Abort running block and return",
                        move: {rows: 0, cols: 5},
                        completer: completer
                    },
                    { 
                        caption: "break ... returning",
                        value: `break returning: <value>`, 
                        meta: "Abort running block and return",
                        move: {rows: 0, cols: 17},
                        completer: completer
                    },
                    { 
                        caption: "session_data",
                        value: `session_data()`, 
                        meta: "Get session datas",
                        move: {rows: 0, cols: 14},
                        completer: completer
                    },
                    { 
                        caption: "session_value",
                        value: `session_value()`, 
                        meta: "Get session value",
                        move: {rows: 0, cols: 14},
                        completer: completer
                    },
                    { 
                        caption: "session_store",
                        value: `session_store()`, 
                        meta: "Set session value",
                        move: {rows: 0, cols: 14},
                        completer: completer
                    },
                    { 
                        caption: "every",
                        value: `every {{_year, _month, _day}, {_hour, _min, _}} ${do_end}`, 
                        meta: "Enqueue a periodic task",
                        move: {rows: 1, cols: 2},
                        fromCol: 2,
                        completer: completer
                    },
                    { 
                        caption: "every ... when",
                        value: `every {{_year, _month, _day}, {_hour, _min, _}}, when: (<guard>) ${do_end}`, 
                        meta: "Enqueue a periodic task",
                        move: {rows: 1, cols: 2},
                        fromCol: 2,
                        completer: completer
                    },
                    
                ];

                callback(null, bobotWords.filter(w => {
                    return real_column >= (w.fromCol??0) && w.caption.slice(0, prefix_len) == prefix                    
                }));
            }
        }]);


        // Keyboard Commands
        editor.commands.addCommand({
            name: 'commit',
            bindKey: {
                win: 'Ctrl-S',
                mac: 'Command-S'
            },
            exec: function(editor) {
                let e = new MouseEvent('click', {bubbles: true, cancelable: true})
                let btn = bobot_editor.querySelector('button.commit')
                btn.dispatchEvent(e);
                setTimeout(()=>editor.focus(), 200);
            },
            readOnly: false 
        });    
        editor.commands.addCommand({
            name: 'commit2',
            bindKey: {
                win: 'F2'
            },
            exec: function(editor) {
                let e = new MouseEvent('click', {bubbles: true, cancelable: true})
                let btn = bobot_editor.querySelector('button.commit')
                btn.dispatchEvent(e);
                setTimeout(()=>editor.focus(), 200);
            },
            readOnly: false 
        });    
        editor.commands.addCommand({
            name: 'cancel',
            bindKey: {
                win: 'Esc',
                mac: 'Esc'
            },
            exec: function(editor) {
                let e = new MouseEvent('click', {bubbles: true, cancelable: true})
                bobot_editor.querySelector('button.cancel').dispatchEvent(e);
            },
            readOnly: false 
        });
        editor.commands.addCommand({
            name: 'cancel2',
            bindKey: {
                win: 'Ctrl-Esc',
                mac: 'Command-Esc'
            },
            exec: function(editor) {
                let e = new MouseEvent('click', {bubbles: true, cancelable: true, ctrlKey: true})
                bobot_editor.querySelector('button.cancel').dispatchEvent(e);
            },
            readOnly: false 
        });

        // Status Bar
        const StatusBar = ace.require("ace/ext/statusbar").StatusBar;
        window.editor_status_bar = new StatusBar(editor, document.getElementById("editor-status-bar"));
    }

    window.addEventListener('keydown', function(e) {
        let keyb = e.key;
        if (e.ctrlKey) keyb = 'CTRL+' + keyb;
        let bt = document.querySelector('*[keyb="'+keyb+'"]');
        // console.log(e.key, e.ctrlKey, bt);
        
        if (bt) {
            e.preventDefault();
            bt.focus();
            bt.click()
            if (bt.tagName == 'SELECT') {
                bt.showPicker();
            }
        }
    });

}, 1000)
