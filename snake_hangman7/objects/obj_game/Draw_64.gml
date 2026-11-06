global.ui_clicked = false;
switch (global.state)
{
    case "title":
        ui_title();
        break;

    case "brief":
        ui_brief();
        break;

    case "play":
    case "end":
        ui_drag_box();
        ui_topbar();
        ui_sidebar();
        if (global.state == "end") ui_end();
        else if (global.paused) ui_pause();
        break;
}
ui_cursor();
if (global.autotest && global.state == "brief" && global.test_t == 2) screen_save(global.test_dir + "autotest_brief.png");
if (global.autotest && global.state != "title")
{
    if (global.frame == global.test_shot) autotest_capture("autotest_" + string(global.frame) + ".png");
    if (global.test_shot == -2) { autotest_capture("autotest_end.png"); global.test_shot = -3; }
}
