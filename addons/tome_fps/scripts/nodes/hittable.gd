class_name Hittable
extends Node
## Can take hits from Projectiles, Explosions, and Melees.

signal hit(event)

@export var disabled := false
