class_name TimeFormat
extends RefCounted
## Dates lisibles pour l'écran des sauvegardes : « à l'instant », « il y a 5 min », « hier à 18:02 »…


static func since(unix_time: float) -> String:
	var elapsed := Time.get_unix_time_from_system() - unix_time
	if elapsed < 60:
		return "à l'instant"
	if elapsed < 3600:
		return "il y a %d min" % int(elapsed / 60)
	if elapsed < 6 * 3600:
		return "il y a %d h" % int(elapsed / 3600)
	var local := _local(unix_time)
	var today := _local(Time.get_unix_time_from_system())
	var clock := "%02d:%02d" % [local["hour"], local["minute"]]
	if local["day"] == today["day"] and local["month"] == today["month"] and local["year"] == today["year"]:
		return "aujourd'hui à " + clock
	return "le %02d/%02d/%d à %s" % [local["day"], local["month"], local["year"], clock]


## Date et heure locales (le système renvoie l'heure universelle).
static func _local(unix_time: float) -> Dictionary:
	var bias_minutes: int = Time.get_time_zone_from_system().get("bias", 0)
	return Time.get_datetime_dict_from_unix_time(int(unix_time) + bias_minutes * 60)
