function toggle_box_min_max(box) {
    if (box.className.match('minimized')) {
        box.className = box.className.replace('minimized', 'maximized'); 
        box.classList.remove('cursor-pointer');
        box.onclick = null;
    } else if (box.className.match('maximized')) {
        box.className = box.className.replace('maximized', 'minimized');
        box.classList.add('cursor-pointer');
        setTimeout(() => { box.onclick = () => toggle_box_min_max(box); }, 1000);
    } else {
        box.classList.add('minimized');
        box.classList.add('cursor-pointer');
        setTimeout(() => { box.onclick = () => toggle_box_min_max(box); }, 1000);
    }
}

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
