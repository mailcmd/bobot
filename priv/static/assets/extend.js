function confirm_action(message, action) {
    box_confirm_action.querySelector('#action').value = action
    box_confirm_action.querySelector('#message').innerHTML = message
    box_confirm_action.showModal();
}

function editor_open(title, text, readonly = false) {
    editor_set_text(text);
    editor_set_title(title);
    bobot_editor.showModal();
    editor.selection.clearSelection();
    editor_set_readonly(readonly);
    editor_gotoline(0);
    setTimeout(() => {
        editor.focus();
        document.querySelector('.ace_text-input')?.focus();
    }, 100);
}

function editor_set_readonly(readonly) {
    editor.setReadOnly(readonly);
    if (readonly) {
        bobot_editor.querySelectorAll('.editing').forEach( b => b.style.display = 'none');
        bobot_editor.querySelectorAll('.reading').forEach( b => b.style.display = '');
        bobot_editor.classList.add('readonly');
        editor_set_status_bar('Readonly!');
        editor.renderer.$cursorLayer.element.style.display = 'none';
    } else {
        bobot_editor.querySelectorAll('.reading').forEach( b => b.style.display = 'none');
        bobot_editor.querySelectorAll('.editing').forEach( b => b.style.display = '');
        bobot_editor.classList.remove('readonly');
        editor_set_status_bar('');
        editor.renderer.$cursorLayer.element.style.display = 'block';
        editor.focus();
    }    
}

function editor_set_text(text) {
    editor.setValue(text);
}

function editor_set_title(title) {
    bobot_editor.setAttribute('data-title', title)
}

function editor_set_status_bar(text, goto_line = null, select_line = true) {
    document.querySelector('#editor-status-bar > .info').innerHTML = text;
    if (goto_line) setTimeout(() => editor_gotoline(goto_line, select_line), 500);
}

function editor_clear_status_bar() {
    document.querySelector('#editor-status-bar > .info').innerHTML = '';
}

function editor_set_operation(e, ope) {
    operation.value = ope;
    ctrl.value = e.ctrlKey    
}

function editor_gotoline(nline, select_line = false) {
    editor.gotoLine(...[nline].flat());
    if (select_line) editor.selection.selectLine();
    editor.focus();
}

function open_connect(el) {
    el.disabled = true;
    const block = el.closest('.defblock');
    block.style.filter = 'grayscale(1)';
    block.style.opacity = '0.5';
    otherBlocks = siblings(block);
    otherBlocks.forEach( b => {
        const div = b.querySelector('div')
        div.classList.add('block-selectable');
        const button = div.querySelector('.connect');
        button.setAttribute('onclick', 'close_connect(this)');
        const icon = button.querySelector('span');
        icon.classList.add('hero-plus-circle-solid');
        icon.classList.remove('hero-arrow-down-circle');
    });
    window.connect_from = el.value;
}

function close_connect(el) {
    const block = el.closest('.defblock');
    block.style.filter = null;
    block.style.opacity = null;
    otherBlocks = [...siblings(block), block];
    otherBlocks.forEach( b => {
        b.style.filter = null;
        b.style.opacity = null;
        const div = b.querySelector('div')
        div.classList.remove('block-selectable');
        const button = div.querySelector('.connect');
        button.disabled = false;
        button.setAttribute('onclick', 'open_connect(this)');
        const icon = button.querySelector('span');
        icon.classList.remove('hero-plus-circle-solid');
        icon.classList.add('hero-arrow-down-circle');
    });
    block_connect(connect_from, el.value);    
}

function block_connect(b1, b2, color = '#a855f7') {
    const from = document.querySelector(`[data-block-name="${b1}"]`);
    const to = document.querySelector(`[data-block-name="${b2}"]`);
    let line = new LeaderLine(
        from,
        // LeaderLine.pointAnchor(to),
        to,
        {
            startPlug: 'square',
            endPlug: 'arrow1',
            color: color, 
            size: 2,
            path: 'grid'
        }
    );

    from.lines = from.lines ?? [];
    from.lines.push(line);
    to.lines = to.lines ?? [];
    to.lines.push(line);

    // new LeaderLine(
    //     document.querySelector(`[data-block-name="${b1}"]`),
    //     LeaderLine.pointAnchor(document.querySelector(`[data-block-name-anchor="${b1}"]`)),
    //     {
    //         startPlug: 'square',
    //         endPlug: 'disc',
    //         color: color, 
    //         size: 2
    //     }
    // );
    // new LeaderLine(
    //     LeaderLine.pointAnchor(document.querySelector(`[data-block-name-anchor="${b1}"]`)),
    //     LeaderLine.pointAnchor(document.querySelector(`[data-block-name-anchor="${b2}"]`)),
    //     {
    //         startPlug: 'disc',
    //         endPlug: 'disc',
    //         color: color, 
    //         size: 2
    //     }
    // );
    // new LeaderLine(
    //     LeaderLine.pointAnchor(document.querySelector(`[data-block-name-anchor="${b2}"]`)),
    //     document.querySelector(`[data-block-name="${b2}"]`),
    //     {
    //         startPlug: 'disc',
    //         endPlug: 'arrow1',
    //         color: color, 
    //         size: 2
    //     }
    // );

}

// utils
const siblings = n => [...n.parentElement.children].filter(c=>c.nodeType == 1 && c!=n)