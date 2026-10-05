extends Node
var callback: JavaScriptObject
func _ready() -> void:
	callback = JavaScriptBridge.create_callback(write_pair)
	JavaScriptBridge.get_interface('window').writeGodotPair = callback
	var paths := {'primaryPath':ProjectSettings.globalize_path('user://youjia_save.json'),'backupPath':ProjectSettings.globalize_path('user://youjia_save.bak'),'persistent':OS.is_userfs_persistent()}
	JavaScriptBridge.eval('window.godotSourcePaths='+JSON.stringify(paths))
func write_pair(args: Array) -> void:
	var primary := FileAccess.open('user://youjia_save.json',FileAccess.WRITE)
	primary.store_buffer(str(args[0]).to_utf8_buffer())
	primary.close()
	var backup := FileAccess.open('user://youjia_save.bak',FileAccess.WRITE)
	backup.store_buffer(str(args[1]).to_utf8_buffer())
	backup.close()
	JavaScriptBridge.eval('window.godotWriteCount=(window.godotWriteCount||0)+1')
