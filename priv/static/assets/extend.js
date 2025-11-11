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