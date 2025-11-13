function editor_set_text(text) {
    editor.setValue(text);
}

function editor_set_title(title) {
    block_editor.setAttribute('data-title', title)
}

function editor_set_status_bar(text) {
    document.querySelector('#editor-status-bar > .info').innerHTML = text;
}

function editor_clear_status_bar() {
    document.querySelector('#editor-status-bar > .info').innerHTML = '';
}

function editor_set_operation(e, ope) {
    operation.value = ope;
    ctrl.value = e.ctrlKey    
}

function editor_gotoline(nline, select_line = false) {
    editor.gotoLine(nline);
    if (select_line) editor.selection.selectLine();
    editor.focus();
}