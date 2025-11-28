extends CharacterBody2D

@export var wander_speed: float = 60
@export var chase_speed: float = 75
@export var detection_radius: float = 50
@export var wander_radius:float = 55

@export var agent: NavigationAgent2D

var state_machine
var player : Node = null
var direction : Vector2 = Vector2.ZERO
