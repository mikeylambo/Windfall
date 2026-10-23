extends Node

signal locale_changed(locale: String)
signal translations_loaded(locale: String)

var current_locale: String = "en"
var translations: Dictionary = {}


func set_locale(locale: String) -> void:
	if locale.is_empty():
		return
	if current_locale == locale:
		return
	current_locale = locale
	locale_changed.emit(current_locale)


func get_locale() -> String:
	return current_locale


func load_translations(locale: String, data: Dictionary) -> void:
	if locale.is_empty():
		return
	translations[locale] = data.duplicate(true)
	translations_loaded.emit(locale)


func tr_key(key: String, fallback: String = "") -> String:
	if key.is_empty():
		return fallback
	if translations.has(current_locale):
		var locale_translations: Dictionary = translations[current_locale]
		if locale_translations.has(key):
			return str(locale_translations[key])
	if not fallback.is_empty():
		return fallback
	return key


func has_key(key: String) -> bool:
	if not translations.has(current_locale):
		return false
	var locale_translations: Dictionary = translations[current_locale]
	return locale_translations.has(key)
