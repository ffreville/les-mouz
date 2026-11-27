class_name Touch
extends RefCounted
## Outils pour le jeu au doigt (voir Device et CameraController).


## Vrai pour un clic de souris imité à partir d'un doigt posé sur l'écran.
static func is_touch(event: InputEvent) -> bool:
	return event.device == InputEvent.DEVICE_ID_EMULATION
