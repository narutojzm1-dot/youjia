# 独立资源场景的真实引擎渲染

Godot 4.7.2.stable.official.ed1daf0bf，Windows OpenGL 3.3 compatibility，AMD Radeon 8060S。官方ZIP SHA512校验通过后运行。先headless导入，再非headless渲染并由viewport保存PNG。两张1280×720截图为引擎输出，未加工像素。

这是隔离Sprite2D场景，不是正式游戏；复制了相同背景、比例和脚点公式。engine-check.json仅证明实际加载三纹理及变换锚点，不能证明角色身体像素完全不变、FeltActor切换、成功事件、碰撞、步态、手机、照片或PCK。

复现时将本目录的 project.godot、main.tscn 和 main.gd复制到独立目录（README和截图非运行必需），并准备原样输入：cast_v2/duck.png→idle.png，父目录duck_attend_master.png→attend_v1.png，父目录duck_attend_v2.png→attend_v2.png，assets/holiday/environment/yard_sunny.png→yard.png。不要在正式游戏项目中嵌套导入测试项目。

```text
godot --headless --path /isolated/path --editor --import --quit
godot --path /isolated/path --rendering-method gl_compatibility -- --capture
```

第二条需可用图形设备；会依次渲染三图、保存capture_*.png并退出。无背景音乐或交互副作用。照片布局点(688,562)、比例0.0252565408085431、idle脚点(670,1205)共用；相同锚点不等于完整动作验收。
