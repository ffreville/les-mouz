class_name CharacterProfile
extends Resource
## Fiche d'un personnage : identité, apparence et réglages propres.

## Identifiant unique (sert à la sauvegarde).
@export var id: StringName = &"mouz"
@export var display_name: String = "Mouz"
## Ancienne image vue de dessus (plus utilisée depuis les humains en calques).
@export var sprite: Texture2D
## Apparence : sexe, âge, peau, cheveux, tenue.
@export var appearance: MouzAppearance
@export var color: Color = Color(0.95, 0.55, 0.25)
## Vitesse de marche en pixels par seconde réelle, à la vitesse x1.
@export var walk_speed: float = 96.0
## Le personnage agit-il seul quand sa file est vide ?
@export var autonomy_enabled: bool = true
## Besoins de ce personnage (on peut donner des besoins différents à chacun).
@export var needs: Array[NeedDefinition] = []
