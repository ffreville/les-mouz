class_name MouzSkills
extends Node
## Les compétences d'un Mouz : minutes de pratique cumulées par compétence.
## L'action en cours (ActionQueue) appelle `practice()` à chaque instant de jeu ; le gain dépend
## de l'humeur et de l'âge. Un niveau gagné est annoncé par un message.

## Une compétence a progressé (pour l'affichage).
signal changed(skill: StringName)

var _minutes: Dictionary[StringName, float] = {}
var _character: Character


func setup(character: Character) -> void:
	_character = character


func level(skill: StringName) -> int:
	return Skills.level_for(_minutes.get(skill, 0.0))


func progress(skill: StringName) -> float:
	return Skills.progress_for(_minutes.get(skill, 0.0))


## `game_minutes` passées à pratiquer `skill`.
func practice(skill: StringName, game_minutes: float) -> void:
	if skill == &"" or game_minutes <= 0.0:
		return
	var before := level(skill)
	_minutes[skill] = _minutes.get(skill, 0.0) + game_minutes * learning_factor()
	var after := level(skill)
	changed.emit(skill)
	if after > before:
		EventBus.skill_level_up.emit(_character, skill, after)
		EventBus.notice.emit("%s passe niveau %d en %s !" % [_character.get_display_name(), after,
				Skills.display_name(skill)])


## Vitesse d'apprentissage selon l'humeur et l'âge.
func learning_factor() -> float:
	var age: StringName = _character.profile.appearance.age if _character.profile.appearance != null else &"adulte"
	return float(Skills.MOOD_FACTORS[mood_key()]) * float(Skills.AGE_FACTORS.get(age, 1.0))


## &"bonne", &"normale" ou &"mauvaise" humeur, pour la vitesse d'apprentissage.
func mood_key() -> StringName:
	var mood := _character.needs.get_mood()
	if mood >= Skills.GOOD_MOOD:
		return &"bonne"
	return &"mauvaise" if mood <= Skills.BAD_MOOD else &"normale"


func to_dict() -> Dictionary:
	var data := {}
	for skill in _minutes:
		data[String(skill)] = snappedf(_minutes[skill], 0.01)
	return data


func restore(data: Dictionary) -> void:
	_minutes.clear()
	for skill in data:
		_minutes[StringName(skill)] = float(data[skill])
	changed.emit(&"")
